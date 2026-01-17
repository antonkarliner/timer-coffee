import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/coffee_beans_detail_controller.dart';

import '../../models/coffee_beans_model.dart';
import 'detail_section_header.dart';
import 'detail_item_row.dart';

/// Enumeration of available information card types
enum CoffeeBeansInfoCardType {
  /// Basic information card (origin, variety, farmer, farm)
  basicInfo,

  /// Geography & terroir card (region, elevation, harvest date)
  geography,

  /// Processing & roasting card (processing method, roast date, roast level, cupping score)
  processing,

  /// Inventory card (amount left, expiration date)
  inventory,

  /// Flavor profile card (tasting notes)
  flavor,

  /// Additional notes card (notes)
  notes,
}

/// A reusable information card widget for coffee bean detail screens.
///
/// This widget provides a unified card system for displaying different types
/// of coffee bean information. It supports multiple card types through the
/// [CoffeeBeansInfoCardType] enum and automatically handles conditional
/// rendering based on available data.
///
/// The component uses the established reusable components ([DetailSectionHeader]
/// and [DetailItemRow]) and follows the design patterns from the coffee beans
/// detail screen. It includes proper accessibility support and theme adaptation.
///
/// Example usage:
/// ```dart
/// CoffeeBeansInfoCard(
///   type: CoffeeBeansInfoCardType.basicInfo,
///   bean: coffeeBean,
/// )
/// ```
class CoffeeBeansInfoCard extends StatelessWidget {
  /// The type of information card to display
  final CoffeeBeansInfoCardType type;

  /// The coffee bean model containing the data to display
  final CoffeeBeansModel bean;

  /// Optional custom card elevation (defaults to theme default)
  final double? elevation;

  /// Optional custom card margin (defaults to EdgeInsets.zero)
  final EdgeInsetsGeometry? margin;

  /// Optional custom card padding (defaults to EdgeInsets.all(16.0))
  final EdgeInsetsGeometry? padding;

  /// Optional custom card shape (defaults to theme default)
  final ShapeBorder? shape;

  const CoffeeBeansInfoCard({
    super.key,
    required this.type,
    required this.bean,
    this.elevation,
    this.margin,
    this.padding,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Check if card should be rendered based on available data
    if (!_shouldRenderCard(loc)) {
      return const SizedBox.shrink();
    }

    return Semantics(
      identifier: 'coffeeBeansInfoCard_${type.name}_${bean.beansUuid}',
      label: _getCardSemanticLabel(loc),
      child: Card(
        elevation: elevation,
        margin: margin ?? EdgeInsets.zero,
        shape: shape,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, loc),
              const SizedBox(height: 16),
              ..._buildContent(context, loc),
            ],
          ),
        ),
      ),
    );
  }

  /// Determines if the card should be rendered based on available data
  bool _shouldRenderCard(AppLocalizations loc) {
    switch (type) {
      case CoffeeBeansInfoCardType.basicInfo:
        // Basic info always renders (at minimum shows origin)
        return true;
      case CoffeeBeansInfoCardType.geography:
        return (bean.region?.isNotEmpty == true) ||
            (bean.elevation != null) ||
            (bean.harvestDate != null);
      case CoffeeBeansInfoCardType.processing:
        // Processing always renders (at minimum shows roast date if available)
        return true;
      case CoffeeBeansInfoCardType.inventory:
        // Inventory renders only if package weight is available and valid
        return bean.validatedPackageWeightGrams != null;
      case CoffeeBeansInfoCardType.flavor:
        return bean.tastingNotes?.isNotEmpty == true;
      case CoffeeBeansInfoCardType.notes:
        return bean.notes?.isNotEmpty == true;
    }
  }

  /// Gets the semantic label for the card
  String _getCardSemanticLabel(AppLocalizations loc) {
    switch (type) {
      case CoffeeBeansInfoCardType.basicInfo:
        return loc.basicInformation;
      case CoffeeBeansInfoCardType.geography:
        return loc.geographyTerroir;
      case CoffeeBeansInfoCardType.processing:
        return loc.processing;
      case CoffeeBeansInfoCardType.inventory:
        return loc.inventory;
      case CoffeeBeansInfoCardType.flavor:
        return loc.flavorProfile;
      case CoffeeBeansInfoCardType.notes:
        return loc.additionalNotes;
    }
  }

  /// Builds the card header with icon and title
  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    IconData icon;
    String title;

    switch (type) {
      case CoffeeBeansInfoCardType.basicInfo:
        icon = Icons.info_outline;
        title = loc.basicInformation;
        break;
      case CoffeeBeansInfoCardType.geography:
        icon = Icons.terrain;
        title = loc.geographyTerroir;
        break;
      case CoffeeBeansInfoCardType.processing:
        icon = Icons.settings;
        title = loc.processing;
        break;
      case CoffeeBeansInfoCardType.inventory:
        icon = Icons.inventory;
        title = loc.inventory;
        break;
      case CoffeeBeansInfoCardType.flavor:
        icon = Icons.local_cafe;
        title = loc.flavorProfile;
        break;
      case CoffeeBeansInfoCardType.notes:
        icon = Icons.note;
        title = loc.additionalNotes;
        break;
    }

    return DetailSectionHeader(
      icon: icon,
      title: title,
    );
  }

  /// Builds the card content based on the card type
  List<Widget> _buildContent(BuildContext context, AppLocalizations loc) {
    switch (type) {
      case CoffeeBeansInfoCardType.basicInfo:
        return _buildBasicInfoContent(loc);
      case CoffeeBeansInfoCardType.geography:
        return _buildGeographyContent(loc);
      case CoffeeBeansInfoCardType.processing:
        return _buildProcessingContent(loc);
      case CoffeeBeansInfoCardType.inventory:
        return _buildInventoryContent(context, loc);
      case CoffeeBeansInfoCardType.flavor:
        return _buildFlavorContent(loc);
      case CoffeeBeansInfoCardType.notes:
        return _buildNotesContent(context, loc);
    }
  }

  /// Builds basic information content
  List<Widget> _buildBasicInfoContent(AppLocalizations loc) {
    final items = <Widget>[];

    items.add(DetailItemRow(
      label: loc.origin,
      value: bean.origin,
    ));

    if (bean.variety?.isNotEmpty == true) {
      items.add(DetailItemRow(
        label: loc.variety,
        value: bean.variety,
      ));
    }

    if (bean.farmer?.isNotEmpty == true) {
      items.add(DetailItemRow(
        label: loc.farmer,
        value: bean.farmer,
      ));
    }

    if (bean.farm?.isNotEmpty == true) {
      items.add(DetailItemRow(
        label: loc.farm,
        value: bean.farm,
      ));
    }

    return items;
  }

  /// Builds geography & terroir content
  List<Widget> _buildGeographyContent(AppLocalizations loc) {
    final items = <Widget>[];

    if (bean.region?.isNotEmpty == true) {
      items.add(DetailItemRow(
        label: loc.region,
        value: bean.region,
      ));
    }

    if (bean.elevation != null) {
      items.add(DetailItemRow(
        label: loc.elevation,
        value: '${bean.elevation}m',
      ));
    }

    if (bean.harvestDate != null) {
      items.add(DetailItemRow(
        label: loc.harvestDate,
        value: DateFormat.yMMMd().format(bean.harvestDate!),
      ));
    }

    return items;
  }

  /// Builds processing & roasting content
  List<Widget> _buildProcessingContent(AppLocalizations loc) {
    final items = <Widget>[];

    if (bean.processingMethod?.isNotEmpty == true) {
      items.add(DetailItemRow(
        label: loc.processingMethod,
        value: bean.processingMethod,
      ));
    }

    if (bean.roastDate != null) {
      items.add(DetailItemRow(
        label: loc.roastDate,
        value: DateFormat.yMMMd().format(bean.roastDate!),
      ));
    }

    if (bean.roastLevel?.isNotEmpty == true) {
      items.add(DetailItemRow(
        label: loc.roastLevel,
        value: bean.roastLevel,
      ));
    }

    if (bean.cuppingScore != null) {
      items.add(DetailItemRow(
        label: loc.cuppingScore,
        value: bean.cuppingScore!.toStringAsFixed(1),
      ));
    }

    return items;
  }

  /// Builds inventory content
  List<Widget> _buildInventoryContent(
      BuildContext context, AppLocalizations loc) {
    final items = <Widget>[];

    if (bean.validatedPackageWeightGrams != null) {
      items.add(DetailItemRow(
        label: loc.amountLeft,
        value: '${bean.validatedPackageWeightGrams!.toStringAsFixed(1)}g',
      ));

      items.add(const SizedBox(height: 8));

      items.add(AppTextButton(
        label: loc.setToZeroButton,
        onPressed: () {
          _showSetToZeroConfirmationDialog(context, loc);
        },
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        height: 36,
      ));
    }

    return items;
  }

  /// Shows the confirmation dialog for setting inventory to zero
  void _showSetToZeroConfirmationDialog(
      BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ConfirmDeleteDialog(
          title: loc.setToZeroDialogTitle,
          content: loc.setToZeroDialogBody,
          confirmLabel: loc.setToZeroDialogConfirm,
          cancelLabel: loc.setToZeroDialogCancel,
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        _handleSetToZero(context);
      }
    });
  }

  /// Handles the set to zero operation
  Future<void> _handleSetToZero(BuildContext context) async {
    // Get the CoffeeBeansDetailController from the context
    final controller = Provider.of<CoffeeBeansDetailController>(
      context,
      listen: false,
    );

    final success = await controller.setPackageWeightToZero(context);
    final loc = AppLocalizations.of(context)!;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.inventorySetToZeroSuccess)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.inventorySetToZeroFail)),
      );
    }
  }

  /// Builds flavor profile content
  List<Widget> _buildFlavorContent(AppLocalizations loc) {
    return [
      DetailItemRow(
        label: loc.tastingNotes,
        value: bean.tastingNotes,
      ),
    ];
  }

  /// Builds additional notes content
  List<Widget> _buildNotesContent(BuildContext context, AppLocalizations loc) {
    return [
      Semantics(
        identifier: 'additionalNotes_${bean.beansUuid}',
        label: '${loc.additionalNotes}: ${bean.notes}',
        child: Text(
          bean.notes!,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ];
  }
}

/// Extension methods for [CoffeeBeansInfoCardType] to provide additional functionality
extension CoffeeBeansInfoCardTypeExtension on CoffeeBeansInfoCardType {
  /// Returns a human-readable name for the card type
  String get displayName {
    switch (this) {
      case CoffeeBeansInfoCardType.basicInfo:
        return 'Basic Information'; // Note: This is in an extension method, can't access loc
      case CoffeeBeansInfoCardType.geography:
        return 'Geography & Terroir';
      case CoffeeBeansInfoCardType.processing:
        return 'Processing'; // Note: This is in an extension method, using existing "processing" key
      case CoffeeBeansInfoCardType.inventory:
        return 'Inventory'; // Note: This is in an extension method, can't access loc
      case CoffeeBeansInfoCardType.flavor:
        return 'Flavor Profile'; // Note: This is in an extension method, can't access loc
      case CoffeeBeansInfoCardType.notes:
        return 'Additional Notes'; // Note: This is in an extension method, can't access loc
    }
  }

  /// Returns the priority order for rendering cards (lower numbers render first)
  int get priority {
    switch (this) {
      case CoffeeBeansInfoCardType.basicInfo:
        return 1;
      case CoffeeBeansInfoCardType.geography:
        return 2;
      case CoffeeBeansInfoCardType.processing:
        return 3;
      case CoffeeBeansInfoCardType.inventory:
        return 4;
      case CoffeeBeansInfoCardType.flavor:
        return 5;
      case CoffeeBeansInfoCardType.notes:
        return 6;
    }
  }
}
