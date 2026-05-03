// lib/providers/bean_review_provider.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/utils/app_logger.dart';

class RatingsSummary {
  final double? avgRating;
  final int reviewCount;

  const RatingsSummary({this.avgRating, required this.reviewCount});
}

class BeanReviewProvider extends ChangeNotifier {
  // Paginated reviews per roaster profile, keyed by roasterProfileId
  final Map<String, List<BeanReviewModel>> _reviewsCache = {};
  final Map<String, RatingsSummary> _ratingsCache = {};
  // User's own review per bean UUID (null value means "fetched, no review")
  final Map<String, BeanReviewModel?> _userBeanReviewCache = {};

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
      );
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
      );
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
    try {
      final response = await Supabase.instance.client
          .from('bean_reviews')
          .select()
          .eq('user_id', user.id)
          .eq('coffee_beans_uuid', beansUuid)
          .maybeSingle();
      final review = response != null
          ? BeanReviewModel.fromJson(Map<String, dynamic>.from(response as Map))
          : null;
      _userBeanReviewCache[beansUuid] = review;
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
        if (roasterProfileId != null) 'roaster_profile_id': roasterProfileId,
        'roaster_name': roasterName,
        'bean_name': beanName,
        if (coffeeBeansUuid != null) 'coffee_beans_uuid': coffeeBeansUuid,
        'rating': rating,
        if (reviewText != null) 'review_text': reviewText,
        if (sweetness != null) 'sweetness': sweetness,
        if (acidity != null) 'acidity': acidity,
        if (fruitiness != null) 'fruitiness': fruitiness,
        if (body != null) 'body': body,
        if (brewingMethodId != null) 'brewing_method_id': brewingMethodId,
        if (wouldBuyAgain != null) 'would_buy_again': wouldBuyAgain,
        if (flavorTags != null && flavorTags.isNotEmpty)
          'flavor_tags': flavorTags,
        if (bitterness != null) 'bitterness': bitterness,
        if (aftertaste != null) 'aftertaste': aftertaste,
        'is_public': true,
      });
      if (roasterProfileId != null) _invalidateCacheForRoaster(roasterProfileId);
      if (coffeeBeansUuid != null) _userBeanReviewCache.remove(coffeeBeansUuid);
      return true;
    } catch (error) {
      AppLogger.error(
        'Error submitting review',
        errorObject: AppLogger.sanitize(error),
      );
      return false;
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
          .eq('user_id', user.id);
      _invalidateCacheForRoaster(roasterProfileId);
      if (coffeeBeansUuid != null) _userBeanReviewCache.remove(coffeeBeansUuid);
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
          .eq('user_id', user.id);
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
      if (coffeeBeansUuid != null) _userBeanReviewCache.remove(coffeeBeansUuid);
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
          .order('created_at', ascending: false);
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
          .maybeSingle();
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
      });
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
          .eq('user_id', user.id);
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

  void clearAll() {
    _reviewsCache.clear();
    _ratingsCache.clear();
    _userBeanReviewCache.clear();
    notifyListeners();
  }
}
