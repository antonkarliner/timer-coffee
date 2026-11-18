import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/bean_recommendation_model.dart';
import '../providers/recommendation_provider.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import '../utils/country_names.dart';
import '../utils/stock_attribute_labels.dart';
import '../widgets/base_buttons.dart';
import '../widgets/settings/settings_list.dart';

/// Coffee-producing origin codes offered in the add-origin sheet (ISO
/// 3166-1 alpha-2, upper case — the server's vocabulary for the origin
/// dimension).
const List<String> _originVocabulary = [
  'BO',
  'BR',
  'BI',
  'CN',
  'CO',
  'CR',
  'CU',
  'CD',
  'DO',
  'EC',
  'SV',
  'ET',
  'GT',
  'HT',
  'HN',
  'IN',
  'ID',
  'CI',
  'JM',
  'KE',
  'LA',
  'MW',
  'MX',
  'MM',
  'NI',
  'PA',
  'PG',
  'PE',
  'PH',
  'RW',
  'SA',
  'TZ',
  'TH',
  'TL',
  'UG',
  'VE',
  'VN',
  'YE',
  'ZM',
  'ZW',
];

/// Server-validated process vocabulary.
const List<String> _processVocabulary = [
  'washed',
  'natural',
  'honey',
  'wet_hulled',
  'experimental',
  'other',
];

/// Server-validated roast vocabulary.
const List<String> _roastVocabulary = [
  'light',
  'medium_light',
  'medium',
  'medium_dark',
  'dark',
];

/// Server-validated flavour vocabulary.
const List<String> _flavorVocabulary = [
  'fruity',
  'berry',
  'citrus',
  'stone_fruit',
  'tropical',
  'floral',
  'tea_like',
  'chocolate',
  'nutty',
  'caramel_sweet',
  'spice',
  'earthy',
  'winey_fermented',
];

/// The user's taste profile (plan 086 Phase D1): what their bean and brew
/// history says they like — origins, processes, roasts and flavours — and
/// the More / Less / Never adjustments that steer their bean suggestions.
///
/// Reached from the Account page; the row that opens it is shown only when
/// the bean-recommendations feature is available and the user has not opted
/// out.
@RoutePage()
class TasteProfileScreen extends StatefulWidget {
  const TasteProfileScreen({super.key});

  @override
  State<TasteProfileScreen> createState() => _TasteProfileScreenState();
}

class _TasteProfileScreenState extends State<TasteProfileScreen> {
  /// Guards so the one-shot load is scheduled exactly once, and
  /// `taste_profile_viewed` exactly once per visit.
  bool _loadScheduled = false;
  bool _viewedTracked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadScheduled) return;
    _loadScheduled = true;
    // After the first frame: the inherited lookup must not run in initState,
    // and a gated load notifies synchronously, which must not happen during
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<RecommendationProvider>().loadTasteProfile());
    });
  }

  /// Reports the view once, in the frame the profile first became ready.
  /// Flags and counts only — never taste values.
  void _scheduleViewedAnalytics(RecommendationProvider provider) {
    if (_viewedTracked) return;
    final profile = provider.tasteProfile;
    if (provider.tasteProfileState != TasteProfileLoadState.ready ||
        profile == null) {
      return;
    }
    _viewedTracked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AnalyticsService.maybeInstance?.track(
        'taste_profile_viewed',
        properties: {
          'enough_history': profile.enoughHistory,
          'preference_count': profile.preferences.length,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final provider = context.watch<RecommendationProvider>();
    final profile = provider.tasteProfile;
    final state = provider.tasteProfileState;
    _scheduleViewedAnalytics(provider);

    return SettingsPageScaffold(
      title: l10n.tasteProfileTitle,
      children: [
        // First slot: spinner while loading, load-failure with retry, or
        // nothing once a profile exists — a reload keeps the profile visible.
        if (profile == null &&
            (state == TasteProfileLoadState.idle ||
                state == TasteProfileLoadState.loading))
          const SettingsSection(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          )
        else if (profile == null && state == TasteProfileLoadState.error)
          SettingsSection(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.base,
                  AppSpacing.sm,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.tasteLoadFailed, style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextButton(
                      label: l10n.retry,
                      onPressed: () => unawaited(
                        context
                            .read<RecommendationProvider>()
                            .loadTasteProfile(),
                      ),
                      isFullWidth: false,
                      height: AppButton.heightSmall,
                      padding: AppButton.paddingSmall,
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        _summarySection(l10n, locale, profile),
        _dimensionSection(
          context,
          provider,
          TasteDimension.origin,
          header: l10n.tasteSectionOrigin,
          addLabel: l10n.tasteAddOrigin,
        ),
        _dimensionSection(
          context,
          provider,
          TasteDimension.process,
          header: l10n.tasteSectionProcess,
          addLabel: l10n.tasteAddProcess,
        ),
        _dimensionSection(
          context,
          provider,
          TasteDimension.roast,
          header: l10n.tasteSectionRoast,
          addLabel: l10n.tasteAddRoast,
        ),
        _dimensionSection(
          context,
          provider,
          TasteDimension.flavor,
          header: l10n.tasteSectionFlavor,
          addLabel: l10n.tasteAddFlavor,
          footer: l10n.tasteTimingNote,
        ),
      ],
    );
  }

  /// The intro line, then either the not-enough-history note or the summary
  /// lines worked out from the labelled history (no AI, just templates).
  Widget _summarySection(
    AppLocalizations l10n,
    Locale locale,
    TasteProfile? profile,
  ) {
    return SettingsSection(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tasteProfileIntro, style: AppTextStyles.body),
              if (profile == null)
                const SizedBox.shrink()
              else if (!profile.enoughHistory)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.tasteNotEnoughHistory,
                    style: AppTextStyles.body,
                  ),
                )
              else
                for (final line in _summaryLines(l10n, locale, profile))
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.sm,
                    ),
                    child: Text(line, style: AppTextStyles.body),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  /// One section per dimension: a row per labelled history value, then rows
  /// for adjustments the user added that are not in the history, then the
  /// add row. Rendered even without enough history — then it holds only
  /// added adjustments plus the add row.
  Widget _dimensionSection(
    BuildContext context,
    RecommendationProvider provider,
    TasteDimension dim, {
    required String header,
    required String addLabel,
    String? footer,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final profile = provider.tasteProfile;
    final rows = <Widget>[];
    final shownValues = <String>{};

    if (profile != null) {
      if (profile.enoughHistory) {
        for (final share in profile.sharesFor(dim)) {
          final label = _labelFor(l10n, dim, share.value, locale);
          if (label == null) continue;
          shownValues.add(share.value);
          rows.add(
            SettingsChoiceRow<_Choice>(
              identifier: 'tasteItem_${dim.wire}_${share.value}',
              title: label,
              subtitle: l10n.tasteShareOfCoffees(
                NumberFormat.percentPattern(
                  locale.toLanguageTag(),
                ).format(share.share),
              ),
              current: _Choice.of(profile.preferenceFor(dim, share.value)),
              sheetTitle: label,
              options: _preferenceOptions(l10n),
              onChanged: (choice) => unawaited(
                _savePreference(
                  context,
                  provider,
                  dim,
                  share.value,
                  choice.preference,
                  source: 'item',
                ),
              ),
            ),
          );
        }
      }
      // Adjustments for values the history does not show yet (or that the
      // user added beyond it). Unlabelled values are skipped entirely.
      for (final adjustment in profile.preferences) {
        if (adjustment.dimension != dim) continue;
        if (shownValues.contains(adjustment.value)) continue;
        final label = _labelFor(l10n, dim, adjustment.value, locale);
        if (label == null) continue;
        shownValues.add(adjustment.value);
        rows.add(
          SettingsChoiceRow<_Choice>(
            identifier: 'tasteItem_${dim.wire}_${adjustment.value}',
            title: label,
            subtitle: l10n.tasteNotInHistory,
            current: _Choice.of(adjustment.preference),
            sheetTitle: label,
            options: _preferenceOptions(l10n),
            onChanged: (choice) => unawaited(
              _savePreference(
                context,
                provider,
                dim,
                adjustment.value,
                choice.preference,
                source: 'item',
              ),
            ),
          ),
        );
      }
    }

    rows.add(
      SettingsActionRow(
        identifier: 'tasteAdd_${dim.wire}',
        title: addLabel,
        onTap: () => unawaited(_addValue(context, provider, dim, addLabel)),
      ),
    );

    return SettingsSection(header: header, footer: footer, children: rows);
  }

  /// The add flow: pick a vocabulary value not already shown, then pick how
  /// to treat it. Nothing is saved when either sheet is dismissed.
  Future<void> _addValue(
    BuildContext context,
    RecommendationProvider provider,
    TasteDimension dim,
    String addLabel,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final profile = provider.tasteProfile;
    final alreadyShown = <String>{
      if (profile != null) ...[
        for (final share in profile.sharesFor(dim)) share.value,
        for (final adjustment in profile.preferences)
          if (adjustment.dimension == dim) adjustment.value,
      ],
    };
    final options = <SettingsChoiceOption<String>>[];
    for (final value in _vocabularyFor(dim)) {
      if (alreadyShown.contains(dim.normalize(value))) continue;
      final label = _labelFor(l10n, dim, value, locale);
      if (label == null) continue;
      options.add(
        SettingsChoiceOption<String>(
          value: value,
          label: label,
          identifier: 'tasteSheet_${dim.wire}_$value',
        ),
      );
    }
    if (options.isEmpty) return;
    options.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    final value = await showSettingsChoiceSheet<String>(
      context: context,
      title: addLabel,
      options: options,
      current: '',
    );
    if (value == null || !context.mounted) return;
    var itemLabel = value;
    for (final option in options) {
      if (option.value == value) itemLabel = option.label;
    }

    final choice = await showSettingsChoiceSheet<_Choice>(
      context: context,
      title: l10n.tasteAddPreferenceTitle(itemLabel),
      options: _preferenceOptions(
        l10n,
      ).where((o) => o.value != _Choice.none).toList(),
      current: _Choice.none,
    );
    final preference = choice?.preference;
    if (preference == null || !context.mounted) return;
    await _savePreference(
      context,
      provider,
      dim,
      value,
      preference,
      source: 'add',
    );
  }

  /// Saves one adjustment (and reports it). The provider updates the display
  /// optimistically and rolls back itself, so the only failures left to
  /// handle here are the two the user must hear about. The messenger and
  /// l10n are captured before the await so nothing reads context afterwards.
  Future<void> _savePreference(
    BuildContext context,
    RecommendationProvider provider,
    TasteDimension dim,
    String value,
    TastePreference? preference, {
    required String source,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final result = await provider.setTastePreference(dim, value, preference);
    AnalyticsService.maybeInstance?.track(
      'taste_preference_changed',
      properties: {
        'dimension': dim.wire,
        'preference': preference?.wire ?? 'cleared',
        'source': source,
        'result': result.name,
      },
    );
    if (result == TastePreferenceWriteResult.limitReached) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tasteLimitReached)));
    } else if (result == TastePreferenceWriteResult.failed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tasteSaveFailed)));
    }
  }
}

/// No change (clears an adjustment), then More / Less / Never.
/// A preference choice with a real value for "No change": the shared choice
/// sheet returns null when it is dismissed, so null cannot also mean "clear".
enum _Choice {
  none(null),
  more(TastePreference.more),
  less(TastePreference.less),
  never(TastePreference.never);

  const _Choice(this.preference);

  final TastePreference? preference;

  static _Choice of(TastePreference? preference) =>
      values.firstWhere((c) => c.preference == preference);
}

List<SettingsChoiceOption<_Choice>> _preferenceOptions(AppLocalizations l10n) =>
    [
      SettingsChoiceOption<_Choice>(
        value: _Choice.none,
        label: l10n.tasteChoiceNoChange,
        identifier: 'tasteSheetPref_none',
      ),
      SettingsChoiceOption<_Choice>(
        value: _Choice.more,
        label: l10n.tasteChoiceMore,
        subtitle: l10n.tasteChoiceMoreSubtitle,
        identifier: 'tasteSheetPref_more',
      ),
      SettingsChoiceOption<_Choice>(
        value: _Choice.less,
        label: l10n.tasteChoiceLess,
        subtitle: l10n.tasteChoiceLessSubtitle,
        identifier: 'tasteSheetPref_less',
      ),
      SettingsChoiceOption<_Choice>(
        value: _Choice.never,
        label: l10n.tasteChoiceNever,
        subtitle: l10n.tasteChoiceNeverSubtitle,
        identifier: 'tasteSheetPref_never',
      ),
    ];

/// The vocabulary a dimension's add sheet offers.
List<String> _vocabularyFor(TasteDimension dim) => switch (dim) {
  TasteDimension.origin => _originVocabulary,
  TasteDimension.process => _processVocabulary,
  TasteDimension.roast => _roastVocabulary,
  TasteDimension.flavor => _flavorVocabulary,
};

/// The user-facing label of one vocabulary value, or null when the value is
/// unknown — such values are never shown as raw server identifiers.
String? _labelFor(
  AppLocalizations l10n,
  TasteDimension dim,
  String value,
  Locale locale,
) => switch (dim) {
  TasteDimension.origin => localizedCountryName(value, locale),
  TasteDimension.process => _processLabel(l10n, value),
  TasteDimension.roast => _roastLabel(l10n, value),
  TasteDimension.flavor => stockFlavorLabel(l10n, value),
};

/// Process labels; the shared stock labels do not know `other`.
String? _processLabel(AppLocalizations l10n, String value) =>
    value == 'other' ? l10n.tasteProcessOther : stockProcessLabel(l10n, value);

/// Roast labels (coffee-trade terms) — no shared helper exists yet.
String? _roastLabel(AppLocalizations l10n, String value) => switch (value) {
  'light' => l10n.tasteRoastLight,
  'medium_light' => l10n.tasteRoastMediumLight,
  'medium' => l10n.tasteRoastMedium,
  'medium_dark' => l10n.tasteRoastMediumDark,
  'dark' => l10n.tasteRoastDark,
  _ => null,
};

/// The summary lines, top values per dimension, 0–2 items each; a line with
/// no labelled value is omitted. Reads correctly with 0, 1 and 2 items.
List<String> _summaryLines(
  AppLocalizations l10n,
  Locale locale,
  TasteProfile profile,
) {
  final lines = <String>[];

  final origins = <String>[];
  for (final share in profile.sharesFor(TasteDimension.origin)) {
    final name = localizedCountryName(share.value, locale);
    if (name == null) continue;
    origins.add(name);
    if (origins.length == 2) break;
  }
  if (origins.isNotEmpty) {
    lines.add(
      l10n.tasteSummaryOrigins(
        origins.length == 1 ? 'single' : 'other',
        origins.length == 1
            ? origins.single
            : l10n.tasteListPair(origins[0], origins[1]),
      ),
    );
  }

  final processes = profile.sharesFor(TasteDimension.process);
  if (processes.isNotEmpty) {
    final label = _processLabel(l10n, processes.first.value);
    if (label != null) lines.add(l10n.tasteSummaryProcess(label));
  }

  final roasts = profile.sharesFor(TasteDimension.roast);
  if (roasts.isNotEmpty) {
    final label = _roastLabel(l10n, roasts.first.value);
    if (label != null) lines.add(l10n.tasteSummaryRoast(label));
  }

  final flavors = <String>[];
  for (final share in profile.sharesFor(TasteDimension.flavor)) {
    final name = stockFlavorLabel(l10n, share.value);
    if (name == null) continue;
    flavors.add(name);
    if (flavors.length == 2) break;
  }
  if (flavors.isNotEmpty) {
    lines.add(
      l10n.tasteSummaryFlavors(
        flavors.length == 1 ? 'single' : 'other',
        flavors.length == 1
            ? flavors.single
            : l10n.tasteListPair(flavors[0], flavors[1]),
      ),
    );
  }

  return lines;
}
