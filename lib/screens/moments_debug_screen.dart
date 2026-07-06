import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/moments_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../widgets/falling_beans_overlay.dart';

/// Internal debug surface for exercising every "moment" trigger without
/// having to wait for real conditions (anniversary date, Oct 1st, peer brews
/// landing in the same minute, etc.).
///
/// Reachable in debug builds via the Info screen entry, or anytime by deep
/// linking to `/debug/moments`. Never linked from production-visible UI.
@RoutePage()
class MomentsDebugScreen extends StatefulWidget {
  const MomentsDebugScreen({super.key});

  @override
  State<MomentsDebugScreen> createState() => _MomentsDebugScreenState();
}

class _MomentsDebugScreenState extends State<MomentsDebugScreen> {
  int _beansRunId = 0;
  int _beansCycles = 0;

  void _triggerBeans(int cycles) {
    setState(() {
      _beansRunId += 1;
      _beansCycles = cycles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moments debug'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            children: [
              const _HowToTestSection(),
              const SizedBox(height: AppSpacing.base),
              const _NowOverrideSection(),
              const SizedBox(height: AppSpacing.base),
              const _FirstBrewSection(),
              const SizedBox(height: AppSpacing.base),
              const _DiscoverySection(),
              const SizedBox(height: AppSpacing.base),
              const _AnnualFlagsSection(),
              const SizedBox(height: AppSpacing.base),
              const _InSyncInfoSection(),
              const SizedBox(height: AppSpacing.base),
              _FallingBeansSection(onTrigger: _triggerBeans),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
          if (_beansCycles > 0)
            Positioned.fill(
              child: FallingBeansOverlay(
                key: ValueKey(_beansRunId),
                cycles: _beansCycles,
                onComplete: () {
                  if (!mounted) return;
                  setState(() => _beansCycles = 0);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable building blocks
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _NowOverrideSection extends StatelessWidget {
  const _NowOverrideSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<MomentsService>(
      builder: (context, moments, _) {
        final override = moments.debugNowOverride;
        return _Section(
          title: 'Now override',
          children: [
            _KeyValue(
              label: 'Real now:',
              value: DateTime.now().toIso8601String(),
            ),
            _KeyValue(
              label: 'Override:',
              value: override?.toIso8601String() ?? '— (using real clock)',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppTextButton(
                  label: 'Today (real)',
                  onPressed: () => moments.debugSetNow(null),
                ),
                AppTextButton(
                  label: 'Oct 1 (this year)',
                  onPressed: () {
                    final now = DateTime.now();
                    moments.debugSetNow(DateTime(now.year, 10, 1, 12));
                  },
                ),
                AppTextButton(
                  label: 'Apr 1 (this year)',
                  onPressed: () {
                    final now = DateTime.now();
                    moments.debugSetNow(DateTime(now.year, 4, 1, 12));
                  },
                ),
                AppTextButton(
                  label: 'Anniversary (1y after first brew)',
                  onPressed: () {
                    final first = moments.debugCachedFirstBrewAt ??
                        moments.debugReadPersistedFirstBrewAt();
                    if (first == null) {
                      _showSnack(
                        context,
                        'No first brew set; seed it in the next section first.',
                      );
                      return;
                    }
                    moments.debugSetNow(DateTime(
                      first.year + 1,
                      first.month,
                      first.day,
                      12,
                    ));
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _FirstBrewSection extends StatelessWidget {
  const _FirstBrewSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<MomentsService>(
      builder: (context, moments, _) {
        final cached = moments.debugCachedFirstBrewAt;
        final persisted = moments.debugReadPersistedFirstBrewAt();
        return _Section(
          title: 'First brew at',
          children: [
            _KeyValue(
              label: 'Cached:',
              value: cached?.toIso8601String() ?? '—',
            ),
            _KeyValue(
              label: 'Persisted:',
              value: persisted?.toIso8601String() ?? '—',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppTextButton(
                  label: '1 year ago',
                  onPressed: () => moments.debugSetFirstBrewAt(
                    DateTime.now().subtract(const Duration(days: 365)),
                  ),
                ),
                AppTextButton(
                  label: '6 months ago',
                  onPressed: () => moments.debugSetFirstBrewAt(
                    DateTime.now().subtract(const Duration(days: 183)),
                  ),
                ),
                AppTextButton(
                  label: '1 day ago',
                  onPressed: () => moments.debugSetFirstBrewAt(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ),
                ),
                AppTextButton(
                  label: 'Clear',
                  onPressed: () => moments.debugSetFirstBrewAt(null),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection();

  @override
  Widget build(BuildContext context) {
    return Consumer<MomentsService>(
      builder: (context, moments, _) {
        return _Section(
          title:
              'Discovery — ${moments.discoveredCount}/${moments.totalMoments}',
          children: [
            for (final id in kAllMomentIds)
              _DiscoveryRow(id: id, moments: moments),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    label: 'Mark all',
                    onPressed: () => moments.debugMarkAllDiscovered(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextButton(
                    label: 'Reset all',
                    onPressed: () => moments.debugResetAllDiscoveries(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DiscoveryRow extends StatelessWidget {
  const _DiscoveryRow({required this.id, required this.moments});

  final String id;
  final MomentsService moments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discovered = moments.isDiscovered(id);
    return InkWell(
      onTap: () => discovered
          ? moments.debugUnmarkDiscovered(id)
          : moments.markDiscovered(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              discovered ? Icons.check_circle : Icons.radio_button_unchecked,
              color: discovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              size: AppIconSize.medium,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                id,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              discovered ? 'tap to unmark' : 'tap to mark',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnualFlagsSection extends StatelessWidget {
  const _AnnualFlagsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<MomentsService>(
      builder: (context, moments, _) {
        final annShown = moments.isAnniversaryShownThisYear();
        final coffeeDayDismissed = moments.isCoffeeDayDismissedThisYear();
        return _Section(
          title: 'Annual flags',
          children: [
            _KeyValue(
              label: 'Anniversary shown this year:',
              value: annShown ? 'yes' : 'no',
            ),
            _KeyValue(
              label: 'Coffee Day dismissed this year:',
              value: coffeeDayDismissed ? 'yes' : 'no',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppTextButton(
                  label: 'Reset anniversary flag',
                  onPressed: () => moments.debugResetAnniversaryShown(),
                ),
                AppTextButton(
                  label: 'Reset Coffee Day dismissal',
                  onPressed: () => moments.debugResetCoffeeDayDismissed(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InSyncInfoSection extends StatelessWidget {
  const _InSyncInfoSection();

  // Country preset packs for the "force in-sync" buttons. Each pack covers a
  // different render path on the in-sync card.
  static const List<String> _countriesShort = ['US', 'DE', 'RU'];
  static const List<String> _countriesLong = [
    'US', 'DE', 'RU', 'JP', 'GB', 'FR', 'IT', 'CA',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MomentsService>(
      builder: (context, moments, _) {
        final hourUtc =
            (moments.debugNowOverride ?? DateTime.now()).toUtc().hour;
        final threshold = moments.debugInSyncThresholdNow;
        final pending = moments.debugForcedInSync;
        final pendingLabel = pending == null
            ? '— (no force)'
            : pending.countries.isEmpty
                ? 'count=${pending.count}, no countries'
                : 'count=${pending.count}, '
                    '${pending.countries.length} countries '
                    '(${pending.countries.take(4).join(", ")}'
                    '${pending.countries.length > 4 ? "…" : ""})';

        return _Section(
          title: 'In-sync',
          children: [
            _KeyValue(label: 'UTC hour:', value: hourUtc.toString()),
            _KeyValue(
              label: 'Threshold for hour:',
              value: threshold.toString(),
            ),
            _KeyValue(label: 'Forced (next brew):', value: pendingLabel),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Count-only — fires the count line; no "from countries" subtitle:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppTextButton(
                  label: 'Force = 1',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(1),
                ),
                AppTextButton(
                  label: 'Force = 3',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(3),
                ),
                AppTextButton(
                  label: 'Force = 5',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(5),
                ),
                AppTextButton(
                  label: 'Force = threshold',
                  onPressed: () =>
                      moments.debugForceInSyncOnNextBrew(threshold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'With countries — exercises the "from US, DE and RU" subtitle:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppTextButton(
                  label: '3, US/DE/RU',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(
                    3,
                    countries: _countriesShort,
                  ),
                ),
                AppTextButton(
                  label: '8, top 8 globally',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(
                    _countriesLong.length,
                    countries: _countriesLong,
                  ),
                ),
                AppTextButton(
                  label: '1, just US',
                  onPressed: () =>
                      moments.debugForceInSyncOnNextBrew(1, countries: ['US']),
                ),
                AppTextButton(
                  label: '2, US/JP',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(
                    2,
                    countries: ['US', 'JP'],
                  ),
                ),
                AppTextButton(
                  label: 'Clear force',
                  onPressed: () => moments.debugForceInSyncOnNextBrew(null),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HowToTestSection extends StatelessWidget {
  const _HowToTestSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Theme(
        // Trim the default ExpansionTile divider so it sits flush in the card.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.base,
          ),
          leading: const Icon(Icons.help_outline),
          title: const Text('How to test each moment'),
          children: const [
            _HowToRow(
              title: 'Anniversary',
              steps: [
                '1. First brew at → "1 year ago".',
                '2. Now override → "Anniversary (1y after first brew)".',
                '3. Annual flags → "Reset anniversary flag" (in case shown earlier today).',
                '4. Complete any brew → Finish screen shows the anniversary card + falling beans.',
                'Note: anniversary requires year ≥ 1 elapsed. The "1 year ago" preset uses today − 365 days, so the day component matches today.',
              ],
            ),
            _HowToRow(
              title: 'International Coffee Day banner',
              steps: [
                '1. Now override → "Oct 1 (this year)".',
                '2. Annual flags → "Reset Coffee Day dismissal" (if you dismissed earlier).',
                '3. Open the Brewing Methods tab → banner shows above the methods list.',
                '4. Tap the close icon → banner persists year-scoped, won\'t return until next year (or until you reset the flag).',
              ],
            ),
            _HowToRow(
              title: 'In-sync (recommended path)',
              steps: [
                '1. In-sync section here → pick a "Count-only" force (no country subtitle) or a "With countries" preset.',
                '2. Start any brew → finish it.',
                '3. Finish screen shows the in-sync card in the same slot the coffee fact normally occupies. Falling beans cameo plays.',
                'Country presets exercise the "from USA, Germany and Russia" subtitle (≤3 named, locale-genitive form). The "8, top 8 globally" preset exercises the "and N others" overflow path.',
                'Override is one-shot: it clears the moment Finish consumes it. Re-tap the force button before each test brew.',
                'Pick "Force = 1" with the threshold ≥ 2 to verify the silent-miss path (coffee fact still renders).',
              ],
            ),
            _HowToRow(
              title: 'In-sync (real Supabase path)',
              steps: [
                'For verifying the actual query: insert N rows into Supabase global_stats with created_at within ±60s of "now", distinct user_ids, where N ≥ debugInSyncThresholdNow. Set country_code on each row to exercise the country subtitle.',
                'Then complete a real brew within that 60s window. Finish screen will dedupe by user_id, count distinct peers, and fire if ≥ threshold.',
                'Use the Supabase MCP execute_sql tool, or the Supabase dashboard SQL editor.',
              ],
            ),
            _HowToRow(
              title: 'Empty Brew Diary charm',
              steps: [
                '1. Brew Diary needs to be empty. Either sign in as a fresh anonymous user, or temporarily delete all your stats.',
                '2. Open the Brew Diary tab.',
                '3. The illustrated empty state appears with a "Brew something" CTA returning to Brewing Methods.',
              ],
            ),
            _HowToRow(
              title: 'Falling beans cameo',
              steps: [
                'Plays automatically on top of: anniversary and in-sync (when fired).',
                'Visually verify by triggering either of the above. The overlay runs 2 cycles on Finish, then auto-removes.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToRow extends StatelessWidget {
  const _HowToRow({required this.title, required this.steps});
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                step,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _FallingBeansSection extends StatelessWidget {
  const _FallingBeansSection({required this.onTrigger});

  final void Function(int cycles) onTrigger;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Falling beans',
      children: [
        Text(
          'Plays the overlay over this screen so you can sanity-check the '
          'physics tuning without finishing a real brew.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            AppTextButton(
              label: '1 cycle (used by anniversary / in-sync)',
              onPressed: () => onTrigger(1),
            ),
            AppTextButton(
              label: '2 cycles',
              onPressed: () => onTrigger(2),
            ),
          ],
        ),
      ],
    );
  }
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
