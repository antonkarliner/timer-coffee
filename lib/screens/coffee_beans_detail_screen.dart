import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

import '../database/database.dart';
import '../models/bean_review_model.dart';
import '../models/coffee_beans_model.dart';
import '../models/user_stat_model.dart';
import '../providers/bean_review_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/roaster_profile_provider.dart';
import '../providers/user_stat_provider.dart';
import '../controllers/coffee_beans_detail_controller.dart';
import '../widgets/base_buttons.dart';
import '../widgets/coffee_bean_details/index.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/roaster_profile/review_body.dart';
import '../widgets/roaster_profile/review_form.dart';
import '../widgets/roaster_contribution/contribution_prompt_card.dart';
import '../app_router.gr.dart';
import '../utils/roaster_background_color.dart';

@RoutePage()
class CoffeeBeansDetailScreen extends StatefulWidget {
  final String uuid;
  final String? focusSection;

  const CoffeeBeansDetailScreen({
    super.key,
    @PathParam('beanId') required this.uuid,
    @QueryParam('focus') this.focusSection,
  });

  @override
  State<CoffeeBeansDetailScreen> createState() =>
      _CoffeeBeansDetailScreenState();
}

class _CoffeeBeansDetailScreenState extends State<CoffeeBeansDetailScreen>
    with SingleTickerProviderStateMixin {
  late final CoffeeBeansDetailController _controller;
  late Future<List<UserStatsModel>> _beanStatsFuture;

  BeanReviewModel? _userReview;
  String? _roasterProfileId;
  String? _resolvedBrewMethodName;
  bool _roasterProfileLookupCompleted = false;
  bool _reviewLoading = false;
  bool _reviewDataLoaded = false;
  bool _deferredLoadsUnlocked = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewSectionKey = GlobalKey();
  late final AnimationController _highlightController;
  bool _focusHandled = false;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimationListener;

  // Held so we can add/remove the listener safely across rebuilds.
  BeanReviewProvider? _reviewProvider;

  @override
  void initState() {
    super.initState();
    _controller = CoffeeBeansDetailController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize(context, widget.uuid);
    _refreshBeanStats();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null ||
          animation.status == AnimationStatus.completed) {
        _deferredLoadsUnlocked = true;
        _controller.loadAncillaryData(context);
        _maybeStartReviewLoad();
        return;
      }
      _routeAnimation = animation;
      _routeAnimationListener = (status) {
        if (status != AnimationStatus.completed) return;
        _detachRouteAnimationListener();
        if (!mounted) return;
        _deferredLoadsUnlocked = true;
        _controller.loadAncillaryData(context);
        _maybeStartReviewLoad();
      };
      animation.addStatusListener(_routeAnimationListener!);
    });
  }

  void _detachRouteAnimationListener() {
    if (_routeAnimation != null && _routeAnimationListener != null) {
      _routeAnimation!.removeStatusListener(_routeAnimationListener!);
    }
    _routeAnimation = null;
    _routeAnimationListener = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<BeanReviewProvider>(context, listen: false);
    if (_reviewProvider != provider) {
      _reviewProvider?.removeListener(_onReviewProviderChanged);
      _reviewProvider = provider;
      _reviewProvider!.addListener(_onReviewProviderChanged);
    }
  }

  /// Called whenever BeanReviewProvider notifies (submit / delete elsewhere).
  /// Re-fetches if our bean's cache entry was cleared.
  void _onReviewProviderChanged() {
    if (_reviewDataLoaded &&
        !_reviewLoading &&
        !(_reviewProvider?.isUserBeanReviewCached(widget.uuid) ?? true)) {
      _reviewDataLoaded = false;
      _loadReviewData();
    }
  }

  void _onControllerChanged() {
    _maybeStartReviewLoad();
  }

  void _refreshBeanStats() {
    _beanStatsFuture = context.read<UserStatProvider>().fetchStatsByBeanUuid(
      widget.uuid,
    );
  }

  Future<void> _openBeanJourney(String beanUuid) async {
    await context.router.push(BeanJourneyRoute(beanUuid: beanUuid));
    if (!mounted) return;
    setState(_refreshBeanStats);
  }

  void _maybeStartReviewLoad() {
    if (_deferredLoadsUnlocked && _controller.hasData && !_reviewDataLoaded) {
      _reviewDataLoaded = true;
      _loadReviewData();
    }
  }

  Future<void> _loadReviewData() async {
    if (!mounted) return;
    setState(() => _reviewLoading = true);
    final bean = _controller.bean!;
    final reviewProvider = Provider.of<BeanReviewProvider>(
      context,
      listen: false,
    );
    final roasterProvider = Provider.of<RoasterProfileProvider>(
      context,
      listen: false,
    );
    final results = await Future.wait([
      reviewProvider.fetchUserReviewByBeanUuid(widget.uuid),
      roasterProvider.fetchRoasterProfileIdByName(bean.roaster),
    ]);
    if (!mounted) return;
    final review = results[0] as BeanReviewModel?;

    // Resolve brewing method display name from local DB when the review was
    // fetched via direct table query (no RPC JOIN → brewingMethodName is null).
    String? resolvedBrewMethodName;
    if (review != null &&
        review.brewingMethodId != null &&
        review.brewingMethodName == null) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      resolvedBrewMethodName = await db.brewingMethodsDao
          .getBrewingMethodNameById(review.brewingMethodId!);
    }

    if (!mounted) return;
    setState(() {
      _userReview = review;
      _roasterProfileId = results[1] as String?;
      _roasterProfileLookupCompleted = true;
      _resolvedBrewMethodName = resolvedBrewMethodName;
      _reviewLoading = false;
    });
    _maybeFocusReviewSection();
  }

  void _maybeFocusReviewSection() {
    if (_focusHandled) return;
    if (widget.focusSection != 'review') return;
    if (_userReview != null) return;
    _focusHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx = _reviewSectionKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          alignment: 0.1,
          curve: Curves.easeInOut,
        );
      }
      if (!mounted) return;
      await _highlightController.forward(from: 0);
      if (!mounted) return;
      await _highlightController.reverse();
    });
  }

  @override
  void dispose() {
    _detachRouteAnimationListener();
    _reviewProvider?.removeListener(_onReviewProviderChanged);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<CoffeeBeansDetailController>(
        builder: (context, ctrl, _) {
          final colorResult = ctrl.roasterColorResult;
          return Scaffold(
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
                          child: Text(title, overflow: TextOverflow.ellipsis),
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
                                  final success = await controller.deleteBean(
                                    context,
                                  );
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
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: double.infinity,
              height: double.infinity,
              // With the warm-cache fast path the color is applied in the
              // first frame, so this animation only plays on true cache
              // misses (deferred load resolving after content is visible).
              color: colorResult != null
                  ? roasterBackgroundColor(
                      result: colorResult,
                      brightness: Theme.of(context).brightness,
                    )
                  : Colors.transparent,
              child: Consumer<CoffeeBeansDetailController>(
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
                    return const Center(child: CircularProgressIndicator());
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
        },
      ),
    );
  }

  /// Navigates to the roaster profile page if an active profile exists.
  Future<void> _navigateToRoasterProfile(
    BuildContext context,
    String roasterName,
  ) async {
    final provider = Provider.of<RoasterProfileProvider>(
      context,
      listen: false,
    );
    final slug = await provider.fetchRoasterSlugByName(roasterName);
    if (!context.mounted) return;
    if (slug != null) {
      context.router.push(RoasterProfileRoute(slug: slug));
    }
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
                  imageUrl: SupabaseEndpointResolver.localizeStorageUrl(url),
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Icon(
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

  /// Shows the "Your Review" card, or an "Add Review" button when no review
  /// exists yet. Hidden entirely when the roaster has no directory profile.
  Widget _buildYourReviewSection(BuildContext context, CoffeeBeansModel bean) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Loading state
    if (_reviewLoading) {
      return Card(
        key: _reviewSectionKey,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              Text(loc.yourReview, style: AppTextStyles.sectionHeader),
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: AppIconSize.medium,
                height: AppIconSize.medium,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      key: _reviewSectionKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.yourReview, style: AppTextStyles.sectionHeader),

            if (_userReview != null) ...[
              const SizedBox(height: AppSpacing.base),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              ReviewBody(
                review: _userReview!,
                brewMethodNameOverride: _resolvedBrewMethodName,
              ),

              const SizedBox(height: AppSpacing.sm),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: AppSpacing.xs,
                overflowSpacing: AppSpacing.xs,
                children: [
                  if (_roasterProfileId != null)
                    AppTextButton(
                      label: loc.editReview,
                      isFullWidth: false,
                      onPressed: () async {
                        final updated = await showReviewForm(
                          context,
                          roasterProfileId: _roasterProfileId,
                          roasterName: bean.roaster,
                          existingReview: _userReview,
                          preselectedBean: bean,
                          sourceScreen: 'coffee_beans_detail',
                        );
                        if (updated && mounted) {
                          _reviewDataLoaded = false;
                          await _loadReviewData();
                        }
                      },
                    ),
                  AppTextButton(
                    label: loc.deleteReview,
                    isFullWidth: false,
                    foregroundColor: colorScheme.error,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => ConfirmDeleteDialog(
                          title: loc.confirmDeleteReviewTitle,
                          content: loc.confirmDeleteReviewMessage,
                          confirmLabel: loc.deleteReview,
                          cancelLabel: loc.cancel,
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final ok =
                          await Provider.of<BeanReviewProvider>(
                            context,
                            listen: false,
                          ).deleteReview(
                            reviewId: _userReview!.id,
                            roasterProfileId: _userReview!.roasterProfileId,
                            coffeeBeansUuid: widget.uuid,
                          );
                      if (ok && mounted) {
                        setState(() {
                          _userReview = null;
                          _resolvedBrewMethodName = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.base),
              AnimatedBuilder(
                animation: _highlightController,
                builder: (context, child) {
                  final v = _highlightController.value;
                  final pulse = v <= 0.5 ? v * 2 : (1 - v) * 2;
                  final eased = Curves.easeInOut.transform(pulse);
                  return Transform.scale(
                    scale: 1.0 + 0.06 * eased,
                    child: child,
                  );
                },
                child: AppElevatedButton(
                  label: loc.addReview,
                  onPressed: () async {
                    final added = await showReviewForm(
                      context,
                      roasterProfileId: _roasterProfileId,
                      roasterName: bean.roaster,
                      preselectedBean: bean,
                      sourceScreen: 'coffee_beans_detail',
                    );
                    if (added && mounted) {
                      _reviewDataLoaded = false;
                      await _loadReviewData();
                    }
                  },
                ),
              ),
            ],
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
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );

    return SingleChildScrollView(
      controller: _scrollController,
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
            onRoasterTap: bean.roaster.isNotEmpty
                ? () => _navigateToRoasterProfile(context, bean.roaster)
                : null,
            brewsLeft: controller.brewsLeft,
          ),

          // Roaster website crowdsourcing prompt (plan 011): shown only for a
          // pending candidate roaster the user hasn't been asked about yet.
          if (bean.roaster.isNotEmpty)
            RoasterContributionPromptCard(
              roaster: bean.roaster,
              profileLookupCompleted: _roasterProfileLookupCompleted,
              isKnownRoaster: _roasterProfileId != null,
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
                      imageUrl: SupabaseEndpointResolver.localizeStorageUrl(
                        bean.photoUrl!,
                      ),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.base),

          // Basic Info Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.basicInfo,
            bean: bean,
          ),
          const SizedBox(height: AppSpacing.base),

          // Geography & Terroir Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.geography,
            bean: bean,
          ),
          const SizedBox(height: AppSpacing.base),

          // Processing & Roasting Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.processing,
            bean: bean,
          ),
          const SizedBox(height: AppSpacing.base),

          // Inventory Card
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.inventory,
            bean: bean,
          ),
          const SizedBox(height: AppSpacing.base),

          // Flavor Profile Card
          CoffeeBeansInfoCard(type: CoffeeBeansInfoCardType.flavor, bean: bean),
          const SizedBox(height: AppSpacing.base),

          // Your Review section
          _buildYourReviewSection(context, bean),
          const SizedBox(height: AppSpacing.base),

          // Additional Notes Card (inline quick edit)
          QuickNotesCard(bean: bean, controller: controller),
          const SizedBox(height: AppSpacing.base),

          // Brews made with this coffee (collapsed by default)
          BeanBrewsSection(
            beansUuid: bean.beansUuid,
            statsFuture: _beanStatsFuture,
            onJourneyTap: () => _openBeanJourney(bean.beansUuid),
          ),
        ],
      ),
    );
  }
}
