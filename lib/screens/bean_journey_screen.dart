import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_view.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class BeanJourneyScreen extends StatefulWidget {
  const BeanJourneyScreen({
    super.key,
    @PathParam('beanId') required this.beanUuid,
  });

  final String beanUuid;

  @override
  State<BeanJourneyScreen> createState() => _BeanJourneyScreenState();
}

class _BeanJourneyScreenState extends State<BeanJourneyScreen> {
  late Future<DiaryGroup?> _groupFuture;
  String? _loadedLocale;
  String? _logoRoaster;
  Future<Map<String, String?>>? _logoUrls;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_loadedLocale != locale) {
      _loadedLocale = locale;
      _groupFuture = _loadGroup(locale);
    }
  }

  Future<DiaryGroup?> _loadGroup(String locale) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final loadedEntries = await context
          .read<UserStatProvider>()
          .fetchDiaryEntries(locale);
      final entries = [
        for (final entry in loadedEntries)
          if (entry.recipeName.isEmpty)
            entry.copyWith(recipeName: loc.unknownRecipe)
          else
            entry,
      ];
      final requestedUuid = widget.beanUuid.trim();
      for (final group in DiaryGroup.build(entries)) {
        if (group.key == requestedUuid) return group;
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load bean Journey',
        errorObject: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, String?>>? _groupLogoUrls(DiaryGroup group) {
    final roaster = group.roaster?.trim();
    if (roaster == null || roaster.isEmpty) return null;
    if (_logoRoaster != roaster) {
      _logoRoaster = roaster;
      _logoUrls = context.read<DatabaseProvider>().fetchCachedRoasterLogoUrls(
        roaster,
      );
    }
    return _logoUrls;
  }

  void _openBeanRecord(DiaryGroup group) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.router.replace(CoffeeBeansDetailRoute(uuid: group.key));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<DiaryGroup?>(
      future: _groupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _JourneyShell(
            title: loc.beanJourneyTitle,
            child: const CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return _JourneyShell(
            title: loc.beanJourneyTitle,
            child: Text(loc.diaryLoadError, textAlign: TextAlign.center),
          );
        }
        final group = snapshot.data;
        if (group == null) {
          return _JourneyShell(
            title: loc.beanJourneyTitle,
            child: Text(loc.beanJourneyNoBrews, textAlign: TextAlign.center),
          );
        }
        return JourneyView(
          group: group,
          logoUrls: _groupLogoUrls(group),
          onBeanTap: () => _openBeanRecord(group),
        );
      },
    );
  }
}

class _JourneyShell extends StatelessWidget {
  const _JourneyShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const SmartBackButton(), title: Text(title)),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}
