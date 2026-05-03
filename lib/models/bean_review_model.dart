// lib/models/bean_review_model.dart

class BeanReviewModel {
  final String id;
  final String userId;
  final String? roasterProfileId;
  final String roasterName;
  final String beanName;
  final String? coffeeBeansUuid; // Private: only visible to the author in-app
  final double rating;
  final String? reviewText;
  final double? sweetness;
  final double? acidity;
  final double? fruitiness;
  final double? body;
  final String? brewingMethodId;
  final bool? wouldBuyAgain;
  final List<String>? flavorTags;
  final double? bitterness;
  final double? aftertaste;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined fields from get_roaster_reviews
  final String? reviewerDisplayName;
  final String? reviewerAvatarUrl;
  final String? replyText;
  final DateTime? replyCreatedAt;
  // Origin + roast date from the reviewer's linked bean record
  final String? beanOrigin;
  final DateTime? beanRoastDate;
  // Joined read-only: brewing method display name from the RPC
  final String? brewingMethodName;

  const BeanReviewModel({
    required this.id,
    required this.userId,
    this.roasterProfileId,
    required this.roasterName,
    required this.beanName,
    this.coffeeBeansUuid,
    required this.rating,
    this.reviewText,
    this.sweetness,
    this.acidity,
    this.fruitiness,
    this.body,
    this.brewingMethodId,
    this.wouldBuyAgain,
    this.flavorTags,
    this.bitterness,
    this.aftertaste,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.reviewerDisplayName,
    this.reviewerAvatarUrl,
    this.replyText,
    this.replyCreatedAt,
    this.beanOrigin,
    this.beanRoastDate,
    this.brewingMethodName,
  });

  factory BeanReviewModel.fromJson(Map<String, dynamic> json) {
    return BeanReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      roasterProfileId: json['roaster_profile_id'] as String?,
      roasterName: json['roaster_name'] as String? ?? '',
      beanName: json['bean_name'] as String,
      coffeeBeansUuid: json['coffee_beans_uuid'] as String?,
      rating: (json['rating'] as num).toDouble(),
      reviewText: json['review_text'] as String?,
      sweetness: (json['sweetness'] as num?)?.toDouble(),
      acidity: (json['acidity'] as num?)?.toDouble(),
      fruitiness: (json['fruitiness'] as num?)?.toDouble(),
      body: (json['body'] as num?)?.toDouble(),
      brewingMethodId: json['brewing_method_id'] as String?,
      wouldBuyAgain: json['would_buy_again'] as bool?,
      flavorTags: (json['flavor_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      bitterness: (json['bitterness'] as num?)?.toDouble(),
      aftertaste: (json['aftertaste'] as num?)?.toDouble(),
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reviewerDisplayName: json['reviewer_display_name'] as String?,
      reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
      replyText: json['reply_text'] as String?,
      replyCreatedAt: json['reply_created_at'] != null
          ? DateTime.parse(json['reply_created_at'] as String)
          : null,
      beanOrigin: json['bean_origin'] as String?,
      beanRoastDate: json['bean_roast_date'] != null
          ? DateTime.parse(json['bean_roast_date'] as String)
          : null,
      brewingMethodName: json['brewing_method_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      if (flavorTags != null && flavorTags!.isNotEmpty) 'flavor_tags': flavorTags,
      if (bitterness != null) 'bitterness': bitterness,
      if (aftertaste != null) 'aftertaste': aftertaste,
      'is_public': isPublic,
    };
  }

  bool get hasTasteProfile =>
      sweetness != null ||
      acidity != null ||
      body != null ||
      bitterness != null ||
      aftertaste != null;

  bool get hasReply => replyText != null;
}
