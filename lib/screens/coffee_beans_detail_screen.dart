import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import '../providers/database_provider.dart';
import '../models/coffee_beans_model.dart';
import 'package:intl/intl.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
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
  Widget _buildDetailsContent(
    BuildContext context,
    CoffeeBeansModel bean,
    String? originalUrl,
    String? mirrorUrl,
  ) {
    final loc = AppLocalizations.of(context)!;
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header Card
          _buildHeroHeader(
              context, bean, originalUrl, mirrorUrl, coffeeBeansProvider, loc),
          const SizedBox(height: 16),

          // Basic Info Card
          _buildBasicInfoCard(context, bean, loc),
          const SizedBox(height: 16),

          // Geography & Terroir Card
          _buildGeographyCard(context, bean, loc),
          const SizedBox(height: 16),

          // Processing & Roasting Card
          _buildProcessingCard(context, bean, loc),
          const SizedBox(height: 16),

          // Flavor Profile Card
          _buildFlavorCard(context, bean, loc),
          const SizedBox(height: 16),

          // Additional Notes Card
          if (bean.notes != null && bean.notes!.isNotEmpty)
            _buildNotesCard(context, bean, loc),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    CoffeeBeansModel bean,
    String? originalUrl,
    String? mirrorUrl,
    CoffeeBeansProvider coffeeBeansProvider,
    AppLocalizations loc,
  ) {
    // Neutral gray gradient that adapts to light/dark mode
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgStart = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final bgEnd = isLight ? Colors.grey.shade100 : Colors.grey.shade700;
    // Tint the fallback icon so it always contrasts
    final iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    // Text colors based on surface so they remain legible
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.85);
    final tertiaryTextColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6);

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo or placeholder
                  SizedBox(
                    height: 80,
                    width: 120,
                    child: (originalUrl != null || mirrorUrl != null)
                        ? RoasterLogo(
                            originalUrl: originalUrl,
                            mirrorUrl: mirrorUrl,
                            height: 80,
                            width: 120,
                            borderRadius: 12.0,
                            forceFit: BoxFit.contain,
                          )
                        : Icon(
                            Coffeico.bag_with_bean,
                            size: 60,
                            color: iconColor,
                          ),
                  ),
                  const SizedBox(width: 20),
                  // Name / roaster / origin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          bean.name,
                          maxLines: 2,
                          minFontSize: 12,
                          overflow: TextOverflow.visible,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bean.roaster,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bean.origin,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: tertiaryTextColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Favorite button
                  IconButton(
                    iconSize: 28,
                    icon: Icon(
                      bean.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: bean.isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : secondaryTextColor,
                    ),
                    onPressed: () async {
                      await coffeeBeansProvider.toggleFavoriteStatus(
                          bean.beansUuid!, !bean.isFavorite);
                      _loadBean();
                    },
                  ),
                ],
              ),
              // Quick stats (roast date & cupping score)
              if (bean.roastDate != null || bean.cuppingScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (bean.roastDate != null)
                        _buildQuickStat(
                          context,
                          Icons.calendar_today,
                          loc.roastDate,
                          DateFormat.yMMMd().format(bean.roastDate!),
                        ),
                      if (bean.cuppingScore != null)
                        _buildQuickStat(
                          context,
                          Icons.star,
                          loc.cuppingScore,
                          '${bean.cuppingScore}',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(
      BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(
      BuildContext context, CoffeeBeansModel bean, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailItem(context, loc.origin, bean.origin),
            if (bean.variety != null && bean.variety!.isNotEmpty)
              _buildDetailItem(context, loc.variety, bean.variety),
            if (bean.farmer != null && bean.farmer!.isNotEmpty)
              _buildDetailItem(context, loc.farmer, bean.farmer),
            if (bean.farm != null && bean.farm!.isNotEmpty)
              _buildDetailItem(context, loc.farm, bean.farm),
          ],
        ),
      ),
    );
  }

  Widget _buildGeographyCard(
      BuildContext context, CoffeeBeansModel bean, AppLocalizations loc) {
    if ((bean.region == null || bean.region!.isEmpty) &&
        (bean.elevation == null) &&
        (bean.harvestDate == null)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terrain,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.geographyTerroir,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bean.region != null && bean.region!.isNotEmpty)
              _buildDetailItem(context, loc.region, bean.region),
            if (bean.elevation != null)
              _buildDetailItem(context, loc.elevation, '${bean.elevation}m'),
            if (bean.harvestDate != null)
              _buildDetailItem(
                context,
                loc.harvestDate,
                DateFormat.yMMMd().format(bean.harvestDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard(
      BuildContext context, CoffeeBeansModel bean, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.processing,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bean.processingMethod != null &&
                bean.processingMethod!.isNotEmpty)
              _buildDetailItem(
                  context, loc.processingMethod, bean.processingMethod),
            if (bean.roastDate != null)
              _buildDetailItem(
                context,
                loc.roastDate,
                DateFormat.yMMMd().format(bean.roastDate!),
              ),
            if (bean.roastLevel != null && bean.roastLevel!.isNotEmpty)
              _buildDetailItem(context, loc.roastLevel, bean.roastLevel),
            if (bean.cuppingScore != null)
              _buildDetailItem(
                context,
                loc.cuppingScore,
                bean.cuppingScore!.toStringAsFixed(1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlavorCard(
      BuildContext context, CoffeeBeansModel bean, AppLocalizations loc) {
    if (bean.tastingNotes == null || bean.tastingNotes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_cafe,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.flavorProfile,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailItem(context, loc.tastingNotes, bean.tastingNotes),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(
      BuildContext context, CoffeeBeansModel bean, AppLocalizations loc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.additionalNotes,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              bean.notes!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItemWithProgress(
    BuildContext context,
    String label,
    double value,
    double maxValue,
  ) {
    final percentage = value / maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${value.toStringAsFixed(1)}/$maxValue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getScoreColor(percentage),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.8) return Colors.lightGreen;
    if (percentage >= 0.7) return Colors.orange;
    return Colors.red;
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
