import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import 'notification_service.dart';

enum OsPermissionStatus { notDetermined, granted, denied }

enum AskEligibilityReason {
  ok,
  web,
  masterOn,
  osGranted,
  osDenied,
  terminal,
  capReached,
  tooSoon,
  tooFewBrews,
  finishScreenAlreadyAsked,
}

class AskEligibility {
  final bool allowed;
  final AskEligibilityReason reason;

  const AskEligibility({required this.allowed, required this.reason});
}

enum AskOutcome { granted, denied, skipped }

/// Owns soft-ask eligibility and bookkeeping, independently of any ask UI.
/// All platform operations are deferred and injectable for unit tests.
class NotificationAskService {
  NotificationAskService({
    required SharedPreferences prefs,
    DateTime Function() now = DateTime.now,
    bool isWeb = kIsWeb,
    Future<bool> Function() isMasterEnabled = _defaultIsMasterEnabled,
    Future<OsPermissionStatus> Function() osStatus = _defaultOsStatus,
    Future<bool> Function() requestOsPermission = _defaultRequestOsPermission,
    Future<void> Function() enableMaster = _defaultEnableMaster,
  }) : _prefs = prefs,
       _now = now,
       _isWeb = isWeb,
       _isMasterEnabled = isMasterEnabled,
       _osStatus = osStatus,
       _requestOsPermission = requestOsPermission,
       _enableMaster = enableMaster;

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final bool _isWeb;
  final Future<bool> Function() _isMasterEnabled;
  final Future<OsPermissionStatus> Function() _osStatus;
  final Future<bool> Function() _requestOsPermission;
  final Future<void> Function() _enableMaster;

  static const _asksKey = 'notif_perm_asks';
  static const _terminalKey = 'notif_perm_terminal';
  static const _legacyKey = 'notif_perm_ab_shown';
  static const _maxAsks = 3;
  static const _minSpacing = Duration(days: 7);

  static Future<bool> _defaultIsMasterEnabled() =>
      NotificationService.instance.settings.isMasterEnabled();

  static Future<OsPermissionStatus> _defaultOsStatus() async {
    final state = await NotificationService.instance.permissions
        .getCurrentPermissionState();
    if (state.granted ||
        state.firebaseStatus == AuthorizationStatus.authorized ||
        state.firebaseStatus == AuthorizationStatus.provisional) {
      return OsPermissionStatus.granted;
    }
    if (state.firebaseStatus == AuthorizationStatus.denied &&
        defaultTargetPlatform != TargetPlatform.android) {
      return OsPermissionStatus.denied;
    }
    // Android reports denied for both a denial and an unrequested permission.
    // A missing Firebase status with a false local fallback is also ambiguous.
    // Treat both as notDetermined; our terminal marker remembers known answers.
    return OsPermissionStatus.notDetermined;
  }

  static Future<bool> _defaultRequestOsPermission() =>
      NotificationService.instance.requestPermissions();

  static Future<void> _defaultEnableMaster() =>
      NotificationService.instance.updateMasterToggle(
        enabled: true,
        userId: Supabase.instance.client.auth.currentUser?.id,
      );

  Future<AskEligibility> canAsk(
    String surface, {
    required int finishedBrewCount,
  }) async {
    final entries = await _readAndMigrate();
    AskEligibility denied(AskEligibilityReason reason) =>
        AskEligibility(allowed: false, reason: reason);

    if (_isWeb) return denied(AskEligibilityReason.web);
    if (_prefs.containsKey(_terminalKey)) {
      return denied(AskEligibilityReason.terminal);
    }
    if (await _isMasterEnabled()) return denied(AskEligibilityReason.masterOn);
    final status = await _osStatus();
    if (status == OsPermissionStatus.granted) {
      return denied(AskEligibilityReason.osGranted);
    }
    if (status == OsPermissionStatus.denied) {
      return denied(AskEligibilityReason.osDenied);
    }
    if (entries.length >= _maxAsks) {
      return denied(AskEligibilityReason.capReached);
    }
    if (entries.isNotEmpty) {
      final last = entries.last;
      if (_now().millisecondsSinceEpoch - last.askedAtMs <
          _minSpacing.inMilliseconds) {
        return denied(AskEligibilityReason.tooSoon);
      }
      if (finishedBrewCount - last.brewCountAtAsk < 3) {
        return denied(AskEligibilityReason.tooFewBrews);
      }
      if (surface == 'finish_screen') {
        return denied(AskEligibilityReason.finishScreenAlreadyAsked);
      }
    }
    return const AskEligibility(allowed: true, reason: AskEligibilityReason.ok);
  }

  /// Called when a soft ask is actually shown, never for a direct user request.
  /// At the lifetime cap this leaves the original ledger unchanged.
  Future<int> recordAsk(
    String surface, {
    required int finishedBrewCount,
  }) async {
    final entries = await _readAndMigrate();
    if (entries.length >= _maxAsks) return entries.length;
    entries.add(
      _AskEntry(surface, _now().millisecondsSinceEpoch, finishedBrewCount),
    );
    await _write(entries);
    return entries.length;
  }

  Future<void> recordOutcome(AskOutcome outcome) async {
    if (outcome == AskOutcome.skipped) return;
    await _prefs.setString(_terminalKey, outcome.name);
  }

  /// Also serves user-initiated requests, so this never records a soft ask.
  Future<bool> requestSystemPermissionAndEnable() async {
    try {
      final granted = await _requestOsPermission();
      if (granted) {
        await _enableMaster();
        await recordOutcome(AskOutcome.granted);
      } else {
        await recordOutcome(AskOutcome.denied);
      }
      return granted;
    } catch (e) {
      AppLogger.error(
        'Error requesting notification permissions',
        errorObject: e,
      );
      return false;
    }
  }

  /// Whether the OS has denied notification permission, as far as it can be
  /// known. Reuses the same status rule as [_defaultOsStatus]: iOS reports
  /// `denied` reliably, Android conflates a denial with "never asked" and is
  /// therefore treated as not denied here — our terminal marker
  /// (`notif_perm_terminal == 'denied'`, written by
  /// [requestSystemPermissionAndEnable]) remembers known answers. Used by
  /// the startup sync that hides the Coffee Journey "turn on brew updates"
  /// milestone on denied devices.
  Future<bool> isOsDenied() async {
    if (_prefs.getString(_terminalKey) == AskOutcome.denied.name) return true;
    return await _osStatus() == OsPermissionStatus.denied;
  }

  Future<int> askCount() async => (await _readAndMigrate()).length;

  Future<List<_AskEntry>> _readAndMigrate() async {
    final entries = _read();
    if (entries.isEmpty && (_prefs.getBool(_legacyKey) ?? false)) {
      entries.add(const _AskEntry('finish_screen', 0, 0));
      await _write(entries);
    }
    return entries;
  }

  List<_AskEntry> _read() {
    final raw = _prefs.getString(_asksKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final entries = <_AskEntry>[];
      for (final entry in decoded) {
        if (entry is! Map ||
            entry['surface'] is! String ||
            entry['askedAtMs'] is! int ||
            entry['brewCountAtAsk'] is! int) {
          return [];
        }
        entries.add(
          _AskEntry(
            entry['surface'] as String,
            entry['askedAtMs'] as int,
            entry['brewCountAtAsk'] as int,
          ),
        );
      }
      return entries.take(_maxAsks).toList();
    } catch (e) {
      AppLogger.error(
        'Failed to decode notification ask ledger',
        errorObject: e,
      );
      return [];
    }
  }

  Future<void> _write(List<_AskEntry> entries) async {
    await _prefs.setString(
      _asksKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

class _AskEntry {
  const _AskEntry(this.surface, this.askedAtMs, this.brewCountAtAsk);

  final String surface;
  final int askedAtMs;
  final int brewCountAtAsk;

  Map<String, Object> toJson() => {
    'surface': surface,
    'askedAtMs': askedAtMs,
    'brewCountAtAsk': brewCountAtAsk,
  };
}
