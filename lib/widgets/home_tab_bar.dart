import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The main screen's bottom tab bar: brew, beans, hub.
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({super.key, this.controller, this.onTap});

  final TabController? controller;
  final GestureTapIndexCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ConvexAppBar.builder(
      count: 3,
      controller: controller, // <-- keep bar & swipes in sync
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      itemBuilder: _HomeTabBuilder([
        TabItem(icon: Coffeico.coffee_maker, title: l10n.homescreenbrewcoffee),
        TabItem(icon: Coffeico.bag_with_bean, title: l10n.myBeans),
        TabItem(icon: Icons.dashboard, title: l10n.homescreenmore),
      ]),
      onTap: onTap, // taps still change page
    );
  }
}

class _HomeTabBuilder extends DelegateBuilder {
  final List<TabItem> items;

  _HomeTabBuilder(this.items);

  @override
  Widget build(BuildContext context, int index, bool active) {
    Color activeColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Colors.black;
    Color inactiveColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withAlpha((255 * 0.5).round())
        : Colors.black.withAlpha((255 * 0.5).round());
    final color = active ? activeColor : inactiveColor;

    var item = items[index];
    return Semantics(
      identifier: 'tabItem_$index',
      label: item.title ?? "",
      // Center loosens the slot's constraints so the ConstrainedBox can apply:
      // the raised active slot is taller than the bar, and capping both slots
      // at the bar's own height keeps a label the same size wherever it sits.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: BAR_HEIGHT),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(item.icon, size: AppIconSize.medium, color: color),
                // One line, scaled down only when it doesn't fit: long labels
                // (de, ru, fi) and large text sizes stay inside the
                // fixed-height bar instead of wrapping or overflowing it.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.title ?? "",
                      maxLines: 1,
                      style: AppTextStyles.caption.copyWith(color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
