import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/database_provider.dart';
import '../models/coffee_beans_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/roaster_logo.dart'; // Ensure this path is correct

@RoutePage()
class CoffeeBeansDetailScreen extends StatefulWidget {
  final String uuid;

  const CoffeeBeansDetailScreen({Key? key, required this.uuid})
      : super(key: key);

  @override
  State<CoffeeBeansDetailScreen> createState() =>
      _CoffeeBeansDetailScreenState();
}

class _CoffeeBeansDetailScreenState extends State<CoffeeBeansDetailScreen> {
  Future<CoffeeBeansModel?>? futureBean;

  @override
  void initState() {
    super.initState();
    _loadBean();
  }

  /// Fetches the coffee bean data and updates the state.
  void _loadBean() {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    setState(() {
      futureBean = coffeeBeansProvider.fetchCoffeeBeansByUuid(widget.uuid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'coffeeBeansDetailsAppBar',
          label: loc.coffeeBeansDetails,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Coffeico.bag_with_bean),
              const SizedBox(width: 8),
              Text(loc.coffeeBeansDetails),
            ],
          ),
        ),
        actions: [
          Semantics(
            identifier: 'editCoffeeBeansButton',
            label: loc.edit,
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.router.push(NewBeansRoute(uuid: widget.uuid));
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<CoffeeBeansModel?>(
        future: futureBean,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Semantics(
                identifier: 'coffeeBeansDetailsError',
                label: loc.error(snapshot.error.toString()),
                child: Text(loc.error(snapshot.error.toString())),
              ),
            );
          } else if (snapshot.hasData) {
            final bean = snapshot.data;
            if (bean == null) {
              return Center(
                child: Semantics(
                  identifier: 'coffeeBeansNotFound',
                  label: loc.coffeeBeansNotFound,
                  child: Text(loc.coffeeBeansNotFound),
                ),
              );
            }

            // Fetch roaster logo URLs
            return FutureBuilder<Map<String, String?>>(
              future: databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
              builder: (context, logoSnapshot) {
                if (logoSnapshot.connectionState == ConnectionState.waiting) {
                  // Removed CircularProgressIndicator
                  return _buildDetailsContent(context, bean, null, null);
                } else if (logoSnapshot.hasError) {
                  // Handle errors by proceeding without logos
                  return _buildDetailsContent(context, bean, null, null);
                } else if (logoSnapshot.hasData) {
                  final logoUrls = logoSnapshot.data!;
                  return _buildDetailsContent(
                      context, bean, logoUrls['original'], logoUrls['mirror']);
                } else {
                  // No data found
                  return _buildDetailsContent(context, bean, null, null);
                }
              },
            );
          } else {
            return Center(
              child: Semantics(
                identifier: 'coffeeBeansDetailsEmpty',
                label: loc.noCoffeeBeans,
                child: Text(loc.noCoffeeBeans),
              ),
            );
          }
        },
      ),
    );
  }

  /// Builds the main content of the detail screen.
  Widget _buildDetailsContent(BuildContext context, CoffeeBeansModel bean,
      String? originalUrl, String? mirrorUrl) {
    final loc = AppLocalizations.of(context)!;
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            children: [
              // Display Roaster Logo
              RoasterLogo(
                originalUrl: originalUrl,
                mirrorUrl: mirrorUrl,
                height: 60.0,
                borderRadius: 8.0,
              ),
              const SizedBox(width: 16),
              // Bean Name and Roaster
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      identifier: 'beanName_${bean.beansUuid}',
                      label: '${loc.name}: ${bean.name}',
                      child: Text(
                        bean.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'beanRoaster_${bean.beansUuid}',
                      label: '${loc.roaster}: ${bean.roaster}',
                      child: Text(
                        '${loc.roaster}: ${bean.roaster}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300] // Light color for dark mode
                              : Colors.grey[700], // Dark color for light mode
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Favorite Button
              Semantics(
                identifier: 'favoriteButton_${bean.beansUuid}',
                label: bean.isFavorite ? loc.removeFavorite : loc.addFavorite,
                child: IconButton(
                  iconSize: 30,
                  icon: Icon(
                    bean.isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: () {
                    // Toggle favorite status
                    coffeeBeansProvider.toggleFavoriteStatus(
                        bean.beansUuid!, !bean.isFavorite);
                    // Refetch the bean data to update the UI
                    _loadBean();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(context, loc.origin, bean.origin),
          const SizedBox(height: 16),
          _buildSectionTitle(context, loc.geographyTerroir),
          _buildDetailItem(context, loc.variety, bean.variety),
          _buildDetailItem(context, loc.region, bean.region),
          _buildDetailItem(context, loc.elevation, bean.elevation?.toString()),
          _buildDetailItem(
            context,
            loc.harvestDate,
            bean.harvestDate != null
                ? DateFormat.yMMMd().format(bean.harvestDate!)
                : null,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(context, loc.processing),
          _buildDetailItem(
              context, loc.processingMethod, bean.processingMethod),
          _buildDetailItem(
            context,
            loc.roastDate,
            bean.roastDate != null
                ? DateFormat.yMMMd().format(bean.roastDate!)
                : null,
          ),
          _buildDetailItem(context, loc.roastLevel, bean.roastLevel),
          _buildDetailItem(
              context, loc.cuppingScore, bean.cuppingScore?.toString()),
          const SizedBox(height: 16),
          _buildSectionTitle(context, loc.flavorProfile),
          _buildDetailItem(context, loc.tastingNotes, bean.tastingNotes),
          const SizedBox(height: 16),
          _buildSectionTitle(context, loc.additionalNotes),
          _buildDetailItem(context, loc.notes, bean.notes),
        ],
      ),
    );
  }

  /// Builds section titles with consistent styling.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Semantics(
      identifier: 'sectionTitle_$title',
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  /// Builds individual detail items with label and value.
  Widget _buildDetailItem(BuildContext context, String label, String? value) {
    return Semantics(
      identifier: 'detailItem_$label',
      label: '$label: ${value ?? '-'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value ?? '-',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
