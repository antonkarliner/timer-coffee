import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:provider/provider.dart';

import '../../database/database.dart';
import '../../models/coffee_beans_model.dart';
import '../../providers/coffee_beans_provider.dart';
import '../../utils/app_logger.dart';
import '../../services/local_notification_scheduler_service.dart';
import '../../services/notification_service.dart';
import '../base_buttons.dart';

/// Debug-only panel that fires test notifications after a 5-second delay.
/// Only shown when built with `--dart-define=NOTIF_DEBUG=true` or in debug mode.
class DebugNotificationPanel extends StatelessWidget {
  const DebugNotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final notifications = [
      (
        id: 1001,
        title: l10n.notifBrewReminderTitle,
        body: l10n.notifBrewReminderBody,
        payload: 'notif:brew_reminder',
      ),
      (
        id: 1002,
        title: l10n.notifBrewEscalationTitle,
        body: l10n.notifBrewEscalationBody,
        payload: 'notif:brew_escalation',
      ),
      (
        id: 1101,
        title: l10n.notifDiscoverBeansTitle,
        body: l10n.notifDiscoverBeansBody,
        payload: '/new_beans',
      ),
      (
        id: 1103,
        title: l10n.notifDiscoverPulseTitle,
        body: l10n.notifDiscoverPulseBody,
        payload: '/pulse',
      ),
      (
        id: 1501,
        title: l10n.notifBrewMilestoneTitle,
        body: l10n.notifBrewMilestoneBody(10),
        payload: '/stats',
      ),
      (
        id: 1701,
        title: l10n.notifExploreRecipesTitle('V60'),
        body: l10n.notifExploreRecipesBody(1),
        payload: '/recipes/v60/101',
      ),
      (
        id: 1201,
        title: l10n.notifMorningTitle,
        body: l10n.notifMorningBody,
        payload: 'notif:morning_reminder',
      ),
      (
        id: 1301,
        title: l10n.notifWeeklyTitle(5),
        body: l10n.notifWeeklyBody(3),
        payload: '/stats?period=thisWeek',
      ),
    ];

    return ExpansionTile(
      leading: const Icon(Icons.bug_report, color: Colors.orange),
      title: const Text('Debug: Notifications'),
      subtitle: const Text('Dev build only — fires in 5 s'),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in notifications)
          ListTile(
            title: Text(
              n.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              n.body,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: AppTextButton(
              label: 'Fire',
              onPressed: () => _fireNotification(
                context,
                id: n.id,
                title: n.title,
                body: n.body,
                payload: n.payload,
              ),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            ),
          ),
        ListTile(
          title: Text(
            l10n.notifBeanFreshnessTitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            'Finds most recently roasted bean (5+ days old)',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: AppTextButton(
            label: 'Fire',
            onPressed: () => _fireBeanFreshnessNotification(context),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          ),
        ),
        ListTile(
          title: Text(
            'Bean review nudge',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            'Picks a random bean and fires the review nudge (with logo)',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: AppTextButton(
            label: 'Fire',
            onPressed: () => _fireBeanReviewNudge(context),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          ),
        ),
      ],
    );
  }

  Future<void> _fireBeanReviewNudge(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final database = context.read<AppDatabase>();
    final locale = Localizations.localeOf(context).languageCode;

    try {
      final beans = await database.coffeeBeansDao.fetchAllCoffeeBeans();
      final candidates = beans.where((b) => !b.isDeleted).toList();
      if (candidates.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('No beans available — add a bean first to test.')),
        );
        return;
      }
      final picked = candidates[math.Random().nextInt(candidates.length)];
      final payload = await LocalNotificationSchedulerService.instance
          .debugFireBeanReviewNudge(
        database: database,
        beansUuid: picked.beansUuid,
        locale: locale,
        delay: const Duration(seconds: 5),
      );
      final label = picked.name.isNotEmpty ? picked.name : picked.roaster;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Bean review nudge fires in 5 s for: $label\n$payload'),
          duration: const Duration(seconds: 3),
        ),
      );
      AppLogger.debug('🔔 DEBUG notif: bean review nudge payload=$payload');
    } catch (e) {
      AppLogger.error('Bean review nudge fire failed', errorObject: e);
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _fireBeanFreshnessNotification(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final beansProvider = context.read<CoffeeBeansProvider>();

    final beans = await beansProvider.fetchAllCoffeeBeans();

    CoffeeBeansModel? candidate;
    for (final bean in beans) {
      if (bean.roastDate == null || bean.isDeleted) continue;
      if (bean.packageWeightGrams != null && bean.packageWeightGrams! < 0.1) {
        continue;
      }
      if (DateTime.now().difference(bean.roastDate!).inDays < 5) continue;
      if (candidate == null ||
          bean.roastDate!.isAfter(candidate.roastDate!)) {
        candidate = bean;
      }
    }

    if (candidate == null) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('No beans with roast date > 5 days found')),
      );
      return;
    }

    final beanName =
        candidate.name.isNotEmpty ? candidate.name : candidate.roaster;
    final daysSinceRoast =
        DateTime.now().difference(candidate.roastDate!).inDays;
    final title = l10n.notifBeanFreshnessTitle;
    final body = l10n.notifBeanFreshnessBody(beanName, daysSinceRoast);
    final payload = '/beans/${candidate.beansUuid}';

    final at = DateTime.now().add(const Duration(seconds: 5));
    try {
      await NotificationService.instance.scheduleLocalNotification(
        id: 1401,
        title: title,
        body: body,
        scheduledDate: at,
        payload: payload,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Notification #1401 fires in 5 s\n$payload'),
          duration: const Duration(seconds: 3),
        ),
      );
      AppLogger.debug('🔔 DEBUG notif: id=1401 payload=$payload at=$at');
    } catch (e) {
      AppLogger.error('Debug notification fire failed', errorObject: e);
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _fireNotification(
    BuildContext context, {
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    final at = DateTime.now().add(const Duration(seconds: 5));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationService.instance.scheduleLocalNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: at,
        payload: payload,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Notification #$id fires in 5 s\n$payload'),
          duration: const Duration(seconds: 3),
        ),
      );
      AppLogger.debug('🔔 DEBUG notif: id=$id payload=$payload at=$at');
    } catch (e) {
      AppLogger.error('Debug notification fire failed', errorObject: e);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}
