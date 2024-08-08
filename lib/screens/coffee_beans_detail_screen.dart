import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class CoffeeBeansDetailScreen extends StatelessWidget {
  final String uuid;

  const CoffeeBeansDetailScreen({Key? key, required this.uuid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);
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
              icon: Icon(Icons.edit),
              onPressed: () {
                context.router.push(NewBeansRoute(uuid: uuid));
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<CoffeeBeansModel?>(
        future: coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Semantics(
                identifier: 'coffeeBeansDetailsLoading',
                label: loc.loading,
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
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

            return Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Semantics(
                          identifier: 'beanName_${bean.beansUuid}',
                          label: '${loc.name}: ${bean.name}',
                          child: Text(
                            bean.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        identifier: 'favoriteButton_${bean.beansUuid}',
                        label: bean.isFavorite
                            ? loc.removeFavorite
                            : loc.addFavorite,
                        child: IconButton(
                          iconSize: 30,
                          icon: Icon(
                            bean.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          onPressed: () {
                            coffeeBeansProvider.toggleFavoriteStatus(
                                bean.beansUuid!, !bean.isFavorite);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildDetailItem(context, loc.roaster, bean.roaster),
                  _buildDetailItem(context, loc.origin, bean.origin),
                  SizedBox(height: 16),
                  _buildSectionTitle(context, loc.geographyTerroir),
                  _buildDetailItem(context, loc.variety, bean.variety),
                  _buildDetailItem(context, loc.region, bean.region),
                  _buildDetailItem(
                      context, loc.elevation, bean.elevation?.toString()),
                  _buildDetailItem(
                    context,
                    loc.harvestDate,
                    bean.harvestDate != null
                        ? DateFormat.yMMMd().format(bean.harvestDate!)
                        : null,
                  ),
                  SizedBox(height: 16),
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
                  SizedBox(height: 16),
                  _buildSectionTitle(context, loc.flavorProfile),
                  _buildDetailItem(
                      context, loc.tastingNotes, bean.tastingNotes),
                  SizedBox(height: 16),
                  _buildSectionTitle(context, loc.additionalNotes),
                  _buildDetailItem(context, loc.notes, bean.notes),
                ],
              ),
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
