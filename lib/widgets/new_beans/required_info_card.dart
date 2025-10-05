import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import '../../theme/design_tokens.dart';

class RequiredInfoCard extends StatelessWidget {
  final String roaster;
  final String name;
  final String origin;

  final Future<List<String>> roasterOptions;
  final Future<List<String>> nameOptions;
  final Future<List<String>> originOptions;

  final ValueChanged<String> onRoasterChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onOriginChanged;

  const RequiredInfoCard({
    super.key,
    required this.roaster,
    required this.name,
    required this.origin,
    required this.roasterOptions,
    required this.nameOptions,
    required this.originOptions,
    required this.onRoasterChanged,
    required this.onNameChanged,
    required this.onOriginChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SectionCard(
      title: loc.requiredInformation,
      subtitle: loc.requiredInfoSubtitle,
      icon: Icons.info_outline,
      isCollapsible: false,
      semanticIdentifier: 'requiredInfoCard',
      child: Column(
        children: [
          // Roaster
          DropdownSearchField(
            label: loc.roaster,
            hintText: loc.enterRoaster,
            initialValue: roaster,
            required: true,
            semanticIdentifier: 'roasterInputField',
            onSearch: (query) async {
              // Get all options and filter based on query
              final allOptions = await roasterOptions;
              if (query.isEmpty) return allOptions;

              return allOptions
                  .where((option) =>
                      option.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            },
            onChanged: onRoasterChanged,
          ),
          const SizedBox(height: AppSpacing.fieldGap),

          // Name
          DropdownSearchField(
            label: loc.name,
            hintText: loc.enterName,
            initialValue: name,
            required: true,
            semanticIdentifier: 'nameInputField',
            onSearch: (query) async {
              // Get all options and filter based on query
              final allOptions = await nameOptions;
              if (query.isEmpty) return allOptions;

              return allOptions
                  .where((option) =>
                      option.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            },
            onChanged: onNameChanged,
          ),
          const SizedBox(height: AppSpacing.fieldGap),

          // Origin
          DropdownSearchField(
            label: loc.origin,
            hintText: loc.enterOrigin,
            initialValue: origin,
            required: true,
            semanticIdentifier: 'originInputField',
            onSearch: (query) async {
              // Get all options and filter based on query
              final allOptions = await originOptions;
              if (query.isEmpty) return allOptions;

              return allOptions
                  .where((option) =>
                      option.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            },
            onChanged: onOriginChanged,
          ),
        ],
      ),
    );
  }
}
