// lib/models/roaster_profile_model.dart

class RoasterProfileModel {
  final String id;
  final String slug;
  final int coffeeRoasterId;
  final String? adminUserId;
  final String roasterName;
  final String? roasterLogoUrl;
  final String? roasterLogoMirrorUrl;
  final String? websiteUrl;
  final String? description;
  final String? city;
  final String? state;
  final String? country;
  final String? addressText;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final bool isActive;
  final String? dominantColorHex;

  const RoasterProfileModel({
    required this.id,
    required this.slug,
    required this.coffeeRoasterId,
    this.adminUserId,
    required this.roasterName,
    this.roasterLogoUrl,
    this.roasterLogoMirrorUrl,
    this.websiteUrl,
    this.description,
    this.city,
    this.state,
    this.country,
    this.addressText,
    this.instagramUrl,
    this.twitterUrl,
    this.facebookUrl,
    this.tiktokUrl,
    required this.isActive,
    this.dominantColorHex,
  });

  factory RoasterProfileModel.fromJson(Map<String, dynamic> json) {
    return RoasterProfileModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      coffeeRoasterId: json['coffee_roaster_id'] as int,
      adminUserId: json['admin_user_id'] as String?,
      roasterName: json['roaster_name'] as String,
      roasterLogoUrl: json['roaster_logo_url'] as String?,
      roasterLogoMirrorUrl: json['roaster_logo_mirror_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      description: json['description'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      addressText: json['address_text'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      twitterUrl: json['twitter_url'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      dominantColorHex: json['dominant_color_hex'] as String?,
    );
  }

  /// Returns a human-readable location string, e.g. "Berlin, Bavaria, Germany"
  String? get locationLabel {
    final parts = [city, state, country]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
