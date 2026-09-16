import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import '../utils/input_validator.dart';
import 'analytics_service.dart';

/// Outcome of an eligibility check for the roaster-website contribution nudge.
class RoasterContributionEligibility {
  const RoasterContributionEligibility({
    required this.eligible,
    this.clusterId,
    this.normalizedName,
  });

  /// Whether the app should prompt the user to contribute this roaster's site.
  final bool eligible;

  /// The pending candidate cluster id (present when [eligible]).
  final String? clusterId;

  /// Server-normalized roaster name for the cluster (present when [eligible]).
  final String? normalizedName;

  static const RoasterContributionEligibility ineligible =
      RoasterContributionEligibility(eligible: false);
}

/// The server-side outcome of submitting a contribution.
enum RoasterContributionResult {
  ok,
  alreadyKnown,
  noCluster,
  notPending,
  error,
}

typedef RoasterContributionTargetLoader =
    Future<Object?> Function(String roaster);

/// Injectable RPC loader for the pending-contribution acknowledgements —
/// mirrors [RoasterContributionTargetLoader] so tests run without a network.
typedef RoasterContributionAcknowledgementLoader = Future<Object?> Function();

/// Injectable fetcher for the widgets that surface a pending acknowledgement,
/// so they can be pumped in tests without a Supabase client.
typedef RoasterContributionAcknowledgementFetcher =
    Future<RoasterContributionAcknowledgement?> Function();

/// Bridges the app to the plan-011 roaster-website crowdsourcing backend:
/// checks whether a roaster is a pending candidate worth prompting about
/// ([checkEligibility]) and submits the user's website ([submitContribution]).
///
/// Coordination state — shared by the in-app card and the notification channel:
/// a cluster is *resolved* only when the user submits a contribution or
/// explicitly dismisses ("Not now"). Both channels keep prompting until the
/// cluster is resolved; resolving suppresses both. Merely *showing* the card
/// does not resolve it — a separate "shown" set exists only to fire the
/// impression analytics event once.
class RoasterContributionService {
  RoasterContributionService._internal({
    RoasterContributionTargetLoader? targetLoader,
    RoasterContributionAcknowledgementLoader? acknowledgementLoader,
    bool Function()? hasCurrentUser,
    DateTime Function()? now,
    Duration targetCacheTtl = const Duration(minutes: 10),
    Duration acknowledgementCacheTtl = const Duration(minutes: 10),
  }) : _targetLoader = targetLoader,
       _acknowledgementLoader = acknowledgementLoader,
       _hasCurrentUser = hasCurrentUser,
       _now = now ?? DateTime.now,
       _targetCacheTtl = targetCacheTtl,
       _acknowledgementCacheTtl = acknowledgementCacheTtl;

  static final RoasterContributionService instance =
      RoasterContributionService._internal();
  factory RoasterContributionService() => instance;

  @visibleForTesting
  factory RoasterContributionService.forTesting({
    required RoasterContributionTargetLoader targetLoader,
    RoasterContributionAcknowledgementLoader? acknowledgementLoader,
    bool Function()? hasCurrentUser,
    DateTime Function()? now,
    Duration targetCacheTtl = const Duration(minutes: 10),
    Duration acknowledgementCacheTtl = const Duration(minutes: 10),
  }) => RoasterContributionService._internal(
    targetLoader: targetLoader,
    acknowledgementLoader: acknowledgementLoader,
    hasCurrentUser: hasCurrentUser,
    now: now,
    targetCacheTtl: targetCacheTtl,
    acknowledgementCacheTtl: acknowledgementCacheTtl,
  );

  /// Clusters the user has finished with — submitted a contribution or tapped
  /// "Not now". Suppresses both the card and the notification. Bounded by the
  /// number of new roasters a single user encounters, so a plain list is fine.
  static const String _keyResolvedClusters = 'roaster_contrib_resolved_v1';

  /// Clusters whose card has been shown at least once — used ONLY to
  /// de-duplicate the impression analytics event, never to suppress prompting.
  static const String _keyShownClusters = 'roaster_contrib_shown_v1';

  static const String _rpcTarget = 'roaster_contribution_target';
  static const String _rpcAcknowledgements =
      'get_my_contribution_acknowledgements';
  static const String _rpcMarkAcknowledged = 'mark_contribution_acknowledged';
  static const String _edgeFnSubmit = 'submit-roaster-contribution';
  static final RegExp _whitespace = RegExp(r'\s+');

  final RoasterContributionTargetLoader? _targetLoader;
  final RoasterContributionAcknowledgementLoader? _acknowledgementLoader;
  final bool Function()? _hasCurrentUser;
  final DateTime Function() _now;
  final Duration _targetCacheTtl;
  final Duration _acknowledgementCacheTtl;
  final Map<String, _CachedRoasterContributionTarget> _targetCache = {};
  final Map<String, Future<_RoasterContributionTarget>> _targetRequests = {};

  /// Cached pending acknowledgement (plan 062). Null inside the entry means
  /// "fetched, nothing pending"; a null entry itself means "not fetched yet".
  _CachedAcknowledgement? _acknowledgementCache;
  Future<RoasterContributionAcknowledgement?>? _acknowledgementRequest;

  SupabaseClient get _client => Supabase.instance.client;

  /// Whether the app should prompt the user to contribute a website for
  /// [roasterText]: eligible when the roaster is not already a known roaster, a
  /// *pending* candidate cluster exists for it, and the cluster is not yet
  /// resolved. Never throws — returns [ineligible] on any error (offline, RPC
  /// failure, etc.).
  Future<RoasterContributionEligibility> checkEligibility(
    String roasterText,
  ) async {
    final trimmed = roasterText.trim();
    if (trimmed.isEmpty) return RoasterContributionEligibility.ineligible;
    // Requires a session (anonymous is fine) so the contribution is attributable.
    final hasCurrentUser =
        _hasCurrentUser?.call() ?? _client.auth.currentUser != null;
    if (!hasCurrentUser) {
      return RoasterContributionEligibility.ineligible;
    }
    try {
      final target = await _getTarget(trimmed);
      // Already a known roaster, no pending cluster, or not pending → no prompt.
      if (target.matchedRoasterId != null ||
          target.clusterId == null ||
          target.clusterStatus != 'pending') {
        return RoasterContributionEligibility.ineligible;
      }
      if (await isResolved(target.clusterId!)) {
        return RoasterContributionEligibility.ineligible;
      }
      return RoasterContributionEligibility(
        eligible: true,
        clusterId: target.clusterId,
        normalizedName: target.normalizedName,
      );
    } catch (error) {
      AppLogger.error(
        'roaster_contribution_target failed',
        errorObject: AppLogger.sanitize(error),
      );
      return RoasterContributionEligibility.ineligible;
    }
  }

  Future<_RoasterContributionTarget> _getTarget(String roaster) {
    final key = roaster.replaceAll(_whitespace, ' ').toLowerCase();
    final cached = _targetCache[key];
    final now = _now();
    if (cached != null && now.isBefore(cached.expiresAt)) {
      return Future.value(cached.target);
    }
    if (cached != null) _targetCache.remove(key);

    final existingRequest = _targetRequests[key];
    if (existingRequest != null) return existingRequest;

    late final Future<_RoasterContributionTarget> request;
    request = _fetchTarget(roaster)
        .then((target) {
          _targetCache[key] = _CachedRoasterContributionTarget(
            target: target,
            expiresAt: _now().add(_targetCacheTtl),
          );
          return target;
        })
        .whenComplete(() {
          if (identical(_targetRequests[key], request)) {
            _targetRequests.remove(key);
          }
        });
    _targetRequests[key] = request;
    return request;
  }

  Future<_RoasterContributionTarget> _fetchTarget(String roaster) async {
    final response = _targetLoader != null
        ? await _targetLoader(roaster)
        : await _client.rpc(_rpcTarget, params: {'p_roaster': roaster});
    if (response is! Map) {
      throw const FormatException('Invalid roaster contribution target');
    }
    return _RoasterContributionTarget.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Records that the card was surfaced for [clusterId]. Fires the impression
  /// analytics once per cluster; does NOT resolve, so the prompt keeps returning
  /// on later visits until the user acts.
  Future<void> markPromptShown(String clusterId) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_keyShownClusters) ?? <String>[];
    if (shown.contains(clusterId)) return;
    shown.add(clusterId);
    await prefs.setStringList(_keyShownClusters, shown);
    AnalyticsService.maybeInstance?.track(
      'roaster_contribution_prompt_shown',
      properties: {'cluster_id': clusterId},
    );
  }

  /// Records that the user dismissed the prompt for [clusterId] ("Not now").
  /// Resolves the cluster and suppresses both channels.
  Future<void> dismiss(String clusterId) async {
    await _markResolved(clusterId);
    AnalyticsService.maybeInstance?.track(
      'roaster_contribution_dismissed',
      properties: {'cluster_id': clusterId},
    );
  }

  /// Submits a user-contributed website (and optional details) for [roaster].
  /// The website is validated client-side first; the edge function re-validates
  /// and is authoritative. Resolves the cluster and emits analytics on any
  /// terminal outcome. Never throws.
  Future<RoasterContributionResult> submitContribution({
    required String roaster,
    required String websiteUrl,
    String? instagramUrl,
    String? city,
    String? country,
    String? clusterId,
  }) async {
    final normalizedUrl = InputValidator.normalizeWebsiteUrl(websiteUrl);
    if (normalizedUrl == null) return RoasterContributionResult.error;
    try {
      final response = await _client.functions.invoke(
        _edgeFnSubmit,
        body: {
          'roaster': roaster.trim(),
          'website_url': normalizedUrl,
          if (instagramUrl != null && instagramUrl.trim().isNotEmpty)
            'instagram_url': instagramUrl.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (country != null && country.trim().isNotEmpty)
            'country': country.trim(),
        },
      );
      final data = response.data;
      final status =
          (data is Map ? data['status'] as String? : null) ?? 'error';
      final effectiveClusterId =
          clusterId ?? (data is Map ? data['cluster_id'] as String? : null);
      // Any terminal server outcome resolves the cluster (stops both channels).
      if (effectiveClusterId != null) {
        await _markResolved(effectiveClusterId);
      }
      AnalyticsService.maybeInstance?.track(
        'roaster_contribution_submitted',
        properties: {'status': status, 'cluster_id': ?effectiveClusterId},
      );
      return _resultFromStatus(status);
    } catch (error) {
      AppLogger.error(
        'submit-roaster-contribution failed',
        errorObject: AppLogger.sanitize(error),
      );
      AnalyticsService.maybeInstance?.track(
        'roaster_contribution_submitted',
        properties: {'status': 'error'},
      );
      return RoasterContributionResult.error;
    }
  }

  /// Whether [clusterId] has been resolved (submitted or dismissed). Read by the
  /// notification scheduler to skip/cancel nudges for handled roasters.
  Future<bool> isResolved(String clusterId) async {
    final prefs = await SharedPreferences.getInstance();
    final resolved = prefs.getStringList(_keyResolvedClusters) ?? const [];
    return resolved.contains(clusterId);
  }

  /// Returns the first pending acknowledgement for the user's contributions
  /// (plan 062) — a roaster they submitted that is now live — or null when
  /// signed out, when nothing is pending, or on any error. Cached for
  /// [_acknowledgementCacheTtl] with in-flight request de-dup. Never throws.
  Future<RoasterContributionAcknowledgement?> fetchPendingAcknowledgement() {
    // Requires a session (anonymous is fine), same as contributing itself.
    final hasCurrentUser =
        _hasCurrentUser?.call() ?? _client.auth.currentUser != null;
    if (!hasCurrentUser) return Future.value(null);

    final cached = _acknowledgementCache;
    final now = _now();
    if (cached != null && now.isBefore(cached.expiresAt)) {
      return Future.value(cached.acknowledgement);
    }
    _acknowledgementCache = null;

    final existingRequest = _acknowledgementRequest;
    if (existingRequest != null) return existingRequest;

    late final Future<RoasterContributionAcknowledgement?> request;
    request = _fetchAcknowledgement()
        .then((acknowledgement) {
          _acknowledgementCache = _CachedAcknowledgement(
            acknowledgement: acknowledgement,
            expiresAt: _now().add(_acknowledgementCacheTtl),
          );
          return acknowledgement;
        })
        .whenComplete(() {
          if (identical(_acknowledgementRequest, request)) {
            _acknowledgementRequest = null;
          }
        });
    _acknowledgementRequest = request;
    return request;
  }

  Future<RoasterContributionAcknowledgement?> _fetchAcknowledgement() async {
    try {
      final response = _acknowledgementLoader != null
          ? await _acknowledgementLoader()
          : await _client.rpc(_rpcAcknowledgements, params: {'p_limit': 1});
      if (response is! List) {
        throw const FormatException('Invalid acknowledgement response');
      }
      if (response.isEmpty) return null;
      final row = response.first;
      if (row is! Map) {
        throw const FormatException('Invalid acknowledgement row');
      }
      return RoasterContributionAcknowledgement.fromMap(
        Map<String, dynamic>.from(row),
      );
    } catch (error) {
      AppLogger.error(
        'get_my_contribution_acknowledgements failed',
        errorObject: AppLogger.sanitize(error),
      );
      return null;
    }
  }

  /// Marks the acknowledgement for [contributionId] as delivered in-app so the
  /// card never returns (the RPC is idempotent). Clears the cached fetch so the
  /// next read is fresh. Never throws.
  Future<void> markAcknowledged(int contributionId) async {
    _acknowledgementCache = null;
    try {
      await _client.rpc(
        _rpcMarkAcknowledged,
        params: {'p_contribution_id': contributionId, 'p_channel': 'in_app'},
      );
    } catch (error) {
      AppLogger.error(
        'mark_contribution_acknowledged failed',
        errorObject: AppLogger.sanitize(error),
      );
    }
    AnalyticsService.maybeInstance?.track(
      'roaster_contribution_ack_shown',
      properties: {'contribution_id': contributionId},
    );
  }

  /// Fires when the user taps an acknowledgement card's primary action.
  void trackAcknowledgementTapped(int contributionId) {
    AnalyticsService.maybeInstance?.track(
      'roaster_contribution_ack_tapped',
      properties: {'contribution_id': contributionId},
    );
  }

  RoasterContributionResult _resultFromStatus(String status) {
    switch (status) {
      case 'ok':
        return RoasterContributionResult.ok;
      case 'already_known':
        return RoasterContributionResult.alreadyKnown;
      case 'no_cluster':
        return RoasterContributionResult.noCluster;
      case 'not_pending':
        return RoasterContributionResult.notPending;
      default:
        return RoasterContributionResult.error;
    }
  }

  Future<void> _markResolved(String clusterId) async {
    final prefs = await SharedPreferences.getInstance();
    final resolved = prefs.getStringList(_keyResolvedClusters) ?? <String>[];
    if (resolved.contains(clusterId)) return;
    resolved.add(clusterId);
    await prefs.setStringList(_keyResolvedClusters, resolved);
  }
}

class _RoasterContributionTarget {
  const _RoasterContributionTarget({
    required this.matchedRoasterId,
    required this.clusterId,
    required this.clusterStatus,
    required this.normalizedName,
  });

  factory _RoasterContributionTarget.fromMap(Map<String, dynamic> data) =>
      _RoasterContributionTarget(
        matchedRoasterId: data['matched_roaster_id'],
        clusterId: data['cluster_id'] as String?,
        clusterStatus: data['cluster_status'] as String?,
        normalizedName: data['normalized_name'] as String?,
      );

  final Object? matchedRoasterId;
  final String? clusterId;
  final String? clusterStatus;
  final String? normalizedName;
}

class _CachedRoasterContributionTarget {
  const _CachedRoasterContributionTarget({
    required this.target,
    required this.expiresAt,
  });

  final _RoasterContributionTarget target;
  final DateTime expiresAt;
}

/// One resolved contribution by the current user: the roaster they submitted is
/// now live in the database, and the hub card thanks them for it (plan 062).
class RoasterContributionAcknowledgement {
  const RoasterContributionAcknowledgement({
    required this.contributionId,
    required this.roasterName,
    required this.slug,
    this.logoUrl,
    this.logoMirrorUrl,
    this.dominantColorHex,
    this.resolvedAt,
  });

  /// Tolerates nulls and a malformed/missing `resolved_at` (parse failure →
  /// null, never throw) so one bad row can never crash the hub card.
  factory RoasterContributionAcknowledgement.fromMap(
    Map<String, dynamic> data,
  ) {
    final resolvedRaw = data['resolved_at'];
    return RoasterContributionAcknowledgement(
      contributionId: _intFrom(data['contribution_id']),
      roasterName: data['roaster_name'] as String? ?? '',
      slug: data['slug'] as String? ?? '',
      logoUrl: data['roaster_logo_url'] as String?,
      logoMirrorUrl: data['roaster_logo_mirror_url'] as String?,
      dominantColorHex: data['dominant_color_hex'] as String?,
      resolvedAt: resolvedRaw is String ? DateTime.tryParse(resolvedRaw) : null,
    );
  }

  static int _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  final int contributionId;
  final String roasterName;
  final String slug;
  final String? logoUrl;
  final String? logoMirrorUrl;
  final String? dominantColorHex;
  final DateTime? resolvedAt;
}

class _CachedAcknowledgement {
  const _CachedAcknowledgement({
    required this.acknowledgement,
    required this.expiresAt,
  });

  /// Null means the fetch succeeded but nothing is pending — cached so the
  /// (overwhelmingly common) empty case does not re-hit the RPC within the TTL.
  final RoasterContributionAcknowledgement? acknowledgement;
  final DateTime expiresAt;
}
