import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/autocomplete_input_field.dart';
import 'package:coffee_timer/widgets/new_beans/section_header.dart';
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
        SectionHeader(icon: Icons.coffee, title: loc.basicDetails),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'varietyInputField',
          label: loc.variety,
          child: AutocompleteInputField(
            label: loc.variety,
            hintText: loc.enterVariety,
            initialOptions: _varietyFuture,
            // Commit only on selection to avoid per-keystroke rebuild flicker.
            onSelected: (v) => widget.onVarietyChanged(v.isEmpty ? null : v),
            onChanged: (v) => widget.onVarietyChanged(
                v.isEmpty ? null : v), // Add onChanged callback
            initialValue: widget.variety,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'regionInputField',
          label: loc.region,
          child: AutocompleteInputField(
            label: loc.region,
            hintText: loc.enterRegion,
            initialOptions: _regionFuture,
            // Commit only on selection to avoid per-keystroke rebuild flicker.
            onSelected: (v) => widget.onRegionChanged(v.isEmpty ? null : v),
            onChanged: (v) => widget.onRegionChanged(
                v.isEmpty ? null : v), // Add onChanged callback
            initialValue: widget.region,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'farmerInputField',
          label: loc.farmer,
          child: AutocompleteInputField(
            label: loc.farmer,
            hintText: loc.enterFarmer,
            initialOptions: _farmerFuture,
            onSelected: widget.onFarmerChanged,
            onChanged: widget.onFarmerChanged, // Add onChanged callback
            initialValue: widget.farmer,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'farmInputField',
          label: loc.farm,
          child: AutocompleteInputField(
            label: loc.farm,
            hintText: loc.enterFarm,
            initialOptions: _farmFuture,
            onSelected: widget.onFarmChanged,
            onChanged: widget.onFarmChanged, // Add onChanged callback
            initialValue: widget.farm,
          ),
        ),
      ],
    );
  }
}
