import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

enum _Category { decoration, keptByVerdict, heldUntil, unreviewed }

class _Allowed {
  const _Allowed(this.count, this.category, this.reason);

  final int count;
  final _Category category;
  final String reason;
}

const Map<String, _Allowed> _allowlist = {
  'lib/screens/brewing_process_screen.dart': _Allowed(
    3,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (1635 and 1637 "
    'previous/next step chevrons, 2101 countdown seconds label paired with the layout preview).',
  ),
  'lib/screens/coffee_beans_screen.dart': _Allowed(
    1,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (171 beans loading error icon).",
  ),
  'lib/screens/roaster_profile_screen.dart': _Allowed(
    4,
    _Category.heldUntil,
    'TEMPORARY (added 2026-11-19): remove when plan 089 Phase 5b finishes these files. '
    'Held for plan 087 Phases 6 and 8b (482 divider, 640 bags logged, '
    '735 review eligibility, 908 disclaimer bullet and text).',
  ),
  'lib/screens/roasters_screen.dart': _Allowed(
    3,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (149 offline icon, "
    '164 offline description, 192 empty catalog or search message).',
  ),
  'lib/screens/stats_screen.dart': _Allowed(
    4,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (77 thumbnail fallback icon, "
    '375 brewed coffee and 430 personal / 916 global top recipes “No data” text).',
  ),
  'lib/widgets/brewing/layout_preview_cards.dart': _Allowed(
    1,
    _Category.keptByVerdict,
    'The miniature seconds label mirrors the ring countdown in '
    'brewing_process_screen.dart. Change both together.',
  ),
  'lib/widgets/coffee_bean_details/coffee_beans_hero_header.dart': _Allowed(
    3,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (119 roaster name, "
    '122 bean origin, 124 fallback coffee bag icon).',
  ),
  'lib/widgets/coffee_beans/coffee_beans_content.dart': _Allowed(
    2,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (117 empty search icon, "
    '149 empty beans list icon).',
  ),
  'lib/widgets/coffee_beans/coffee_beans_empty_state.dart': _Allowed(
    1,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (66 empty beans or search icon).",
  ),
  'lib/widgets/containers/section_card.dart': _Allowed(
    1,
    _Category.decoration,
    'Divider between the card header and its content.',
  ),
  'lib/widgets/delete_button.dart': _Allowed(
    1,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (27 disabled delete icon).",
  ),
  'lib/widgets/fields/otp_code_field.dart': _Allowed(
    3,
    _Category.keptByVerdict,
    'Alpha 0 hides the input layer text and cursor. '
    'Alpha 0.38 is the disabled convention for the displayed digits.',
  ),
  'lib/widgets/fields/time_field.dart': _Allowed(
    1,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (383 unselected time wheel labels).",
  ),
  'lib/widgets/recipe_detail/bean_selection_row.dart': _Allowed(
    2,
    _Category.unreviewed,
    "follow-up: text/icon fade not in plan 089's list (434 fallback coffee bag icon). "
    '48 is decoration: the 6% press overlay (`cs.onSurface`).',
  ),
  'lib/widgets/roaster_profile/taste_profile_sliders.dart': _Allowed(
    5,
    _Category.decoration,
    'Active and inactive tracks and thumb before interaction, plus the empty and background display tracks.',
  ),
};

void main() {
  test('Plan 089 D5 guards against alpha-faded text and icons', () {
    final whitespace = RegExp(r'\s+');
    final alphaFade = RegExp(
      // Any receiver: `colorScheme.`, `scheme.`, `cs.` all reach the same
      // members.
      r'\w+\.(?:onSurface|onSurfaceVariant|onBackground)\.'
      r'(?:withValues\(alpha:|withOpacity\()',
    );
    final counts = <String, int>{};

    for (final root in ['lib/screens', 'lib/widgets']) {
      final files = Directory(root).listSync(recursive: true).whereType<File>();
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        if (!name.endsWith('.dart') ||
            name.startsWith('yearly_stats_story_') ||
            name == 'notification_debug_screen.dart' ||
            name == 'moments_debug_screen.dart') {
          continue;
        }

        final source = file.readAsStringSync().replaceAll(whitespace, '');
        final count = alphaFade.allMatches(source).length;
        if (count > 0) {
          counts[file.path.replaceAll(Platform.pathSeparator, '/')] = count;
        }
      }
    }

    final violations = <String>[];
    final paths = {..._allowlist.keys, ...counts.keys}.toList()..sort();
    for (final path in paths) {
      final allowed = _allowlist[path];
      final limit = allowed?.count ?? 0;
      final count = counts[path] ?? 0;
      if (count == limit) continue;

      final details = allowed == null
          ? 'No allowlist entry.'
          : '${allowed.category.name}. ${allowed.reason}';
      final action = count < limit
          ? ' Lower the allowlist count to $count. Remove the entry when it reaches zero.'
          : '';
      violations.add(
        '$path has $count matches ($limit allowed). $details$action',
      );
    }

    if (violations.isNotEmpty) {
      fail(
        'Plan 089 D5. Never alpha-fade text or icons. '
        'Use onSurfaceVariant for readable text and icons and outline for '
        'tertiary metadata inside cards. Decorations belong in the allowlist '
        'with a reason.\n${violations.join('\n')}',
      );
    }
  });
}
