// lib/widgets/roaster_profile/review_form.dart
//
// Bottom sheet form for writing or editing a bean review.
// Displays beans from the user's collection where the roaster matches.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_router.gr.dart';
import '../../database/database.dart';
import '../../l10n/app_localizations.dart';
import '../../models/bean_review_model.dart';
import '../../models/brewing_method_model.dart';
import '../../models/coffee_beans_model.dart';
import '../../providers/bean_review_provider.dart';
import '../../providers/coffee_beans_provider.dart';
import '../../services/authentication_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/base_buttons.dart';
import '../containers/section_card.dart';
import 'flavor_notes_picker.dart';
import 'star_rating.dart';
import 'taste_profile_sliders.dart';

/// Shows the review form as a modal bottom sheet.
/// Returns true if a review was successfully submitted/updated.
/// [roasterProfileId] may be null when the roaster has no directory profile yet.
Future<bool> showReviewForm(
  BuildContext context, {
  String? roasterProfileId,
  required String roasterName,
  BeanReviewModel? existingReview,
  CoffeeBeansModel? preselectedBean,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
    ),
    builder: (_) => _ReviewFormSheet(
      roasterProfileId: roasterProfileId,
      roasterName: roasterName,
      existingReview: existingReview,
      preselectedBean: preselectedBean,
    ),
  );
  return result ?? false;
}

class _ReviewFormSheet extends StatefulWidget {
  final String? roasterProfileId;
  final String roasterName;
  final BeanReviewModel? existingReview;
  final CoffeeBeansModel? preselectedBean;

  const _ReviewFormSheet({
    required this.roasterProfileId,
    required this.roasterName,
    this.existingReview,
    this.preselectedBean,
  });

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  late double _rating;
  late final TextEditingController _reviewController;
  late final TextEditingController _brewMethodController;
  CoffeeBeansModel? _selectedBean;
  List<CoffeeBeansModel> _matchingBeans = [];
  bool _loadingBeans = true;
  bool _submitting = false;

  // Taste profile — null until user interacts
  double? _sweetness;
  double? _acidity;
  double? _body;
  double? _bitterness;
  double? _aftertaste;
  final Set<String> _interactedSliderKeys = {};

  // New fields
  List<BrewingMethodModel> _allBrewingMethods = [];
  String? _selectedBrewingMethodId;
  bool? _wouldBuyAgain;
  List<String> _flavorTags = [];
  bool _loadingBrewMethods = true;

  bool get _isEditing => widget.existingReview != null;
  // When a specific bean is pre-selected (e.g. from bean detail screen),
  // the selector is locked — the user cannot change which bean they review.
  bool get _beanLocked => widget.preselectedBean != null && !_isEditing;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    _rating = existing?.rating ?? 0;
    _reviewController = TextEditingController(text: existing?.reviewText ?? '');
    _brewMethodController = TextEditingController();

    // Restore taste profile from existing review
    _sweetness = existing?.sweetness;
    _acidity = existing?.acidity;
    _body = existing?.body;
    _bitterness = existing?.bitterness;
    _aftertaste = existing?.aftertaste;

    // Pre-mark sliders as interacted if they have saved values
    if (_sweetness != null) _interactedSliderKeys.add('sweetness');
    if (_acidity != null) _interactedSliderKeys.add('acidity');
    if (_body != null) _interactedSliderKeys.add('body');
    if (_bitterness != null) _interactedSliderKeys.add('bitterness');
    if (_aftertaste != null) _interactedSliderKeys.add('aftertaste');

    // New fields
    _selectedBrewingMethodId = existing?.brewingMethodId;
    _wouldBuyAgain = existing?.wouldBuyAgain;
    _flavorTags = existing?.flavorTags ?? [];

    _loadBeans();
    _loadBrewMethods();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _brewMethodController.dispose();
    super.dispose();
  }

  Future<void> _loadBeans() async {
    final beansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final reviewProvider =
        Provider.of<BeanReviewProvider>(context, listen: false);

    final all = await beansProvider.fetchAllCoffeeBeans();
    final roasterLower = widget.roasterName.trim().toLowerCase();
    final roasterBeans = all
        .where((b) => b.roaster.toLowerCase() == roasterLower && !b.isDeleted)
        .toList();

    // Fetch which beans the user has already reviewed so we can exclude them
    // from the selector (enforcing 1 review per bean record in the UI).
    final userReviews = await reviewProvider.fetchUserReviews();
    final reviewedUuids = userReviews
        .where((r) => r.coffeeBeansUuid != null)
        .map((r) => r.coffeeBeansUuid!)
        .toSet();

    // Allow the existing review's bean through so edit mode still works.
    final existingUuid = widget.existingReview?.coffeeBeansUuid;
    final matching = roasterBeans.where((b) {
      if (b.beansUuid == existingUuid) return true;
      return !reviewedUuids.contains(b.beansUuid);
    }).toList();

    if (!mounted) return;
    setState(() {
      _matchingBeans = matching;
      _loadingBeans = false;

      // Pre-select: from prop, or from existing review, or first in list
      if (widget.preselectedBean != null) {
        final uuid = widget.preselectedBean!.beansUuid;
        final found = matching.where((b) => b.beansUuid == uuid);
        _selectedBean = found.isNotEmpty
            ? found.first
            : (matching.isNotEmpty ? matching.first : null);
      } else if (existingUuid != null) {
        final found = matching.where((b) => b.beansUuid == existingUuid);
        _selectedBean = found.isNotEmpty ? found.first : null;
      } else if (matching.isNotEmpty) {
        _selectedBean = matching.first;
      }
    });
  }

  Future<void> _loadBrewMethods() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final methods = await db.brewingMethodsDao.getAllBrewingMethods();

    // Pre-select the most recently used method for these beans (if any)
    String? preselect = _selectedBrewingMethodId;
    if (preselect == null) {
      final beansUuid = widget.preselectedBean?.beansUuid ??
          widget.existingReview?.coffeeBeansUuid;
      if (beansUuid != null) {
        final recent =
            await db.userStatsDao.fetchDistinctBrewingMethodsForBean(beansUuid);
        if (recent.isNotEmpty) preselect = recent.first;
      }
    }

    if (!mounted) return;
    setState(() {
      _allBrewingMethods = methods;
      _selectedBrewingMethodId ??= preselect;
      _loadingBrewMethods = false;
    });
    _syncBrewMethodController();
  }

  void _syncBrewMethodController() {
    final method = _allBrewingMethods
        .where((m) => m.brewingMethodId == _selectedBrewingMethodId)
        .firstOrNull;
    _brewMethodController.text = method?.brewingMethod ?? '';
  }

  Future<void> _showBrewMethodModal(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.reviewBrewMethodLabel),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        children: _allBrewingMethods
            .map(
              (m) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, m.brewingMethodId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    m.brewingMethod,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: m.brewingMethodId == _selectedBrewingMethodId
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedBrewingMethodId = selected);
      _syncBrewMethodController();
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    if (!_isEditing && _selectedBean == null) return;

    setState(() => _submitting = true);

    // Auto-moderation: check review text before publishing.
    // Skip if text is empty (rating-only review has nothing to flag).
    final text = _reviewController.text.trim();
    if (text.isNotEmpty) {
      try {
        final moderationResponse =
            await Supabase.instance.client.functions.invoke(
          'content-moderation',
          body: {'text': text},
        );
        if (!mounted) return;
        if (moderationResponse.status == 200 &&
            moderationResponse.data != null) {
          final result = moderationResponse.data as Map<String, dynamic>;
          if (result['safe'] != true) {
            final l10n = AppLocalizations.of(context)!;
            final reason =
                (result['reason'] as String?) ?? l10n.moderationReasonDefault;
            setState(() => _submitting = false);
            final outerContext = context;
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                title: Text(l10n.moderationFailedTitle),
                content: Text(l10n.reviewModerationFailedBody(reason)),
                actions: [
                  AppTextButton(
                    label: l10n.moderationRulesLearnMore,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      outerContext.router
                          .push(InfoRoute(section: 'moderation'));
                    },
                    isFullWidth: false,
                    height: AppButton.heightMedium,
                    padding: AppButton.paddingMedium,
                  ),
                  AppElevatedButton(
                    label: l10n.dismiss,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    isFullWidth: false,
                    height: AppButton.heightMedium,
                    padding: AppButton.paddingMedium,
                  ),
                ],
              ),
            );
            return;
          }
        }
      } catch (_) {
        // Moderation API failure — proceed with submission rather than
        // blocking the user on an infrastructure issue.
        if (!mounted) return;
      }
    }

    final provider = Provider.of<BeanReviewProvider>(context, listen: false);

    bool ok;
    if (_isEditing) {
      ok = await provider.updateReview(
        reviewId: widget.existingReview!.id,
        roasterProfileId: widget.roasterProfileId!,
        rating: _rating,
        reviewText: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        sweetness:
            _interactedSliderKeys.contains('sweetness') ? _sweetness : null,
        acidity: _interactedSliderKeys.contains('acidity') ? _acidity : null,
        fruitiness: null,
        body: _interactedSliderKeys.contains('body') ? _body : null,
        bitterness:
            _interactedSliderKeys.contains('bitterness') ? _bitterness : null,
        aftertaste:
            _interactedSliderKeys.contains('aftertaste') ? _aftertaste : null,
        coffeeBeansUuid: widget.existingReview!.coffeeBeansUuid,
        brewingMethodId: _selectedBrewingMethodId,
        wouldBuyAgain: _wouldBuyAgain,
        flavorTags: _flavorTags.isEmpty ? null : _flavorTags,
      );
    } else {
      ok = await provider.submitReview(
        roasterProfileId: widget.roasterProfileId,
        roasterName: widget.roasterName,
        beanName: _selectedBean!.name,
        coffeeBeansUuid: _selectedBean!.beansUuid,
        rating: _rating,
        reviewText: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        sweetness:
            _interactedSliderKeys.contains('sweetness') ? _sweetness : null,
        acidity: _interactedSliderKeys.contains('acidity') ? _acidity : null,
        fruitiness: null,
        body: _interactedSliderKeys.contains('body') ? _body : null,
        bitterness:
            _interactedSliderKeys.contains('bitterness') ? _bitterness : null,
        aftertaste:
            _interactedSliderKeys.contains('aftertaste') ? _aftertaste : null,
        brewingMethodId: _selectedBrewingMethodId,
        wouldBuyAgain: _wouldBuyAgain,
        flavorTags: _flavorTags.isEmpty ? null : _flavorTags,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;

    final bool tasteProfileInitiallyExpanded = widget.existingReview != null &&
        (widget.existingReview!.hasTasteProfile ||
            widget.existingReview!.flavorTags?.isNotEmpty == true);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        top: AppSpacing.base,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.base),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              _isEditing ? l10n.editReview : l10n.writeReview,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.base),

            // Sign-in gate — show prompt and nothing else
            if (user == null) ...[
              Text(l10n.signInToReview, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.base),
              AppElevatedButton(
                label: l10n.signInToReview,
                onPressed: () async {
                  final signedIn =
                      await AuthenticationService.promptSignIn(context);
                  if (signedIn && mounted) {
                    setState(() {});
                  }
                },
              ),
            ] else ...[
              // Bean selector (only for new reviews)
              if (!_isEditing) ...[
                Text(l10n.reviewBeanLabel, style: AppTextStyles.fieldLabel),
                const SizedBox(height: AppSpacing.xs),
                if (_loadingBeans)
                  const Center(child: CircularProgressIndicator())
                else if (_beanLocked)
                  // Bean is fixed (came from the bean detail screen)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      color: colorScheme.surfaceContainerHighest
                          .withOpacity(0.4),
                    ),
                    child: Text(
                      _selectedBean?.name ?? widget.preselectedBean!.name,
                      style: AppTextStyles.body,
                    ),
                  )
                else if (_matchingBeans.isEmpty)
                  Text(
                    l10n.noRecipesYet,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  )
                else
                  DropdownButtonFormField<CoffeeBeansModel>(
                    value: _selectedBean,
                    hint: Text(l10n.selectBeanForReview),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    items: _matchingBeans
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child:
                                Text(b.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBean = v),
                  ),
                const SizedBox(height: AppSpacing.base),
              ],

              // Star rating
              Text(l10n.reviewRatingLabel, style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.xs),
              StarRating(
                value: _rating,
                starSize: AppIconSize.large,
                interactive: true,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: AppSpacing.base),

              // Review text
              Text(l10n.reviewTextLabel, style: AppTextStyles.fieldLabel),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.reviewTextLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.base),
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              // Brew method
              if (_loadingBrewMethods)
                const SizedBox(
                  height: 56,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _brewMethodController,
                  readOnly: true,
                  onTap: () => _showBrewMethodModal(context),
                  decoration: InputDecoration(
                    labelText: l10n.reviewBrewMethodLabel,
                    hintText: l10n.reviewBrewMethodHint,
                    suffixIcon: const Icon(Icons.keyboard_arrow_down),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade500
                            : Colors.grey.shade300,
                        width: AppStroke.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade500
                            : Colors.grey.shade300,
                        width: AppStroke.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        width: AppStroke.focus,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.base),

              // Would buy again — label + colored toggle buttons in one row
              Row(
                children: [
                  Text(l10n.reviewWouldBuyAgainLabel,
                      style: AppTextStyles.fieldLabel),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _BuyAgainButton(
                            label: 'Yes',
                            selected: _wouldBuyAgain == true,
                            activeColor: const Color(0xFF43A047),
                            onTap: () => setState(() => _wouldBuyAgain =
                                _wouldBuyAgain == true ? null : true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _BuyAgainButton(
                            label: 'No',
                            selected: _wouldBuyAgain == false,
                            activeColor: colorScheme.error,
                            onTap: () => setState(() => _wouldBuyAgain =
                                _wouldBuyAgain == false ? null : false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),

              // Taste profile (collapsed by default) — flavor notes + sliders
              SectionCard(
                title: l10n.tasteProfileAdvancedTitle,
                icon: Icons.tune_outlined,
                isCollapsible: true,
                initiallyExpanded: tasteProfileInitiallyExpanded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.reviewFlavorNotesLabel,
                        style: AppTextStyles.fieldLabel),
                    const SizedBox(height: AppSpacing.xs),
                    FlavorNotesPicker(
                      selectedTags: _flavorTags,
                      onChanged: (tags) =>
                          setState(() => _flavorTags = tags),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    const Divider(),
                    const SizedBox(height: AppSpacing.xs),
                    TasteProfileSliders(
                      sweetness: _sweetness,
                      acidity: _acidity,
                      body: _body,
                      bitterness: _bitterness,
                      aftertaste: _aftertaste,
                      readOnly: false,
                      interactedKeys: _interactedSliderKeys,
                      onChanged: (values) => setState(() {
                        _sweetness = values['sweetness'];
                        _acidity = values['acidity'];
                        _body = values['body'];
                        _bitterness = values['bitterness'];
                        _aftertaste = values['aftertaste'];
                      }),
                      onSliderInteracted: (key) =>
                          setState(() => _interactedSliderKeys.add(key)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppElevatedButton(
                label: l10n.submitReviewButton,
                onPressed: (_rating > 0 &&
                        (_isEditing || _selectedBean != null) &&
                        !_submitting)
                    ? _submit
                    : null,
                isLoading: _submitting,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _BuyAgainButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _BuyAgainButton({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        selected ? _contrastColor(activeColor) : activeColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppButton.heightMedium,
        decoration: BoxDecoration(
          color: selected ? activeColor : activeColor.withAlpha(15),
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(
            color: selected ? activeColor : activeColor.withAlpha(120),
            width: selected ? AppStroke.focus : AppStroke.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _contrastColor(Color color) =>
      color.computeLuminance() > 0.35 ? Colors.black87 : Colors.white;
}
