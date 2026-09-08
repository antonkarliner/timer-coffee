class LaunchPopupModel {
  final int id;
  final String content;
  final String locale;
  final DateTime createdAt;
  final String platform; // 'ios' | 'android' | 'web' | 'all'
  final String? hookType;
  final double? goalAmountUsd;
  final double? progressAmountUsd;
  final DateTime? campaignEndsAt;

  LaunchPopupModel({
    required this.id,
    required this.content,
    required this.locale,
    required this.createdAt,
    required this.platform,
    this.hookType,
    this.goalAmountUsd,
    this.progressAmountUsd,
    this.campaignEndsAt,
  });

  bool get isCampaign => hookType != null;

  bool get isCampaignActive =>
      isCampaign &&
      (campaignEndsAt == null ||
          campaignEndsAt!.isAfter(DateTime.now().toUtc()));

  /// Construct from a Supabase row/map. Normalizes platform to one of
  /// 'ios', 'android', 'web', 'all' and defaults to 'all' for null/unknown.
  factory LaunchPopupModel.fromMap(Map<String, dynamic> map) {
    final rawPlatform = (map['platform'] as String?)?.toLowerCase() ?? 'all';
    final normalizedPlatform =
        ['ios', 'android', 'web', 'all'].contains(rawPlatform)
        ? rawPlatform
        : 'all';
    final rawHookType = (map['hook_type'] as String?)?.toLowerCase();
    final normalizedHookType =
        [
          'license_renewal',
          'coffee_day',
          'black_friday',
          'feature_object',
          'yearly_recap',
        ].contains(rawHookType)
        ? rawHookType
        : null;

    double? parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseCampaignEnd(dynamic value) {
      if (value is! String) return null;
      return DateTime.tryParse(value)?.toUtc();
    }

    return LaunchPopupModel(
      id: map['id'] as int,
      content: map['content'] as String,
      locale: map['locale'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      platform: normalizedPlatform,
      hookType: normalizedHookType,
      goalAmountUsd: parseAmount(map['goal_amount_usd']),
      progressAmountUsd: parseAmount(map['progress_amount_usd']),
      campaignEndsAt: parseCampaignEnd(map['campaign_ends_at']),
    );
  }
}
