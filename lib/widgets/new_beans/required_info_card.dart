import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/autocomplete_input_field.dart';

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
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.requiredInformation,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Roaster
            Semantics(
              identifier: 'roasterInputField',
              label: loc.roaster,
              child: AutocompleteInputField(
                label: loc.roaster,
                hintText: loc.enterRoaster,
                initialOptions: roasterOptions,
                onSelected: onRoasterChanged,
                onChanged: onRoasterChanged, // Add onChanged callback
                initialValue: roaster,
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Semantics(
              identifier: 'nameInputField',
              label: loc.name,
              child: AutocompleteInputField(
                label: loc.name,
                hintText: loc.enterName,
                initialOptions: nameOptions,
                onSelected: onNameChanged,
                onChanged: onNameChanged, // Add onChanged callback
                initialValue: name,
              ),
            ),
            const SizedBox(height: 8),

            // Origin
            Semantics(
              identifier: 'originInputField',
              label: loc.origin,
              child: AutocompleteInputField(
                label: loc.origin,
                hintText: loc.enterOrigin,
                initialOptions: originOptions,
                onSelected: onOriginChanged,
                onChanged: onOriginChanged, // Add onChanged callback
                initialValue: origin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
