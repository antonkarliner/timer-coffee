class LaunchPopupModel {
  final int id;
  final String content;
  final String locale;
  final DateTime createdAt;
  final String platform; // 'ios' | 'android' | 'web' | 'all'

  LaunchPopupModel({
    required this.id,
    required this.content,
    required this.locale,
    required this.createdAt,
    required this.platform,
  });

  /// Construct from a Supabase row/map. Normalizes platform to one of
  /// 'ios', 'android', 'web', 'all' and defaults to 'all' for null/unknown.
  factory LaunchPopupModel.fromMap(Map<String, dynamic> map) {
    final rawPlatform = (map['platform'] as String?)?.toLowerCase() ?? 'all';
    final normalizedPlatform =
        ['ios', 'android', 'web', 'all'].contains(rawPlatform)
            ? rawPlatform
            : 'all';

    return LaunchPopupModel(
      id: map['id'] as int,
      content: map['content'] as String,
      locale: map['locale'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      platform: normalizedPlatform,
    );
  }
}
