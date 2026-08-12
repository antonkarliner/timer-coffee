import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/app_switch_list_tile.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';

enum _FilterSheetView { overview, roasters, beans }

class _BeanChoice {
  const _BeanChoice({
    required this.uuid,
    required this.name,
    required this.roaster,
  });

  final String uuid;
  final String name;
  final String roaster;
}

class DiaryFilterSelection {
  const DiaryFilterSelection({
    this.methodIds = const {},
    this.beanUuids = const {},
    this.origins = const {},
    this.tags = const {},
    this.ratingThreshold,
    this.hasNotes = false,
    this.hasExtractionYield = false,
  });

  final Set<String> methodIds;
  final Set<String> beanUuids;
  final Set<String> origins;
  final Set<String> tags;
  final double? ratingThreshold;
  final bool hasNotes;
  final bool hasExtractionYield;

  bool get isEmpty =>
      methodIds.isEmpty &&
      beanUuids.isEmpty &&
      origins.isEmpty &&
      tags.isEmpty &&
      ratingThreshold == null &&
      !hasNotes &&
      !hasExtractionYield;
}

Future<DiaryFilterSelection?> showDiaryFilterSheet(
  BuildContext context, {
  required List<DiaryEntry> entries,
  required DiaryFilterSelection initialSelection,
}) => showModalBottomSheet<DiaryFilterSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
  ),
  builder: (_) =>
      _DiaryFilterSheet(entries: entries, initialSelection: initialSelection),
);

class _DiaryFilterSheet extends StatefulWidget {
  const _DiaryFilterSheet({
    required this.entries,
    required this.initialSelection,
  });

  final List<DiaryEntry> entries;
  final DiaryFilterSelection initialSelection;

  @override
  State<_DiaryFilterSheet> createState() => _DiaryFilterSheetState();
}

class _DiaryFilterSheetState extends State<_DiaryFilterSheet> {
  final TextEditingController _beanSearchController = TextEditingController();

  late Set<String> _methodIds;
  late Set<String> _beanUuids;
  late Set<String> _origins;
  late Set<String> _tags;
  late double? _ratingThreshold;
  late bool _hasNotes;
  late bool _hasExtractionYield;
  late final List<_BeanChoice> _beans;
  _FilterSheetView _view = _FilterSheetView.overview;
  String? _selectedRoaster;

  @override
  void initState() {
    super.initState();
    _methodIds = {...widget.initialSelection.methodIds};
    _beanUuids = {...widget.initialSelection.beanUuids};
    _origins = {...widget.initialSelection.origins};
    _tags = {...widget.initialSelection.tags};
    _ratingThreshold = widget.initialSelection.ratingThreshold;
    _hasNotes = widget.initialSelection.hasNotes;
    _hasExtractionYield = widget.initialSelection.hasExtractionYield;
    _beans = _buildBeanChoices();
  }

  @override
  void dispose() {
    _beanSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final methods = <String, String>{
      for (final entry in widget.entries)
        entry.brewingMethodId: entry.methodName,
    }.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final origins =
        widget.entries
            .map((entry) => entry.origin?.trim())
            .whereType<String>()
            .where((origin) => origin.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final tags = _distinctTags(widget.entries);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          top: AppSpacing.base,
          right: AppSpacing.base,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(loc),
            const SizedBox(height: AppSpacing.base),
            Flexible(
              child: switch (_view) {
                _FilterSheetView.overview => _buildOverview(
                  loc,
                  methods,
                  origins,
                  tags,
                ),
                _FilterSheetView.roasters => _buildRoasterChooser(loc),
                _FilterSheetView.beans => _buildBeansForRoaster(loc),
              },
            ),
            if (_view == _FilterSheetView.overview) ...[
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: AppTextButton(
                      label: loc.clearFilters,
                      onPressed: _clear,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppElevatedButton(
                      label: loc.apply,
                      onPressed: _apply,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final title = switch (_view) {
      _FilterSheetView.overview => loc.diaryFilterSheetTitle,
      _FilterSheetView.roasters => loc.diaryChooseBeans,
      _FilterSheetView.beans => _selectedRoaster!,
    };

    return Row(
      children: [
        if (_view != _FilterSheetView.overview)
          IconButton(
            key: const ValueKey('diaryFilterBack'),
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back, size: AppIconSize.medium),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          )
        else
          const SizedBox(width: AppSpacing.xxl),
        Expanded(
          child: Text(
            title,
            key: ValueKey('diaryFilterTitle_${_view.name}'),
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildOverview(
    AppLocalizations loc,
    List<MapEntry<String, String>> methods,
    List<String> origins,
    List<String> tags,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('diaryFilterOverview'),
      child: Column(
        children: [
          _optionSection(
            title: loc.diaryMethods,
            icon: Coffeico.coffee_maker,
            options: methods,
            selected: _methodIds,
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            title: loc.diaryBeans,
            icon: Coffeico.bag_with_bean,
            isCollapsible: false,
            paddingChild: false,
            child: ListTile(
              key: const ValueKey('diaryBeanOverview'),
              title: Text(
                _beanUuids.isEmpty
                    ? loc.diaryAnyBean
                    : loc.diarySelectedBeanCount(_beanUuids.length),
                style: AppTextStyles.body,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: AppIconSize.medium,
              ),
              onTap: () => setState(() => _view = _FilterSheetView.roasters),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _optionSection(
            title: loc.diaryOrigins,
            icon: Icons.public,
            options: [for (final origin in origins) MapEntry(origin, origin)],
            selected: _origins,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _optionSection(
              title: loc.diaryTags,
              icon: Icons.sell_outlined,
              options: [for (final tag in tags) MapEntry(tag, '#$tag')],
              selected: _tags,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            title: loc.diaryRating,
            icon: Icons.star_outline,
            isCollapsible: false,
            child: Wrap(
              spacing: AppSpacing.xs,
              children: [
                _ratingChip(loc.all, null),
                _ratingChip(loc.diaryRatingThreePlus, 3),
                _ratingChip(loc.diaryRatingFourPlus, 4),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            title: loc.diaryMoreFilters,
            icon: Icons.checklist,
            isCollapsible: false,
            paddingChild: false,
            child: Column(
              children: [
                AppSwitchListTile(
                  title: loc.diaryHasNotes,
                  value: _hasNotes,
                  onChanged: (value) => setState(() => _hasNotes = value),
                ),
                AppSwitchListTile(
                  title: loc.diaryHasExtraction,
                  value: _hasExtractionYield,
                  onChanged: (value) =>
                      setState(() => _hasExtractionYield = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoasterChooser(AppLocalizations loc) {
    final query = _beanSearchController.text.trim().toLowerCase();
    final matchingBeans = query.isEmpty
        ? const <_BeanChoice>[]
        : _beans
              .where(
                (bean) =>
                    bean.name.toLowerCase().contains(query) ||
                    bean.roaster.toLowerCase().contains(query),
              )
              .toList();
    final groupedBeans = <String, List<_BeanChoice>>{};
    for (final bean in _beans) {
      groupedBeans.putIfAbsent(bean.roaster, () => []).add(bean);
    }
    final roasters = groupedBeans.keys.toList()..sort(_compareLabels);

    return Column(
      key: const ValueKey('diaryRoasterChooser'),
      children: [
        LabeledField(
          controller: _beanSearchController,
          label: loc.diaryBeanSearch,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.search,
          showClearButton: true,
          prefixIcon: const Icon(Icons.search, size: AppIconSize.medium),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: query.isNotEmpty
              ? matchingBeans.isEmpty
                    ? Center(
                        child: Text(
                          loc.noBeansMatchSearch,
                          style: AppTextStyles.body,
                        ),
                      )
                    : ListView(
                        children: [
                          for (final bean in matchingBeans) _beanCheckbox(bean),
                        ],
                      )
              : ListView(
                  children: [
                    SectionCard(
                      title: loc.roastersCatalogTitle,
                      icon: Icons.storefront_outlined,
                      isCollapsible: false,
                      paddingChild: false,
                      child: Column(
                        children: [
                          for (final roaster in roasters)
                            ListTile(
                              key: ValueKey('diaryRoaster_$roaster'),
                              title: Text(roaster, style: AppTextStyles.body),
                              subtitle: Text(
                                loc.diaryBeanCount(
                                  groupedBeans[roaster]!.length,
                                ),
                                style: AppTextStyles.caption,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: AppIconSize.medium,
                              ),
                              onTap: () => setState(() {
                                _selectedRoaster = roaster;
                                _view = _FilterSheetView.beans;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBeansForRoaster(AppLocalizations loc) {
    final roaster = _selectedRoaster!;
    final beans = _beans.where((bean) => bean.roaster == roaster);

    return ListView(
      key: const ValueKey('diaryBeansForRoaster'),
      children: [
        SectionCard(
          title: loc.diaryBeans,
          icon: Coffeico.bag_with_bean,
          isCollapsible: false,
          paddingChild: false,
          child: Column(
            children: [for (final bean in beans) _beanCheckbox(bean)],
          ),
        ),
      ],
    );
  }

  Widget _beanCheckbox(_BeanChoice bean) => CheckboxListTile(
    key: ValueKey('diaryBeanCheckbox_${bean.uuid}'),
    value: _beanUuids.contains(bean.uuid),
    title: Text(bean.name, style: AppTextStyles.body),
    subtitle: Text(bean.roaster, style: AppTextStyles.caption),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    onChanged: (selected) => setState(() {
      selected == true
          ? _beanUuids.add(bean.uuid)
          : _beanUuids.remove(bean.uuid);
    }),
  );

  List<_BeanChoice> _buildBeanChoices() {
    assert(() {
      for (final entry in widget.entries) {
        final uuid = entry.coffeeBeansUuid?.trim();
        if (uuid != null && uuid.isNotEmpty) {
          assert(
            entry.roaster?.trim().isNotEmpty == true,
            'Every linked diary bean must have a nonempty roaster.',
          );
        }
      }
      return true;
    }());

    final beansByUuid = <String, _BeanChoice>{};
    for (final entry in widget.entries) {
      final uuid = entry.coffeeBeansUuid?.trim();
      final name = entry.beanName?.trim();
      final roaster = entry.roaster?.trim();
      if (uuid == null ||
          uuid.isEmpty ||
          name == null ||
          name.isEmpty ||
          roaster == null ||
          roaster.isEmpty) {
        continue;
      }
      beansByUuid.putIfAbsent(
        uuid,
        () => _BeanChoice(uuid: uuid, name: name, roaster: roaster),
      );
    }

    final beans = beansByUuid.values.toList()
      ..sort((a, b) {
        final roasterOrder = _compareLabels(a.roaster, b.roaster);
        return roasterOrder == 0
            ? _compareLabels(a.name, b.name)
            : roasterOrder;
      });
    return beans;
  }

  int _compareLabels(String a, String b) {
    final normalizedOrder = a.toLowerCase().compareTo(b.toLowerCase());
    return normalizedOrder == 0 ? a.compareTo(b) : normalizedOrder;
  }

  void _goBack() => setState(() {
    if (_view == _FilterSheetView.beans) {
      _view = _FilterSheetView.roasters;
      return;
    }
    _beanSearchController.clear();
    _view = _FilterSheetView.overview;
  });

  Widget _optionSection({
    required String title,
    required IconData icon,
    required List<MapEntry<String, String>> options,
    required Set<String> selected,
  }) => SectionCard(
    title: title,
    icon: icon,
    isCollapsible: false,
    child: Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option.value, style: AppTextStyles.caption),
            selected: selected.contains(option.key),
            showCheckmark: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            onSelected: (value) => setState(() {
              value ? selected.add(option.key) : selected.remove(option.key);
            }),
          ),
      ],
    ),
  );

  Widget _ratingChip(String label, double? threshold) => FilterChip(
    label: Text(label, style: AppTextStyles.caption),
    selected: _ratingThreshold == threshold,
    showCheckmark: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
    onSelected: (_) => setState(() => _ratingThreshold = threshold),
  );

  void _clear() => setState(() {
    _methodIds.clear();
    _beanUuids.clear();
    _origins.clear();
    _tags.clear();
    _ratingThreshold = null;
    _hasNotes = false;
    _hasExtractionYield = false;
  });

  void _apply() => Navigator.of(context).pop(
    DiaryFilterSelection(
      methodIds: _methodIds,
      beanUuids: _beanUuids,
      origins: _origins,
      tags: _tags,
      ratingThreshold: _ratingThreshold,
      hasNotes: _hasNotes,
      hasExtractionYield: _hasExtractionYield,
    ),
  );
}

/// Distinct tags across [entries], deduplicated case-insensitively while
/// keeping the first-seen casing, sorted alphabetically case-insensitively.
List<String> _distinctTags(List<DiaryEntry> entries) {
  final seen = <String, String>{};
  for (final entry in entries) {
    for (final tag in entry.tagList) {
      seen.putIfAbsent(tag.toLowerCase(), () => tag);
    }
  }
  final tags = seen.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return tags;
}
