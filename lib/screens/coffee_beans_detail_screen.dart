import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../providers/coffee_beans_provider.dart';
import '../controllers/coffee_beans_detail_controller.dart';
import '../widgets/coffee_bean_details/index.dart';

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
  late final CoffeeBeansDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CoffeeBeansDetailController();
    _controller.initialize(context, widget.uuid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
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
            Consumer<CoffeeBeansDetailController>(
              builder: (context, controller, child) {
                return Semantics(
                  identifier: 'editCoffeeBeansButton',
                  label: loc.edit,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: controller.hasData
                        ? () => controller.navigateToEdit(context)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<CoffeeBeansDetailController>(
          builder: (context, controller, child) {
            if (controller.hasError) {
              return Center(
                child: Semantics(
                  identifier: 'coffeeBeansDetailsError',
                  label: loc.error(controller.errorMessage!),
                  child: Text(loc.error(controller.errorMessage!)),
                ),
              );
            }

            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!controller.hasData) {
              return Center(
                child: Semantics(
                  identifier: 'coffeeBeansNotFound',
                  label: loc.coffeeBeansNotFound,
                  child: Text(loc.coffeeBeansNotFound),
                ),
              );
            }

            return _buildDetailsContent(context, controller);
          },
        ),
      ),
    );
  }

  /// Builds the main content of the detail screen using modularized components.
  Widget _buildDetailsContent(
    BuildContext context,
    CoffeeBeansDetailController controller,
  ) {
    final bean = controller.bean!;
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Header Component
          CoffeeBeansHeroHeader(
            bean: bean,
            originalUrl: controller.originalLogoUrl,
            mirrorUrl: controller.mirrorLogoUrl,
            coffeeBeansProvider: coffeeBeansProvider,
            onFavoriteToggle: () => controller.refreshData(context),
          ),
          const SizedBox(height: 16),

          // Basic Info Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.basicInfo,
            bean: bean,
          ),
          const SizedBox(height: 16),

          // Geography & Terroir Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.geography,
            bean: bean,
          ),
          const SizedBox(height: 16),

          // Processing & Roasting Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.processing,
            bean: bean,
          ),
          const SizedBox(height: 16),

          // Flavor Profile Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.flavor,
            bean: bean,
          ),
          const SizedBox(height: 16),

          // Additional Notes Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.notes,
            bean: bean,
          ),
        ],
      ),
    );
  }
}
