// lib/providers/bean_review_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/config/network_timeouts.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/persistent_ttl_cache.dart';

class RatingsSummary {
  final double? avgRating;
  final int reviewCount;

  const RatingsSummary({this.avgRating, required this.reviewCount});
}

/// Result of an OpenAI translation call for a single (review, target locale).
/// `sameLanguage = true` means the source already matches the target — no
/// translated text was produced and the UI should hide the Translate button.
class ReviewTranslation {
  final String reviewId;
  final String targetLocale;
  final String? translatedText;
  final String sourceLocale;
  final String? model;
  final bool sameLanguage;

  const ReviewTranslation({
    required this.reviewId,
    required this.targetLocale,
    required this.sourceLocale,
    this.translatedText,
    this.model,
    this.sameLanguage = false,
  });
}

class BeanReviewProvider extends ChangeNotifier {
  // Paginated reviews per roaster profile, keyed by roasterProfileId
  final Map<String, List<BeanReviewModel>> _reviewsCache = {};
  final Map<String, RatingsSummary> _ratingsCache = {};
  // User's own review per bean UUID (null value means "fetched, no review")
  final Map<String, BeanReviewModel?> _userBeanReviewCache = {};
  final PersistentTtlCache _userReviewPersistentCache =
      PersistentTtlCache('user_bean_review_');
  // In-memory translation cache, keyed by "$reviewId|$targetLocale".
  // The server holds the durable cache; this avoids re-invoking the edge
  // function within a single session.
  final Map<String, ReviewTranslation> _translationCache = {};

  String _translationKey(String reviewId, String targetLocale) =>
      '$reviewId|$targetLocale';

  ReviewTranslation? cachedTranslation({
    required String reviewId,
    required String targetLocale,
  }) =>
      _translationCache[_translationKey(reviewId, targetLocale)];

  List<BeanReviewModel> reviewsForRoaster(String roasterProfileId) =>
      _reviewsCache[roasterProfileId] ?? [];

  RatingsSummary? ratingSummary(String roasterProfileId) =>
      _ratingsCache[roasterProfileId];

  /// Returns true if a result (review or confirmed absence) is in the cache.
  /// Listeners can use this to detect when a bean's review was invalidated.
  bool isUserBeanReviewCached(String beansUuid) =>
      _userBeanReviewCache.containsKey(beansUuid);

  /// Fetches paginated reviews for a roaster. Appends results to cache.
  Future<List<BeanReviewModel>> fetchReviewsForRoaster(
    String roasterProfileId, {
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_roaster_reviews',
        params: {
          'p_roaster_profile_id': roasterProfileId,
          'p_offset': offset,
          'p_limit': limit,
        },
      ).timeout(NetworkTimeouts.smallSync);
      if (response == null) return [];
      final fetched = (response as List)
          .map((e) => BeanReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (offset == 0) {
        _reviewsCache[roasterProfileId] = fetched;
      } else {
        _reviewsCache[roasterProfileId] = [
          ...(_reviewsCache[roasterProfileId] ?? []),
          ...fetched,
        ];
      }
      notifyListeners();
      return fetched;
    } catch (error) {
      AppLogger.error(
        'Error fetching reviews for roaster',
        errorObject: AppLogger.sanitize(error),
      );
      return [];
    }
  }

  /// Fetches aggregate rating summary for a roaster.
  Future<RatingsSummary?> fetchAggregateRating(String roasterProfileId) async {
    if (_ratingsCache.containsKey(roasterProfileId)) {
      return _ratingsCache[roasterProfileId];
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'get_roaster_rating_summary',
        params: {'p_roaster_profile_id': roasterProfileId},
      ).timeout(NetworkTimeouts.handshake);
      if (response == null) return null;
      final data = Map<String, dynamic>.from(response as Map);
      final summary = RatingsSummary(
        avgRating: (data['avg_rating'] as num?)?.toDouble(),
        reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      );
      _ratingsCache[roasterProfileId] = summary;
      notifyListeners();
      return summary;
    } catch (error) {
      AppLogger.error(
        'Error fetching rating summary',
        errorObject: AppLogger.sanitize(error),
      );
      return null;
    }
  }

  /// Fetches the current user's review for a specific bean UUID.
  /// Returns null if the user hasn't reviewed this bean yet.
  Future<BeanReviewModel?> fetchUserReviewByBeanUuid(String beansUuid) async {
    if (_userBeanReviewCache.containsKey(beansUuid)) {
      return _userBeanReviewCache[beansUuid];
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final persistentKey = '${user.id}_$beansUuid';
    final persisted = await _userReviewPersistentCache.read(
      persistentKey,
      maxAge: const Duration(hours: 12),
    );
    if (persisted != null) {
      final rawReview = persisted['review'] as Map<String, dynamic>?;
      final review = rawReview != null
          ? BeanReviewModel.fromJson(rawReview)
          : null;
      _userBeanReviewCache[beansUuid] = review;
      return review;
    }

    try {
      final response = await Supabase.instance.client
          .from('bean_reviews')
          .select()
          .eq('user_id', user.id)
          .eq('coffee_beans_uuid', beansUuid)
          .maybeSingle()
          .timeout(NetworkTimeouts.handshake);
      final review = response != null
          ? BeanReviewModel.fromJson(Map<String, dynamic>.from(response as Map))
          : null;
      _userBeanReviewCache[beansUuid] = review;
      await _userReviewPersistentCache.write(persistentKey, {
        'review': response != null
            ? Map<String, dynamic>.from(response as Map)
            : null,
      });
      return review;
    } catch (error) {
      AppLogger.error(
        'Error fetching user review by bean uuid',
        errorObject: AppLogger.sanitize(error),
      );
      return null;
    }
  }

  /// Submits a new review. Invalidates cache for this roaster on success.
  /// [roasterProfileId] may be null when the roaster has no directory profile
  /// yet — the review will be auto-linked by a DB trigger when the profile is
  /// eventually created.
  Future<bool> submitReview({
    String? roasterProfileId,
    required String roasterName,
    required String beanName,
    String? coffeeBeansUuid,
    required double rating,
    String? reviewText,
    double? sweetness,
    double? acidity,
    double? fruitiness,
    double? body,
    String? brewingMethodId,
    bool? wouldBuyAgain,
    List<String>? flavorTags,
    double? bitterness,
    double? aftertaste,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client.from('bean_reviews').insert({
        'user_id': user.id,
        'roaster_profile_id': ?roasterProfileId,
        'roaster_name': roasterName,
        'bean_name': beanName,
        'coffee_beans_uuid': ?coffeeBeansUuid,
        'rating': rating,
        'review_text': ?reviewText,
        'sweetness': ?sweetness,
        'acidity': ?acidity,
        'fruitiness': ?fruitiness,
        'body': ?body,
        'brewing_method_id': ?brewingMethodId,
        'would_buy_again': ?wouldBuyAgain,
        if (flavorTags != null && flavorTags.isNotEmpty)
          'flavor_tags': flavorTags,
        'bitterness': ?bitterness,
        'aftertaste': ?aftertaste,
        'is_public': true,
      }).timeout(NetworkTimeouts.handshake);
      if (roasterProfileId != null) _invalidateCacheForRoaster(roasterProfileId);
      if (coffeeBeansUuid != null) {
        _userBeanReviewCache.remove(coffeeBeansUuid);
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          unawaited(
            _userReviewPersistentCache.remove('${uid}_$coffeeBeansUuid'),
          );
        }
      }

      final hasTasteProfile = sweetness != null ||
          acidity != null ||
          fruitiness != null ||
          body != null ||
          bitterness != null ||
          aftertaste != null;
      AnalyticsService.instance.track(
        'review_added',
        properties: {
          'bean_uuid': ?coffeeBeansUuid,
          'has_roaster_profile': roasterProfileId != null,
          'has_text': reviewText != null && reviewText.isNotEmpty,
          'rating': rating.round(),
          'has_taste_profile': hasTasteProfile,
          'has_flavor_tags': flavorTags != null && flavorTags.isNotEmpty,
          'flavor_tags_count': flavorTags?.length ?? 0,
          'has_brewing_method': brewingMethodId != null,
          'would_buy_again': wouldBuyAgain == null
              ? 'unset'
              : (wouldBuyAgain ? 'yes' : 'no'),
        },
      );

      // Attribute to a recent bean review nudge tap if within 60 minutes.
      if (coffeeBeansUuid != null) {
        unawaited(_maybeTrackReviewAfterNotification(coffeeBeansUuid));
      }

      return true;
    } catch (error) {
      AppLogger.error(
        'Error submitting review',
        errorObject: AppLogger.sanitize(error),
      );
      return false;
    }
  }

  Future<void> _maybeTrackReviewAfterNotification(String beansUuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notif_bean_review_tap_ms_$beansUuid';
      final triggerKey = 'notif_bean_review_tap_trigger_$beansUuid';
      final tapMs = prefs.getInt(key);
      if (tapMs == null) return;
      final secondsSinceTap =
          (DateTime.now().millisecondsSinceEpoch - tapMs) ~/ 1000;
      if (secondsSinceTap < 0 || secondsSinceTap > 60 * 60) {
        await prefs.remove(key);
        await prefs.remove(triggerKey);
        return;
      }
      final trigger = prefs.getString(triggerKey);
      AnalyticsService.instance.track(
        'review_added_after_notification',
        properties: {
          'bean_uuid': beansUuid,
          'notification_type': 'bean_review_nudge',
          'trigger': ?trigger,
          'seconds_since_tap': secondsSinceTap,
        },
      );
      await prefs.remove(key);
      await prefs.remove(triggerKey);
    } catch (e) {
      AppLogger.debug('Review attribution check failed: $e');
    }
  }

  /// Updates an existing review (all fields editable).
  Future<bool> updateReview({
    required String reviewId,
    required String roasterProfileId,
    required double rating,
    String? reviewText,
    double? sweetness,
    double? acidity,
    double? fruitiness,
    double? body,
    String? coffeeBeansUuid,
    String? brewingMethodId,
    bool? wouldBuyAgain,
    List<String>? flavorTags,
    double? bitterness,
    double? aftertaste,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client
          .from('bean_reviews')
          .update({
            'rating': rating,
            'review_text': reviewText,
            'sweetness': sweetness,
            'acidity': acidity,
            'fruitiness': fruitiness,
            'body': body,
            'brewing_method_id': brewingMethodId,
            'would_buy_again': wouldBuyAgain,
            'flavor_tags': flavorTags,
            'bitterness': bitterness,
            'aftertaste': aftertaste,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('user_id', user.id)
          .timeout(NetworkTimeouts.handshake);

      final hasTasteProfile = sweetness != null ||
          acidity != null ||
          fruitiness != null ||
          body != null ||
          bitterness != null ||
          aftertaste != null;
      AnalyticsService.instance.track(
        'review_edited',
        properties: {
          'bean_uuid': ?coffeeBeansUuid,
          'rating': rating.round(),
          'has_text': reviewText != null && reviewText.isNotEmpty,
          'has_taste_profile': hasTasteProfile,
          'has_flavor_tags': flavorTags != null && flavorTags.isNotEmpty,
          'has_would_buy_again': wouldBuyAgain != null,
        },
      );

      _invalidateCacheForRoaster(roasterProfileId);
      if (coffeeBeansUuid != null) {
        _userBeanReviewCache.remove(coffeeBeansUuid);
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          unawaited(
            _userReviewPersistentCache.remove('${uid}_$coffeeBeansUuid'),
          );
        }
      }
      // Server trigger has already cleared `bean_review_translations` for this
      // review; mirror that in the in-memory cache so listeners reload.
      _invalidateTranslationsForReview(reviewId);
      return true;
    } catch (error) {
      AppLogger.error(
        'Error updating review',
        errorObject: AppLogger.sanitize(error),
      );
      return false;
    }
  }

  /// Deletes a review.
  Future<bool> deleteReview({
    required String reviewId,
    String? roasterProfileId,
    String? coffeeBeansUuid,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client
          .from('bean_reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', user.id)
          .timeout(NetworkTimeouts.handshake);

      AnalyticsService.instance.track(
        'review_deleted',
        properties: {
          'bean_uuid': ?coffeeBeansUuid,
          'has_roaster_profile': roasterProfileId != null,
        },
      );

      if (roasterProfileId != null) {
        // Splice the deleted review out of the cached list rather than nuking
        // the whole cache — keeps the remaining reviews visible immediately.
        final cached = _reviewsCache[roasterProfileId];
        if (cached != null) {
          _reviewsCache[roasterProfileId] =
              cached.where((r) => r.id != reviewId).toList();
        }
        // Ratings count changed — clear so it refreshes next time.
        _ratingsCache.remove(roasterProfileId);
      }
      if (coffeeBeansUuid != null) {
        _userBeanReviewCache.remove(coffeeBeansUuid);
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          unawaited(
            _userReviewPersistentCache.remove('${uid}_$coffeeBeansUuid'),
          );
        }
      }
      _invalidateTranslationsForReview(reviewId);
      notifyListeners();
      return true;
    } catch (error) {
      AppLogger.error(
        'Error deleting review',
        errorObject: AppLogger.sanitize(error),
      );
      return false;
    }
  }

  /// Fetches all reviews by the current user.
  Future<List<BeanReviewModel>> fetchUserReviews() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await Supabase.instance.client
          .from('bean_reviews')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .timeout(NetworkTimeouts.smallSync);
      return (response as List)
          .map((e) => BeanReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (error) {
      AppLogger.error(
        'Error fetching user reviews',
        errorObject: AppLogger.sanitize(error),
      );
      return [];
    }
  }

  /// Fetches the current user's review for a specific bean on a roaster.
  Future<BeanReviewModel?> fetchUserReviewForBean({
    required String roasterProfileId,
    required String beanName,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('bean_reviews')
          .select()
          .eq('user_id', user.id)
          .eq('roaster_profile_id', roasterProfileId)
          .eq('bean_name', beanName)
          .maybeSingle()
          .timeout(NetworkTimeouts.handshake);
      if (response == null) return null;
      return BeanReviewModel.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (error) {
      AppLogger.error(
        'Error fetching user review for bean',
        errorObject: AppLogger.sanitize(error),
      );
      return null;
    }
  }

  /// Submits or updates a roaster admin reply to a review.
  Future<bool> submitReply({
    required String reviewId,
    required String replyText,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client.from('review_replies').upsert({
        'review_id': reviewId,
        'user_id': user.id,
        'reply_text': replyText,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).timeout(NetworkTimeouts.handshake);
      // Invalidate all roaster caches so replies reload
      _reviewsCache.clear();
      notifyListeners();
      return true;
    } catch (error) {
      AppLogger.error(
        'Error submitting reply',
        errorObject: AppLogger.sanitize(error),
      );
      return false;
    }
  }

  /// Deletes a roaster admin reply.
  Future<bool> deleteReply({required String reviewId}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client
          .from('review_replies')
          .delete()
          .eq('review_id', reviewId)
          .eq('user_id', user.id)
          .timeout(NetworkTimeouts.handshake);
      _reviewsCache.clear();
      notifyListeners();
      return true;
    } catch (error) {
      AppLogger.error(
        'Error deleting reply',
        errorObject: AppLogger.sanitize(error),
      );
      return false;
    }
  }

  void _invalidateCacheForRoaster(String roasterProfileId) {
    _reviewsCache.remove(roasterProfileId);
    _ratingsCache.remove(roasterProfileId);
    notifyListeners();
  }

  void _invalidateTranslationsForReview(String reviewId) {
    _translationCache.removeWhere((key, _) => key.startsWith('$reviewId|'));
  }

  /// Invokes the `translate-bean-review` edge function for a single review.
  /// Returns null on error; callers should show a generic failure message.
  Future<ReviewTranslation?> fetchTranslation({
    required String reviewId,
    required String targetLocale,
  }) async {
    final key = _translationKey(reviewId, targetLocale);
    final cached = _translationCache[key];
    if (cached != null) return cached;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'translate-bean-review',
        body: {'review_id': reviewId, 'target_locale': targetLocale},
      ).timeout(NetworkTimeouts.smallSync);
      final data = response.data;
      if (data is! Map) {
        AnalyticsService.instance.track(
          'review_translated',
          properties: {
            'target_locale': targetLocale,
            'status': 'error',
          },
        );
        return null;
      }
      final dataMap = Map<String, dynamic>.from(data);
      final result = _translationFromMap(
        reviewId: reviewId,
        targetLocale: targetLocale,
        data: dataMap,
      );
      if (result != null) {
        _translationCache[key] = result;
        notifyListeners();
      }
      AnalyticsService.instance.track(
        'review_translated',
        properties: {
          'target_locale': targetLocale,
          'status': (dataMap['status'] as String?) ?? 'unknown',
          if (dataMap['source_locale'] is String)
            'source_locale': dataMap['source_locale'],
        },
      );
      return result;
    } catch (error) {
      AppLogger.error(
        'Error fetching review translation',
        errorObject: AppLogger.sanitize(error),
      );
      AnalyticsService.instance.track(
        'review_translated',
        properties: {
          'target_locale': targetLocale,
          'status': 'error',
        },
      );
      return null;
    }
  }

  /// Invokes the `translate-bean-review` edge function in batch mode for the
  /// "Translate all reviews" action. Already-cached entries are skipped.
  Future<void> fetchTranslationsBatch({
    required List<String> reviewIds,
    required String targetLocale,
  }) async {
    final pending = reviewIds
        .where((id) => !_translationCache.containsKey(_translationKey(id, targetLocale)))
        .toList();
    if (pending.isEmpty) return;
    var succeeded = 0;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'translate-bean-review',
        body: {'review_ids': pending, 'target_locale': targetLocale},
      ).timeout(NetworkTimeouts.smallSync);
      final data = response.data;
      if (data is! Map) {
        AnalyticsService.instance.track(
          'reviews_translated_batch',
          properties: {
            'target_locale': targetLocale,
            'requested_count': pending.length,
            'succeeded_count': 0,
          },
        );
        return;
      }
      final results = (data['results'] as List?) ?? const [];
      var changed = false;
      for (final raw in results) {
        if (raw is! Map) continue;
        final entry = Map<String, dynamic>.from(raw);
        final reviewId = entry['review_id'] as String?;
        if (reviewId == null) continue;
        final result = _translationFromMap(
          reviewId: reviewId,
          targetLocale: targetLocale,
          data: entry,
        );
        if (result != null) {
          _translationCache[_translationKey(reviewId, targetLocale)] = result;
          succeeded++;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (error) {
      AppLogger.error(
        'Error fetching review translations batch',
        errorObject: AppLogger.sanitize(error),
      );
    } finally {
      AnalyticsService.instance.track(
        'reviews_translated_batch',
        properties: {
          'target_locale': targetLocale,
          'requested_count': pending.length,
          'succeeded_count': succeeded,
        },
      );
    }
  }

  ReviewTranslation? _translationFromMap({
    required String reviewId,
    required String targetLocale,
    required Map<String, dynamic> data,
  }) {
    final status = data['status'] as String?;
    if (status == 'translated' || status == 'cached') {
      final text = data['translated_text'] as String?;
      final source = data['source_locale'] as String?;
      if (text == null || source == null) return null;
      return ReviewTranslation(
        reviewId: reviewId,
        targetLocale: targetLocale,
        translatedText: text,
        sourceLocale: source,
        model: data['model'] as String?,
      );
    }
    if (status == 'same_language') {
      final source = data['source_locale'] as String? ?? targetLocale;
      return ReviewTranslation(
        reviewId: reviewId,
        targetLocale: targetLocale,
        sourceLocale: source,
        sameLanguage: true,
      );
    }
    // empty / forbidden / not_found / error / unknown — don't cache.
    return null;
  }

  void clearAll() {
    _reviewsCache.clear();
    _ratingsCache.clear();
    _userBeanReviewCache.clear();
    _translationCache.clear();
    unawaited(_userReviewPersistentCache.clear());
    notifyListeners();
  }
}
