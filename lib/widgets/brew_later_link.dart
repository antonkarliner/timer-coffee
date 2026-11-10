import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_stat_provider.dart';
import '../services/analytics_service.dart';
import '../services/date_time_format_service.dart';
import '../services/local_notification_scheduler_service.dart';
import '../services/notification_ask_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import 'base_buttons.dart';
import 'fields/time_field.dart';

/// The minimum gap between "now" and the reminder fire time. Earlier today
/// slots that don't leave this much room roll to tomorrow.
const _minimumLeadTime = Duration(minutes: 30);

/// The next occurrence of [time] that is at least 30 minutes after [now]:
/// today when the chosen time still qualifies, otherwise tomorrow. Built with
/// the [DateTime] constructor (not `add`) so DST transitions keep the
/// wall-clock time.
DateTime brewLaterFireTime(DateTime now, TimeOfDay time) {
  final today = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (!today.isBefore(now.add(_minimumLeadTime))) return today;
  return DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
}

/// Formats a fire time for display, respecting the user's 24-hour preference
/// ([DateTimeFormatService]) before the device default.
String _formatTime(BuildContext context, DateTime fireAt) {
  final fmtSvc = Provider.of<DateTimeFormatService>(context, listen: false);
  final is24h = fmtSvc.use24Hour(MediaQuery.of(context).alwaysUse24HourFormat);
  return DateFormat(is24h ? 'HH:mm' : 'hh:mm a').format(fireAt);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ---------------------------------------------------------------------------
// Injectable collaborator types — the production defaults talk to the
// scheduler/notification singletons; tests pass fakes instead.
// ---------------------------------------------------------------------------

/// Returns true when the link may be shown (no logged brew yet, not web).
typedef BrewLaterEligibilityLoader = Future<bool> Function();

typedef BrewLaterPendingReader = Future<
    ({String recipeId, String methodId, DateTime fireAt})?> Function();

typedef BrewLaterReminderSetter = Future<bool> Function({
  required String recipeId,
  required String methodId,
  required DateTime fireAt,
  required String source,
  required String locale,
  required String recipeName,
});

typedef BrewLaterReminderCanceller = Future<void> Function(
    {required String reason});

/// True when notifications are already usable (OS permission granted AND the
/// in-app master toggle on) — no permission request needed.
typedef BrewLaterPermissionCheck = Future<bool> Function();

/// OS prompt + master-toggle enable; false when not granted.
typedef BrewLaterPermissionRequest = Future<bool> Function();

/// The time the sheet starts from when the morning reminder is not available.
typedef BrewLaterDefaultTimeLoader = Future<TimeOfDay> Function();

enum _BrewLaterPhase { loading, hidden, idle, set }

/// "Remind me later" link (plan 065, Phase 6b). Shown on recipe detail and
/// preparation only for brand-new users (zero logged brews); opens a bottom
/// sheet that schedules a one-shot "brew later" reminder through
/// [LocalNotificationSchedulerService.setBrewLater].
///
/// The outer [Semantics] slot is stable across every phase (loading, hidden,
/// idle, set): only its child changes, so no tree position changes type when
/// the async eligibility/pending state arrives.
class BrewLaterLink extends StatefulWidget {
  const BrewLaterLink({
    super.key,
    required this.recipeId,
    required this.methodId,
    required this.recipeName,
    required this.source,
    this.loadIsEligible,
    this.readPending,
    this.setReminder,
    this.cancelReminder,
    this.checkPermissionUsable,
    this.requestPermission,
    this.defaultTime,
    this.now,
  });

  final String recipeId;
  final String methodId;
  final String recipeName;

  /// `'recipe_detail'` or `'preparation'` — carried on all brew_later events.
  final String source;

  /// The rest are test seams; each defaults to its production collaborator.
  final BrewLaterEligibilityLoader? loadIsEligible;
  final BrewLaterPendingReader? readPending;
  final BrewLaterReminderSetter? setReminder;
  final BrewLaterReminderCanceller? cancelReminder;
  final BrewLaterPermissionCheck? checkPermissionUsable;
  final BrewLaterPermissionRequest? requestPermission;
  final BrewLaterDefaultTimeLoader? defaultTime;
  final DateTime Function()? now;

  @override
  State<BrewLaterLink> createState() => _BrewLaterLinkState();
}

class _BrewLaterLinkState extends State<BrewLaterLink> {
  _BrewLaterPhase _phase = _BrewLaterPhase.loading;
  ({String recipeId, String methodId, DateTime fireAt})? _pending;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(BrewLaterLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The recipe detail screen can swap the id after an import resolves.
    if (oldWidget.recipeId != widget.recipeId) {
      _refresh(checkEligibility: false);
    }
  }

  Future<bool> _loadIsEligible() async {
    final loader = widget.loadIsEligible;
    if (loader != null) return loader();
    if (kIsWeb) return false;
    try {
      // Provider lookup happens before the first await — no context use
      // across an async gap.
      final dao = Provider.of<UserStatProvider>(context, listen: false)
          .db
          .userStatsDao;
      // Cheapest existing "any brew?" read: a LIMIT 1 query over user_stats.
      final earliest = await dao.earliestBrewAt();
      return earliest == null;
    } catch (e) {
      AppLogger.debug('Brew-later eligibility check failed: $e');
      return false;
    }
  }

  Future<({String recipeId, String methodId, DateTime fireAt})?>
      _readPending() {
    final reader = widget.readPending;
    if (reader != null) return reader();
    return LocalNotificationSchedulerService.instance.pendingBrewLater();
  }

  Future<void> _refresh({bool checkEligibility = true}) async {
    if (checkEligibility) {
      final eligible = await _loadIsEligible();
      if (!mounted) return;
      if (!eligible) {
        setState(() {
          _phase = _BrewLaterPhase.hidden;
          _pending = null;
        });
        return;
      }
    }
    final pending = await _readPending();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      // A pending reminder for a different recipe still shows the idle link.
      _phase = pending != null && pending.recipeId == widget.recipeId
          ? _BrewLaterPhase.set
          : _BrewLaterPhase.idle;
    });
  }

  Future<void> _openSheet() async {
    // Captured before the await — the link's context dies with it.
    final locale = Localizations.localeOf(context).languageCode;
    AnalyticsService.maybeInstance?.track(
      'brew_later_tapped',
      properties: {
        'source': widget.source,
        'recipe_id': widget.recipeId,
        'state': _phase == _BrewLaterPhase.set ? 'set' : 'idle',
      },
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // The content still scrolls if a large text scale outgrows the screen.
      isScrollControlled: true,
      builder: (sheetContext) => _BrewLaterSheet(
        recipeId: widget.recipeId,
        methodId: widget.methodId,
        recipeName: widget.recipeName,
        source: widget.source,
        locale: locale,
        startInSetState:
            _phase == _BrewLaterPhase.set && _pending != null,
        pendingFireAt: _pending?.fireAt,
        setReminder: widget.setReminder ?? _defaultSetReminder,
        cancelReminder: widget.cancelReminder ?? _defaultCancelReminder,
        checkPermissionUsable:
            widget.checkPermissionUsable ?? _defaultCheckPermissionUsable,
        requestPermission: widget.requestPermission ?? _defaultRequestPermission,
        defaultTime: widget.defaultTime ?? _defaultSheetDefaultTime,
        now: widget.now ?? DateTime.now,
      ),
    );
    if (!mounted) return;
    // Reload the pending state so the label reflects what the sheet did.
    await _refresh(checkEligibility: false);
  }

  Future<bool> _defaultSetReminder({
    required String recipeId,
    required String methodId,
    required DateTime fireAt,
    required String source,
    required String locale,
    required String recipeName,
  }) =>
      LocalNotificationSchedulerService.instance.setBrewLater(
        recipeId: recipeId,
        methodId: methodId,
        fireAt: fireAt,
        source: source,
        locale: locale,
        recipeName: recipeName,
      );

  Future<void> _defaultCancelReminder({required String reason}) =>
      LocalNotificationSchedulerService.instance.cancelBrewLater(
        reason: reason,
      );

  Future<bool> _defaultCheckPermissionUsable() async {
    final service = NotificationService.instance;
    final granted = await service.permissions.hasNotificationPermission;
    if (!granted) return false;
    return service.settings.isMasterEnabled();
  }

  Future<bool> _defaultRequestPermission() async {
    final askService = NotificationAskService(
      prefs: await SharedPreferences.getInstance(),
    );
    return askService.requestSystemPermissionAndEnable();
  }

  Future<TimeOfDay> _defaultSheetDefaultTime() async {
    final settings = NotificationSettingsService.instance;
    if (await settings.isMorningReminderEnabled()) {
      return settings.getMorningReminderTime();
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _phase == _BrewLaterPhase.idle || _phase == _BrewLaterPhase.set;
    return Semantics(
      identifier: 'brewLaterLink',
      // Stable slot: the same Semantics position every frame; when the link
      // is not shown it holds a SizedBox.shrink().
      child: visible
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: AppTextButton(
                label: _label(context),
                icon: Icons.alarm,
                isFullWidth: false,
                onPressed: _openSheet,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = _pending;
    if (_phase == _BrewLaterPhase.set && pending != null) {
      return l10n.brewLaterLinkSet(_formatTime(context, pending.fireAt));
    }
    return l10n.brewLaterLink;
  }
}

// ---------------------------------------------------------------------------
// The sheet
// ---------------------------------------------------------------------------

class _BrewLaterSheet extends StatefulWidget {
  const _BrewLaterSheet({
    required this.recipeId,
    required this.methodId,
    required this.recipeName,
    required this.source,
    required this.locale,
    required this.startInSetState,
    required this.pendingFireAt,
    required this.setReminder,
    required this.cancelReminder,
    required this.checkPermissionUsable,
    required this.requestPermission,
    required this.defaultTime,
    required this.now,
  });

  final String recipeId;
  final String methodId;
  final String recipeName;
  final String source;
  final String locale;
  final bool startInSetState;
  final DateTime? pendingFireAt;
  final BrewLaterReminderSetter setReminder;
  final BrewLaterReminderCanceller cancelReminder;
  final BrewLaterPermissionCheck checkPermissionUsable;
  final BrewLaterPermissionRequest requestPermission;
  final BrewLaterDefaultTimeLoader defaultTime;
  final DateTime Function() now;

  @override
  State<_BrewLaterSheet> createState() => _BrewLaterSheetState();
}

class _BrewLaterSheetState extends State<_BrewLaterSheet> {
  // Written so the first-brew permission dialog never leads to an OS prompt
  // iOS would no longer show (see NotificationAskService._legacyKey).
  static const _abShownKey = 'notif_perm_ab_shown';

  late TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _inFlight = false;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultTime();
  }

  Future<void> _loadDefaultTime() async {
    final time = await widget.defaultTime();
    if (!mounted) return;
    setState(() => _selectedTime = time);
  }

  DateTime get _fireAt => brewLaterFireTime(widget.now(), _selectedTime);

  /// "Today at …" / "Tomorrow at …" for the currently resolved fire time.
  String _whenLabel(BuildContext context, AppLocalizations l10n) {
    final fireAt = _fireAt;
    final label = _formatTime(context, fireAt);
    return _isSameDay(fireAt, widget.now())
        ? l10n.brewLaterToday(label)
        : l10n.brewLaterTomorrow(label);
  }

  Future<void> _pickTime() async {
    final fmtSvc =
        Provider.of<DateTimeFormatService>(context, listen: false);
    final is24h =
        fmtSvc.use24Hour(MediaQuery.of(context).alwaysUse24HourFormat);
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _selectedTime,
      use24HourFormat: is24h,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  Future<void> _confirm() async {
    if (_inFlight) return;
    setState(() => _inFlight = true);
    try {
      final usable = await widget.checkPermissionUsable();
      var permission = 'already_granted';
      if (!usable) {
        // No second explanatory dialog — this sheet is the explanation.
        AnalyticsService.maybeInstance?.track(
          'notification_permission_shown',
          properties: {'source': 'brew_later'},
        );
        final ok = await widget.requestPermission();
        AnalyticsService.maybeInstance?.track(
          'notification_permission_result',
          properties: {
            'source': 'brew_later',
            'result': ok ? 'granted' : 'denied',
          },
        );
        if (!ok) {
          await _onPermissionDenied();
          return;
        }
        permission = 'granted_now';
      }

      final fireAt = brewLaterFireTime(widget.now(), _selectedTime);
      final scheduled = await widget.setReminder(
        recipeId: widget.recipeId,
        methodId: widget.methodId,
        fireAt: fireAt,
        source: widget.source,
        locale: widget.locale,
        recipeName: widget.recipeName,
      );
      if (!scheduled) {
        if (!mounted) return;
        setState(() => _denied = true);
        return;
      }

      AnalyticsService.maybeInstance?.track(
        'brew_later_scheduled',
        properties: {
          'source': widget.source,
          'recipe_id': widget.recipeId,
          'hours_ahead':
              (fireAt.difference(widget.now()).inMinutes / 60).round(),
          'permission': permission,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted && !_denied) {
        setState(() => _inFlight = false);
      }
    }
  }

  Future<void> _onPermissionDenied() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_abShownKey, true);
    } catch (e) {
      AppLogger.debug('Failed to persist $_abShownKey: $e');
    }
    AnalyticsService.maybeInstance?.track(
      'brew_later_permission_denied',
      properties: {
        'source': widget.source,
        'recipe_id': widget.recipeId,
      },
    );
    if (!mounted) return;
    setState(() {
      _denied = true;
      _inFlight = false;
    });
  }

  Future<void> _cancelReminder() async {
    await widget.cancelReminder(reason: 'user');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Mirrors the notifications settings page: the exact notification pane
  /// first, the general app settings as a fallback.
  Future<void> _openSystemNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      AppLogger.error('Error opening notification settings', errorObject: e);
      try {
        await AppSettings.openAppSettings();
      } catch (fallbackError) {
        AppLogger.error(
          'Error opening general app settings',
          errorObject: fallbackError,
        );
      }
    }
  }

  void _openSettingsAndClose() {
    Navigator.of(context).pop();
    _openSystemNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final List<Widget> children;
    if (_denied) {
      children = [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(l10n.brewLaterDenied, style: AppTextStyles.body),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Semantics(
            identifier: 'brewLaterOpenSettingsButton',
            child: AppElevatedButton(
              label: l10n.brewLaterOpenSettings,
              onPressed: _openSettingsAndClose,
            ),
          ),
        ),
      ];
    } else if (widget.startInSetState && widget.pendingFireAt != null) {
      final fireAt = widget.pendingFireAt!;
      final label = _formatTime(context, fireAt);
      final whenLine = _isSameDay(fireAt, widget.now())
          ? l10n.brewLaterToday(label)
          : l10n.brewLaterTomorrow(label);
      children = [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(whenLine, style: AppTextStyles.body),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Semantics(
            identifier: 'brewLaterCancelButton',
            child: AppTextButton(
              label: l10n.brewLaterCancel,
              onPressed: _cancelReminder,
            ),
          ),
        ),
      ];
    } else {
      children = [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(l10n.brewLaterSheetBody, style: AppTextStyles.body),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          identifier: 'brewLaterTimeRow',
          child: InkWell(
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.base,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.brewLaterTimeLabel, style: AppTextStyles.body),
                  Text(
                    _whenLabel(context, l10n),
                    style: AppTextStyles.body
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Semantics(
            identifier: 'brewLaterConfirmButton',
            child: AppElevatedButton(
              label: l10n.brewLaterConfirm,
              // In-flight guard so a double tap cannot fire two permission
              // requests.
              onPressed: _inFlight ? null : _confirm,
            ),
          ),
        ),
      ];
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Text(l10n.brewLaterSheetTitle, style: AppTextStyles.title),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}
