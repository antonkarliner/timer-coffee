import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffeico/coffeico.dart';
import '../widgets/smart_back_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/user_stat_model.dart';
import 'package:intl/intl.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../utils/icon_utils.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../widgets/expandable_card.dart';
import '../notifiers/card_expansion_notifier.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../models/coffee_beans_model.dart';
import '../widgets/roaster_logo.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart'; // Import AppLogger
import '../widgets/base_buttons.dart';
import '../services/date_time_format_service.dart';

@RoutePage()
class BrewDiaryScreen extends StatefulWidget {
  const BrewDiaryScreen({super.key, this.initialExpandedStatUuid});

  final String? initialExpandedStatUuid;

  @override
  State<BrewDiaryScreen> createState() => _BrewDiaryScreenState();
}

class _BrewDiaryScreenState extends State<BrewDiaryScreen> {
  bool isEditMode = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _targetKey = GlobalKey();
  bool _scrollScheduled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String getSweeetnessLabel(int position) {
    final loc = AppLocalizations.of(context)!;
    switch (position) {
      case 0:
        return loc.sweet;
      case 1:
        return loc.balance;
      case 2:
        return loc.acidic;
      default:
        return loc.donationerr;
    }
  }

  String getStrengthLabel(int position) {
    final loc = AppLocalizations.of(context)!;
    switch (position) {
      case 0:
        return loc.light;
      case 1:
        return loc.balance;
      case 2:
        return loc.strong;
      default:
        return loc.donationerr;
    }
  }

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  /// Illustrated empty-state for a diary with no entries. Shown both when the
  /// query returns an empty list and when it returns no data at all.
  Widget _buildEmptyCharm(BuildContext context, {required String semanticsId}) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        identifier: semanticsId,
        label: loc.mts_emptyDiaryTitle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_cafe_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                loc.mts_emptyDiaryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              AppTextButton(
                label: loc.mts_emptyDiaryAction,
                icon: Icons.local_cafe,
                onPressed: () => context.router.navigate(const HomeRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<UserStatsModel> stats) {
    final loc = AppLocalizations.of(context)!;
    final fmtSvc = Provider.of<DateTimeFormatService>(context);

    // Group stats by date
    Map<String, List<UserStatsModel>> groupedStats = {};
    final activeDatePattern = fmtSvc.datePattern(loc.dateFormat);
    DateFormat dateFormat = DateFormat(
      activeDatePattern,
      Localizations.localeOf(context).toString(),
    );

    for (var stat in stats) {
      String dateKey = dateFormat.format(stat.createdAt.toLocal());
      if (!groupedStats.containsKey(dateKey)) {
        groupedStats[dateKey] = [];
      }
      groupedStats[dateKey]!.add(stat);
    }

    // Sort dates in descending order (newest first)
    List<String> sortedDates = groupedStats.keys.toList();
    sortedDates.sort((a, b) {
      DateTime dateA = DateFormat(
        activeDatePattern,
        Localizations.localeOf(context).toString(),
      ).parse(a);
      DateTime dateB = DateFormat(
        activeDatePattern,
        Localizations.localeOf(context).toString(),
      ).parse(b);
      return dateB.compareTo(dateA); // Descending order
    });

    if (widget.initialExpandedStatUuid != null && !_scrollScheduled) {
      _scrollScheduled = true;
      _scheduleScrollToTarget(groupedStats, sortedDates);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _calculateTotalItems(groupedStats, sortedDates),
      itemBuilder: (context, index) {
        return _buildListItem(groupedStats, sortedDates, index);
      },
    );
  }

  // Date separator height (vertical padding 32 + text row ~24)
  static const double _separatorHeight = 56.0;
  // Collapsed card height (ListTile + subtitle + Card borders) + bottom padding
  static const double _cardHeight = 124.0;
  // ListView top padding
  static const double _listPadding = 16.0;

  void _scheduleScrollToTarget(
    Map<String, List<UserStatsModel>> groupedStats,
    List<String> sortedDates,
  ) {
    final targetUuid = widget.initialExpandedStatUuid!;
    double offset = _listPadding;
    bool found = false;

    for (final date in sortedDates) {
      offset += _separatorHeight;
      for (final stat in groupedStats[date]!) {
        if (stat.statUuid == targetUuid) {
          found = true;
          break;
        }
        offset += _cardHeight;
      }
      if (found) break;
    }

    if (!found) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      // Jump to estimated position so ListView.builder builds the target item.
      _scrollController.jumpTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
      // Second frame: the target item is now built — scroll precisely to it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignment: 0.1,
          );
        }
      });
    });
  }

  int _calculateTotalItems(
    Map<String, List<UserStatsModel>> groupedStats,
    List<String> sortedDates,
  ) {
    int totalItems = 0;
    for (String date in sortedDates) {
      totalItems += 1; // Date separator
      totalItems += groupedStats[date]!.length; // Cards for that date
    }
    return totalItems;
  }

  Widget _buildListItem(
    Map<String, List<UserStatsModel>> groupedStats,
    List<String> sortedDates,
    int index,
  ) {
    int currentIndex = 0;

    for (String date in sortedDates) {
      // Check if this index is the date separator
      if (currentIndex == index) {
        return _buildDateSeparator(date);
      }
      currentIndex++;

      // Check if this index is one of the cards for this date
      List<UserStatsModel> statsForDate = groupedStats[date]!;
      for (int i = 0; i < statsForDate.length; i++) {
        if (currentIndex == index) {
          final card = buildUserStatCard(context, statsForDate[i]);
          final isTarget =
              statsForDate[i].statUuid == widget.initialExpandedStatUuid;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: isTarget ? KeyedSubtree(key: _targetKey, child: card) : card,
          );
        }
        currentIndex++;
      }
    }

    // Fallback (should not happen)
    return const SizedBox.shrink();
  }

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              date,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userStatProvider = Provider.of<UserStatProvider>(context);
    final loc = AppLocalizations.of(context)!;

    final initialUuid = widget.initialExpandedStatUuid;
    return ChangeNotifierProvider(
      create: (_) {
        final notifier = CardExpansionNotifier();
        if (initialUuid != null) {
          notifier.setExpansion(initialUuid, true);
        }
        return notifier;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Semantics(
            identifier: 'brewDiaryBackButton',
            child: const SmartBackButton(),
          ),
          title: Semantics(
            identifier: 'brewDiaryAppBar',
            label: loc.brewdiary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.library_books),
                const SizedBox(width: 8),
                Text(loc.brewdiary),
              ],
            ),
          ),
          actions: [
            if (!isEditMode)
              Semantics(
                identifier: 'addBrewEntryButton',
                child: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await context.router.push(
                      const ManualBrewEntryRoute(),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                ),
              ),
            Semantics(
              identifier: 'toggleEditModeButton',
              child: IconButton(
                icon: Icon(isEditMode ? Icons.done : Icons.edit_note),
                onPressed: toggleEditMode,
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: FutureBuilder<List<UserStatsModel>>(
            future: userStatProvider.fetchAllUserStats(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Semantics(
                    identifier: 'brewDiaryError',
                    label: 'Error',
                    child: Text("Error: ${snapshot.error}"),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                return _buildEmptyCharm(context, semanticsId: 'brewDiaryEmpty');
              } else if (snapshot.hasData) {
                return _buildGroupedList(snapshot.data!);
              } else {
                return _buildEmptyCharm(
                  context,
                  semanticsId: 'brewDiaryEmptyFallback',
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildUserStatCard(BuildContext context, UserStatsModel stat) {
    final loc = AppLocalizations.of(context)!;
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final userStatProvider = Provider.of<UserStatProvider>(context);
    final fmtSvc = Provider.of<DateTimeFormatService>(context);
    final is24h = fmtSvc.use24Hour(
      MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final timePattern = is24h ? 'HH:mm' : 'hh:mm a';
    DateFormat dateFormat = DateFormat(
      '${fmtSvc.datePattern(loc.dateFormat)} $timePattern',
      Localizations.localeOf(context).toString(),
    );

    return FutureBuilder<List<String>>(
      future: Future.wait([
        recipeProvider.getBrewingMethodName(stat.brewingMethodId),
        recipeProvider.getLocalizedRecipeName(stat.recipeId),
      ]),
      builder: (context, namesSnapshot) {
        if (namesSnapshot.hasData) {
          return Semantics(
            key: ValueKey(stat.statUuid),
            identifier: 'userStatCard_${stat.statUuid}',
            label: '${namesSnapshot.data![1]}, ${namesSnapshot.data![0]}',
            child: Consumer<CardExpansionNotifier>(
              builder: (context, notifier, _) {
                bool isExpanded = notifier.isExpanded(stat.statUuid);
                return ExpandableCard(
                  key: ValueKey(stat.statUuid),
                  leading: getIconByBrewingMethod(stat.brewingMethodId),
                  header: namesSnapshot.data![1],
                  headerStyle: const TextStyle(fontWeight: FontWeight.bold),
                  subtitle: "", // We'll use a custom subtitle in the ListTile
                  subtitleWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(namesSnapshot.data![0]),
                      const SizedBox(height: 8),
                      Text(dateFormat.format(stat.createdAt.toLocal())),
                    ],
                  ),
                  detail: buildDetail(context, stat),
                  trailing: isEditMode
                      ? Semantics(
                          identifier: 'deleteUserStatButton_${stat.statUuid}',
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDeleteDialog(
                                  title: AppLocalizations.of(
                                    context,
                                  )!.confirmDeleteTitle,
                                  content: AppLocalizations.of(
                                    context,
                                  )!.confirmDeleteMessage,
                                  confirmLabel: AppLocalizations.of(
                                    context,
                                  )!.delete,
                                  cancelLabel: AppLocalizations.of(
                                    context,
                                  )!.cancel,
                                ),
                              );
                              if (confirmed == true) {
                                await userStatProvider.deleteUserStat(
                                  stat.statUuid,
                                );
                                notifier.setExpansion(stat.statUuid, false);
                              }
                            },
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (stat.rating != null)
                              Text(
                                '★ ${stat.rating!.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            Semantics(
                              identifier: 'markBrewButton_${stat.statUuid}',
                              child: IconButton(
                                icon: Icon(
                                  stat.isMarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: stat.isMarked
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                iconSize: AppIconSize.medium,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    userStatProvider.updateUserStat(
                                      statUuid: stat.statUuid,
                                      isMarked: !stat.isMarked,
                                    ),
                              ),
                            ),
                          ],
                        ),
                  isExpanded: isExpanded,
                  onExpansionChanged: (bool expanded) {
                    notifier.setExpansion(stat.statUuid, expanded);
                  },
                );
              },
            ),
          );
        } else if (namesSnapshot.connectionState == ConnectionState.waiting) {
          return Semantics(
            identifier: 'brewDiaryCardLoading_${stat.statUuid}',
            label: 'Loading User Stat Card',
            child: const Card(child: ListTile(title: Text("Loading..."))),
          );
        } else {
          return Semantics(
            identifier: 'brewDiaryCardError_${stat.statUuid}',
            label: 'Error Loading User Stat Card',
            child: const Card(
              child: ListTile(title: Text("Error fetching records")),
            ),
          );
        }
      },
    );
  }

  Widget buildDetail(BuildContext context, UserStatsModel stat) {
    final loc = AppLocalizations.of(context)!;
    TextStyle detailTextStyle = Theme.of(context).textTheme.titleMedium!;
    TextStyle labelStyle = detailTextStyle.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    TextStyle valueStyle = detailTextStyle.copyWith(fontSize: 18);
    final userStatProvider = Provider.of<UserStatProvider>(context);
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    TextEditingController notesController = TextEditingController(
      text: stat.notes,
    );
    FocusNode notesFocusNode = FocusNode();

    notesFocusNode.addListener(() {
      if (!notesFocusNode.hasFocus) {
        Provider.of<UserStatProvider>(
          context,
          listen: false,
        ).updateUserStat(statUuid: stat.statUuid, notes: notesController.text);
      }
    });

    return Semantics(
      identifier: 'userStatDetail_${stat.statUuid}',
      label: 'User Stat Details',
      child: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ), // Increased padding for better spacing
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to start
          children: [
            // Coffee Amount
            Semantics(
              identifier: 'coffeeAmount_${stat.statUuid}',
              label: '${loc.coffeeamount}: ${stat.coffeeAmount}',
              child: Row(
                children: [
                  Text("${loc.coffeeamount}: ", style: labelStyle),
                  Text(stat.coffeeAmount.toString(), style: valueStyle),
                ],
              ),
            ),
            const SizedBox(height: 8), // Added spacing between elements
            // Water Amount
            Semantics(
              identifier: 'waterAmount_${stat.statUuid}',
              label: '${loc.wateramount}: ${stat.waterAmount}',
              child: Row(
                children: [
                  Text("${loc.wateramount}: ", style: labelStyle),
                  Text(stat.waterAmount.toString(), style: valueStyle),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Grind Size
            if (stat.grindSize != null && stat.grindSize!.isNotEmpty)
              Semantics(
                identifier: 'grindSize_${stat.statUuid}',
                label: '${loc.grindsize}: ${stat.grindSize}',
                child: Row(
                  children: [
                    Text("${loc.grindsize}: ", style: labelStyle),
                    Text(stat.grindSize!, style: valueStyle),
                  ],
                ),
              ),
            if (stat.grindSize != null && stat.grindSize!.isNotEmpty)
              const SizedBox(height: 8),
            // Sweetness and Strength (if applicable)
            if (stat.recipeId == '106')
              Semantics(
                identifier: 'sweetnessStrength_${stat.id}',
                label:
                    "${getSweeetnessLabel(stat.sweetnessSliderPosition)}, ${getStrengthLabel(stat.strengthSliderPosition)}",
                child: Text(
                  "${getSweeetnessLabel(stat.sweetnessSliderPosition)}, ${getStrengthLabel(stat.strengthSliderPosition)}",
                  style: detailTextStyle,
                  textAlign: TextAlign.start,
                ),
              ),
            const SizedBox(height: 8),
            // Extraction calculator result (if the user saved one for this brew)
            if (stat.extractionYieldPercent != null)
              Semantics(
                identifier: 'extractionCalcDiaryLine_${stat.statUuid}',
                label: stat.tdsPercent != null
                    ? loc.extractionCalcDiaryLine(
                        stat.extractionYieldPercent!.toStringAsFixed(1),
                        stat.tdsPercent!.toStringAsFixed(2),
                      )
                    : '${loc.extractionCalcResultLabel}: '
                          '${stat.extractionYieldPercent!.toStringAsFixed(1)}%',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    stat.tdsPercent != null
                        ? loc.extractionCalcDiaryLine(
                            stat.extractionYieldPercent!.toStringAsFixed(1),
                            stat.tdsPercent!.toStringAsFixed(2),
                          )
                        : '${loc.extractionCalcResultLabel}: '
                              '${stat.extractionYieldPercent!.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            // Calculate extraction action — always available, independent of
            // whether a result has been saved yet.
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                identifier: 'calculateExtractionButton_${stat.statUuid}',
                label: 'Calculate Extraction Button',
                child: SizedBox(
                  height: 56,
                  child: AppElevatedButton(
                    label: loc.extractionCalcDiaryAction,
                    icon: Icons.calculate_outlined,
                    onPressed: () => context.router.push(
                      ExtractionCalculatorRoute(statUuid: stat.statUuid),
                    ),
                    isFullWidth: false,
                    height: 56,
                    padding: AppButton.paddingSmall,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Divider
            const Divider(thickness: 0.5, indent: 10, endIndent: 10),
            const SizedBox(height: 8),
            // Beans Section Title
            if (stat.coffeeBeansUuid == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      loc.beans,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      identifier: 'selectBeansButton_${stat.statUuid}',
                      label: 'Select Beans Button',
                      child: SizedBox(
                        height: 56,
                        child: AppElevatedButton(
                          label: loc.selectBeans,
                          onPressed: () =>
                              _openAddBeansPopup(context, stat.statUuid),
                          isFullWidth: false,
                          height: 56,
                          padding: AppButton.paddingSmall,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  loc.beans,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            // Beans Details or Selection Button
            if (stat.coffeeBeansUuid != null)
              FutureBuilder<CoffeeBeansModel?>(
                future: coffeeBeansProvider.fetchCoffeeBeansByUuid(
                  stat.coffeeBeansUuid!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final bean = snapshot.data!;
                    return FutureBuilder<Map<String, String?>>(
                      future: databaseProvider.fetchCachedRoasterLogoUrls(
                        bean.roaster,
                      ),
                      builder: (context, logoSnapshot) {
                        const double logoHeight = 80.0;
                        const double maxWidthFactor = 2.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row with logo and details
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRoasterLogoPlate(
                                      context,
                                      databaseProvider,
                                      bean.roaster,
                                      logoHeight,
                                      maxWidthFactor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Table(
                                          columnWidths: {
                                            0: IntrinsicColumnWidth(),
                                            1: FlexColumnWidth(),
                                          },
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.top,
                                          children: [
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8.0,
                                                      ),
                                                  child: Text(
                                                    '${loc.name}: ',
                                                    style: labelStyle,
                                                  ),
                                                ),
                                                Text(
                                                  bean.name,
                                                  style: valueStyle,
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                SizedBox(height: 8),
                                                SizedBox(height: 8),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8.0,
                                                      ),
                                                  child: Text(
                                                    '${loc.roaster}: ',
                                                    style: labelStyle,
                                                  ),
                                                ),
                                                Text(
                                                  bean.roaster,
                                                  style: valueStyle,
                                                ),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                SizedBox(height: 8),
                                                SizedBox(height: 8),
                                              ],
                                            ),
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8.0,
                                                      ),
                                                  child: Text(
                                                    '${loc.origin}: ',
                                                    style: labelStyle,
                                                  ),
                                                ),
                                                Text(
                                                  bean.origin,
                                                  style: valueStyle,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Keep bean actions on one row and scale down on narrow cards.
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: SizedBox(
                                  height: 56,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 56,
                                          child: AppElevatedButton(
                                            label: loc.details,
                                            onPressed: () {
                                              context.router.push(
                                                CoffeeBeansDetailRoute(
                                                  uuid: bean.beansUuid,
                                                ),
                                              );
                                            },
                                            isFullWidth: false,
                                            height: 56,
                                            padding: AppButton.paddingSmall,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 56,
                                          child: AppTextButton(
                                            label: loc.removeFromEntry,
                                            onPressed: () async {
                                              final scaffoldMessenger =
                                                  ScaffoldMessenger.of(context);
                                              AppLogger.debug(
                                                'Remove beans button pressed for stat: ${stat.statUuid}',
                                              );
                                              AppLogger.debug(
                                                'Current coffeeBeansUuid: ${stat.coffeeBeansUuid}',
                                              );

                                              // Add weight back to beans before removing the reference
                                              if (stat.coffeeBeansUuid !=
                                                  null) {
                                                // Fetch bean data to get the bean name
                                                final bean =
                                                    await coffeeBeansProvider
                                                        .fetchCoffeeBeansByUuid(
                                                          stat.coffeeBeansUuid!,
                                                        );
                                                final beanName =
                                                    bean?.name ??
                                                    'Unknown beans';

                                                final newWeight =
                                                    await coffeeBeansProvider
                                                        .updateBeanWeightAfterBrewModification(
                                                          stat.coffeeBeansUuid!,
                                                          stat.coffeeAmount,
                                                        );

                                                if (newWeight != null &&
                                                    context.mounted) {
                                                  scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        loc.beansWeightAddedBack(
                                                          stat.coffeeAmount
                                                              .toString(),
                                                          beanName,
                                                          newWeight
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                          loc.unitGramsShort,
                                                        ),
                                                      ),
                                                      duration: Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }

                                              await userStatProvider
                                                  .updateUserStat(
                                                    statUuid: stat.statUuid,
                                                    clearBeans: true,
                                                  );
                                              AppLogger.debug(
                                                'updateUserStat called',
                                              );
                                            },
                                            isFullWidth: false,
                                            height: 56,
                                            padding: AppButton.paddingSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No beans found'));
                  }
                },
              )
            else
              const SizedBox.shrink(),
            const Divider(thickness: 0.5, indent: 10, endIndent: 10),
            const SizedBox(height: 8),
            // Notes Section
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
              child: Text(
                loc.notes,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Semantics(
              identifier: 'notesInputField_${stat.statUuid}',
              label: 'Notes Input Field',
              child: TextFormField(
                initialValue: stat.notes,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  // Debounce the updates to avoid too many calls
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    userStatProvider.updateUserStat(
                      statUuid: stat.statUuid,
                      notes: value,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddBeansPopup(BuildContext context, String statUuid) {
    final loc = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    final expansionNotifier = Provider.of<CardExpansionNotifier>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddCoffeeBeansWidget(
          onSelect: (String selectedBeanUuid) async {
            // Get the current stat to know the coffee amount
            final currentStat = await userStatProvider.fetchUserStatByUuid(
              statUuid,
            );

            if (currentStat != null) {
              // Subtract weight from the selected beans
              final newWeight = await coffeeBeansProvider
                  .updateBeanWeightWhenBeansAdded(
                    selectedBeanUuid,
                    currentStat.coffeeAmount,
                  );

              if (newWeight != null) {
                // Fetch bean data to get the bean name
                final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(
                  selectedBeanUuid,
                );
                final beanName = bean?.name ?? 'Unknown beans';

                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        loc.beansWeightSubtracted(
                          currentStat.coffeeAmount.toString(),
                          beanName,
                          newWeight.toStringAsFixed(1),
                          loc.unitGramsShort,
                        ),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }

            await userStatProvider.updateUserStat(
              statUuid: statUuid,
              coffeeBeansUuid: selectedBeanUuid,
            );
            expansionNotifier.addBean(statUuid);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  Widget _buildRoasterLogoPlate(
    BuildContext context,
    DatabaseProvider databaseProvider,
    String roaster,
    double logoHeight,
    double maxWidthFactor,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isLogoHorizontal = false;

        return FutureBuilder<Map<String, String?>>(
          future: databaseProvider.fetchCachedRoasterLogoUrls(roaster),
          builder: (context, snapshot) {
            final originalUrl = snapshot.data?['original'];
            final mirrorUrl = snapshot.data?['mirror'];
            final hasLogo = originalUrl != null || mirrorUrl != null;

            // Make plate responsive: square for square logos, wider for horizontal logos
            final plateWidth = isLogoHorizontal
                ? logoHeight * maxWidthFactor
                : logoHeight;
            final plateHeight = logoHeight;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: plateWidth,
              height: plateHeight,
              decoration: BoxDecoration(
                color: hasLogo
                    ? (Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade400
                          : Colors.grey.shade700)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              clipBehavior: Clip.hardEdge,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
                    child: child,
                  ),
                ),
                child: hasLogo
                    ? Padding(
                        key: const ValueKey('logo'),
                        padding: const EdgeInsets.all(4.0),
                        child: RoasterLogo(
                          originalUrl: originalUrl,
                          mirrorUrl: mirrorUrl,
                          height: logoHeight - 8, // Account for padding
                          width: plateWidth - 8, // Account for padding
                          borderRadius: 4,
                          forceFit: BoxFit.contain,
                          onAspectRatioDetermined: (isHorizontal) {
                            if (isLogoHorizontal != isHorizontal) {
                              setState(() {
                                isLogoHorizontal = isHorizontal;
                              });
                            }
                          },
                        ),
                      )
                    : Padding(
                        key: const ValueKey('placeholder'),
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Coffeico.bag_with_bean,
                          size: logoHeight - 8, // Account for padding
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
