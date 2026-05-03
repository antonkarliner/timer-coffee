// lib/widgets/roasters/country_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:coffee_timer/providers/roasters_provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

Future<void> showCountryFilterSheet(
  BuildContext context,
  RoastersProvider provider,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
    ),
    builder: (context) => _CountryFilterSheet(provider: provider),
  );
}

class _CountryFilterSheet extends StatelessWidget {
  final RoastersProvider provider;

  const _CountryFilterSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentFilter = provider.countryFilter;
    final countries = provider.countries;
    final counts = provider.countryCounts;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.xs,
                AppSpacing.base,
                AppSpacing.sm,
              ),
              child: Text(
                loc.filterByCountry,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: countries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All countries" row
                    return ListTile(
                      leading: const Icon(Icons.public),
                      title: Text(loc.allCountries),
                      trailing: currentFilter == null
                          ? Icon(
                              Icons.check,
                              color:
                                  Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        provider.setCountryFilter(null);
                        Navigator.of(context).pop();
                      },
                    );
                  }
                  final country = countries[index - 1];
                  final count = counts[country] ?? 0;
                  return ListTile(
                    title: Text(country),
                    subtitle: Text(loc.roasterCountryCount(count)),
                    trailing: currentFilter == country
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      provider.setCountryFilter(country);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
