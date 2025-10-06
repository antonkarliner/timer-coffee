import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class BasicDetailsSection extends StatefulWidget {
  final String? variety;
  final String? region;
  final String? farmer;
  final String? farm;

  final Future<List<String>> varietyOptions;
  final Future<List<String>> regionOptions;
  final Future<List<String>> farmerOptions;
  final Future<List<String>> farmOptions;

  final ValueChanged<String?> onVarietyChanged;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onFarmerChanged;
  final ValueChanged<String?> onFarmChanged;

  const BasicDetailsSection({
    super.key,
    this.variety,
    this.region,
    this.farmer,
    this.farm,
    required this.varietyOptions,
    required this.regionOptions,
    required this.farmerOptions,
    required this.farmOptions,
    required this.onVarietyChanged,
    required this.onRegionChanged,
    required this.onFarmerChanged,
    required this.onFarmChanged,
  });

  @override
  State<BasicDetailsSection> createState() => _BasicDetailsSectionState();
}

class _BasicDetailsSectionState extends State<BasicDetailsSection> {
  late Future<List<String>> _varietyFuture;
  late Future<List<String>> _regionFuture;
  late Future<List<String>> _farmerFuture;
  late Future<List<String>> _farmFuture;

  @override
  void initState() {
    super.initState();
    _varietyFuture = widget.varietyOptions;
    _regionFuture = widget.regionOptions;
    _farmerFuture = widget.farmerOptions;
    _farmFuture = widget.farmOptions;
  }

  @override
  void didUpdateWidget(covariant BasicDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.varietyOptions != widget.varietyOptions) {
      _varietyFuture = widget.varietyOptions;
    }
    if (oldWidget.regionOptions != widget.regionOptions) {
      _regionFuture = widget.regionOptions;
    }
    if (oldWidget.farmerOptions != widget.farmerOptions) {
      _farmerFuture = widget.farmerOptions;
    }
    if (oldWidget.farmOptions != widget.farmOptions) {
      _farmFuture = widget.farmOptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Variety Field
        DropdownSearchField(
          label: loc.variety,
          hintText: loc.enterVariety,
          initialValue: widget.variety,
          semanticIdentifier: 'varietyInputField',
          onSearch: (query) async {
            final options = await _varietyFuture;
            if (query.isEmpty) return options;
            return options
                .where((option) =>
                    option.toLowerCase().contains(query.toLowerCase()))
                .toList();
          },
          onChanged: (value) {
            widget.onVarietyChanged(value.isEmpty ? null : value);
          },
        ),

        const SizedBox(height: AppSpacing.fieldGap),

        // Region Field
        DropdownSearchField(
          label: loc.region,
          hintText: loc.enterRegion,
          initialValue: widget.region,
          semanticIdentifier: 'regionInputField',
          onSearch: (query) async {
            final options = await _regionFuture;
            if (query.isEmpty) return options;
            return options
                .where((option) =>
                    option.toLowerCase().contains(query.toLowerCase()))
                .toList();
          },
          onChanged: (value) {
            widget.onRegionChanged(value.isEmpty ? null : value);
          },
        ),

        const SizedBox(height: AppSpacing.fieldGap),

        // Farmer Field
        DropdownSearchField(
          label: loc.farmer,
          hintText: loc.enterFarmer,
          initialValue: widget.farmer,
          semanticIdentifier: 'farmerInputField',
          onSearch: (query) async {
            final options = await _farmerFuture;
            if (query.isEmpty) return options;
            return options
                .where((option) =>
                    option.toLowerCase().contains(query.toLowerCase()))
                .toList();
          },
          onChanged: widget.onFarmerChanged,
        ),

        const SizedBox(height: AppSpacing.fieldGap),

        // Farm Field
        DropdownSearchField(
          label: loc.farm,
          hintText: loc.enterFarm,
          initialValue: widget.farm,
          semanticIdentifier: 'farmInputField',
          onSearch: (query) async {
            final options = await _farmFuture;
            if (query.isEmpty) return options;
            return options
                .where((option) =>
                    option.toLowerCase().contains(query.toLowerCase()))
                .toList();
          },
          onChanged: widget.onFarmChanged,
        ),
      ],
    );
  }
}
