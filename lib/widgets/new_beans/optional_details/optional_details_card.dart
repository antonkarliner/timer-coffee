import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/new_beans/optional_details/sections/basic_details_section.dart';
import 'package:coffee_timer/widgets/new_beans/optional_details/sections/processing_section.dart';
import 'package:coffee_timer/widgets/new_beans/optional_details/sections/flavor_profile_section.dart';
import 'package:coffee_timer/widgets/new_beans/optional_details/sections/quality_measurements_section.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class OptionalDetailsCard extends StatefulWidget {
  // Initial values
  final String? variety;
  final String? region;
  final String? farmer;
  final String? farm;
  final String? processingMethod;
  final String? roastLevel;
  final List<String> tastingNotes;
  final int? elevation;
  final double? cuppingScore;

  // Options sources
  final Future<List<String>> varietyOptions;
  final Future<List<String>> regionOptions;
  final Future<List<String>> farmerOptions;
  final Future<List<String>> farmOptions;
  final Future<List<String>> processingMethodOptions;
  final Future<List<String>> roastLevelOptions;
  final Future<List<String>> tastingNotesOptions;

  // Callbacks
  final ValueChanged<String?> onVarietyChanged;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onFarmerChanged;
  final ValueChanged<String?> onFarmChanged;
  final ValueChanged<String?> onProcessingMethodChanged;
  final ValueChanged<String?> onRoastLevelChanged;
  final ValueChanged<List<String>> onTastingNotesChanged;
  final ValueChanged<int?> onElevationChanged;
  final ValueChanged<double?> onCuppingScoreChanged;

  const OptionalDetailsCard({
    super.key,
    // initial values
    this.variety,
    this.region,
    this.farmer,
    this.farm,
    this.processingMethod,
    this.roastLevel,
    this.tastingNotes = const [],
    this.elevation,
    this.cuppingScore,
    // options
    required this.varietyOptions,
    required this.regionOptions,
    required this.farmerOptions,
    required this.farmOptions,
    required this.processingMethodOptions,
    required this.roastLevelOptions,
    required this.tastingNotesOptions,
    // callbacks
    required this.onVarietyChanged,
    required this.onRegionChanged,
    required this.onFarmerChanged,
    required this.onFarmChanged,
    required this.onProcessingMethodChanged,
    required this.onRoastLevelChanged,
    required this.onTastingNotesChanged,
    required this.onElevationChanged,
    required this.onCuppingScoreChanged,
  });

  @override
  State<OptionalDetailsCard> createState() => _OptionalDetailsCardState();
}

class _OptionalDetailsCardState extends State<OptionalDetailsCard> {
  String? _variety;
  String? _region;
  String? _farmer;
  String? _farm;
  String? _processingMethod;
  String? _roastLevel;
  List<String> _tastingNotes = [];
  int? _elevation;
  double? _cuppingScore;

  @override
  void initState() {
    super.initState();
    _variety = widget.variety;
    _region = widget.region;
    _farmer = widget.farmer;
    _farm = widget.farm;
    _processingMethod = widget.processingMethod;
    _roastLevel = widget.roastLevel;
    _tastingNotes = List.from(widget.tastingNotes);
    _elevation = widget.elevation;
    _cuppingScore = widget.cuppingScore;
  }

  @override
  void didUpdateWidget(covariant OptionalDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variety != widget.variety) {
      _variety = widget.variety;
    }
    if (oldWidget.region != widget.region) {
      _region = widget.region;
    }
    if (oldWidget.farmer != widget.farmer) {
      _farmer = widget.farmer;
    }
    if (oldWidget.farm != widget.farm) {
      _farm = widget.farm;
    }
    if (oldWidget.processingMethod != widget.processingMethod) {
      _processingMethod = widget.processingMethod;
    }
    if (oldWidget.roastLevel != widget.roastLevel) {
      _roastLevel = widget.roastLevel;
    }
    if (oldWidget.tastingNotes != widget.tastingNotes) {
      _tastingNotes = List.from(widget.tastingNotes);
    }
    if (oldWidget.elevation != widget.elevation) {
      _elevation = widget.elevation;
    }
    if (oldWidget.cuppingScore != widget.cuppingScore) {
      _cuppingScore = widget.cuppingScore;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.optional,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BasicDetailsSection(
                  variety: _variety,
                  region: _region,
                  farmer: _farmer,
                  farm: _farm,
                  varietyOptions: widget.varietyOptions,
                  regionOptions: widget.regionOptions,
                  farmerOptions: widget.farmerOptions,
                  farmOptions: widget.farmOptions,
                  onVarietyChanged: (v) {
                    setState(() {
                      _variety = v;
                    });
                    widget.onVarietyChanged(v);
                  },
                  onRegionChanged: (v) {
                    setState(() {
                      _region = v;
                    });
                    widget.onRegionChanged(v);
                  },
                  onFarmerChanged: (v) {
                    setState(() {
                      _farmer = v;
                    });
                    widget.onFarmerChanged(v);
                  },
                  onFarmChanged: (v) {
                    setState(() {
                      _farm = v;
                    });
                    widget.onFarmChanged(v);
                  },
                ),
                const SizedBox(height: 16),
                ProcessingSection(
                  processingMethod: _processingMethod,
                  roastLevel: _roastLevel,
                  processingMethodOptions: widget.processingMethodOptions,
                  roastLevelOptions: widget.roastLevelOptions,
                  onProcessingMethodChanged: (v) {
                    setState(() {
                      _processingMethod = v;
                    });
                    widget.onProcessingMethodChanged(v);
                  },
                  onRoastLevelChanged: (v) {
                    setState(() {
                      _roastLevel = v;
                    });
                    widget.onRoastLevelChanged(v);
                  },
                ),
                const SizedBox(height: 16),
                FlavorProfileSection(
                  tastingNotes: _tastingNotes,
                  tastingNotesOptions: widget.tastingNotesOptions,
                  onTastingNotesChanged: (tags) {
                    setState(() {
                      _tastingNotes = tags;
                    });
                    widget.onTastingNotesChanged(tags);
                  },
                ),
                const SizedBox(height: 16),
                QualityMeasurementsSection(
                  elevation: _elevation,
                  cuppingScore: _cuppingScore,
                  onElevationChanged: (val) {
                    setState(() {
                      _elevation = val;
                    });
                    widget.onElevationChanged(val);
                  },
                  onCuppingScoreChanged: (val) {
                    setState(() {
                      _cuppingScore = val;
                    });
                    widget.onCuppingScoreChanged(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
