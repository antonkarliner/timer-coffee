// Ratchet for raw style literals in screens and widgets (plan 090, H2b).
//
// Counts `fontSize: <number>` and `Radius.circular(<number>)` in lib/screens
// and lib/widgets and fails if either count rises above the recorded limit.
// The count may only go down: when a sweep removes literals, lower the
// matching limit below to the new count so they cannot creep back.
//
// Use the design tokens instead (lib/theme/design_tokens.dart):
// AppTextStyles.* for sizes, AppRadius.* for corner radii.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Recorded on 2026-11-20 at plan 090's H2a commit (7ffaeb61).
const int _maxFontSizeLiterals = 38;
const int _maxRadiusLiterals = 13;

/// Files with their own art direction or debug-only UI, not held to tokens.
const Set<String> _exempt = {
  'lib/screens/notification_debug_screen.dart',
  'lib/screens/yearly_stats_story_24_screen.dart',
  'lib/screens/yearly_stats_story_25_screen.dart',
};

final RegExp _fontSizeLiteral = RegExp(r'fontSize:\s*\d');
final RegExp _radiusLiteral = RegExp(r'Radius\.circular\(\s*\d');

Map<String, int> _countPerFile(RegExp pattern) {
  final counts = <String, int>{};
  for (final root in ['lib/screens', 'lib/widgets']) {
    final dir = Directory(root);
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (_exempt.contains(path)) continue;
      final n = pattern.allMatches(entity.readAsStringSync()).length;
      if (n > 0) counts[path] = n;
    }
  }
  return counts;
}

String _describe(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((e) => '  ${e.value}  ${e.key}').join('\n');
}

void main() {
  test('exempt files still exist (update the list if one is removed)', () {
    for (final path in _exempt) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('fontSize literals do not increase', () {
    final counts = _countPerFile(_fontSizeLiteral);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    expect(
      total,
      lessThanOrEqualTo(_maxFontSizeLiterals),
      reason:
          'Found $total `fontSize: <number>` literals (limit '
          '$_maxFontSizeLiterals). Use AppTextStyles instead.\n'
          '${_describe(counts)}',
    );
  });

  test('Radius.circular literals do not increase', () {
    final counts = _countPerFile(_radiusLiteral);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    expect(
      total,
      lessThanOrEqualTo(_maxRadiusLiterals),
      reason:
          'Found $total `Radius.circular(<number>)` literals (limit '
          '$_maxRadiusLiterals). Use AppRadius instead.\n'
          '${_describe(counts)}',
    );
  });
}
