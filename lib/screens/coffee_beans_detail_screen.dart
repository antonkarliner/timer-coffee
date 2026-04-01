import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

import '../providers/coffee_beans_provider.dart';
import '../controllers/coffee_beans_detail_controller.dart';
import '../widgets/coffee_bean_details/index.dart';
import '../widgets/confirm_delete_dialog.dart';

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
          title: Consumer<CoffeeBeansDetailController>(
            builder: (context, controller, child) {
              final title = controller.hasData
                  ? controller.bean!.name
                  : loc.coffeeBeansDetails;
              return Semantics(
                identifier: 'coffeeBeansDetailsAppBar',
                label: title,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Coffeico.bag_with_bean),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Consumer<CoffeeBeansDetailController>(
              builder: (context, controller, child) {
                return Semantics(
                  identifier: 'deleteCoffeeBeansButton',
                  label: loc.delete,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: controller.hasData
                        ? () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => ConfirmDeleteDialog(
                                title: loc.confirmDeleteTitle,
                                content: loc.confirmDeleteMessage,
                                confirmLabel: loc.delete,
                                cancelLabel: loc.cancel,
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              final success =
                                  await controller.deleteBean(context);
                              if (success && context.mounted) {
                                context.router.maybePop();
                              }
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
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

  /// Opens a full-screen viewer for [url] with pinch-to-zoom support.
  void _showFullScreenPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: AppIconSize.large,
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.base,
              right: AppSpacing.base,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
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

          // Cover photo (shown if user attached one) — polaroid card style
          if (bean.photoUrl != null) ...[
            const SizedBox(height: AppSpacing.base),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: GestureDetector(
                onTap: () => _showFullScreenPhoto(context, bean.photoUrl!),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: CachedNetworkImage(
                      imageUrl: bean.photoUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],

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

          // Inventory Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.inventory,
            bean: bean,
          ),
          const SizedBox(height: 16),

          // Flavor Profile Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.flavor,
            bean: bean,
          ),
          const SizedBox(height: 16),

          // Additional Notes Card (inline quick edit)
          QuickNotesCard(
            bean: bean,
            controller: controller,
          ),
        ],
      ),
    );
  }
}
