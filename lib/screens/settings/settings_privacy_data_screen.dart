import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/app_switch_list_tile.dart';
import '../../widgets/settings/data_export_section.dart';
import '../../widgets/settings/settings_list.dart';
import '../../widgets/smart_back_button.dart';

/// Privacy & data settings page (Settings → Privacy & data): the three
/// usage-analytics switches, the self-serve data export entry point and the
/// bundled privacy policy.
///
/// Not yet linked from the root Settings screen; reachable by route/deep
/// link only.
@RoutePage()
class SettingsPrivacyDataScreen extends StatelessWidget {
  const SettingsPrivacyDataScreen({super.key});

  // Product decision D6a: nothing is ever reported about the general switch,
  // in either direction — hence no handler-side analytics at all. The brews
  // and beans switches ARE reported, after the change has been applied, so
  // `setting_changed` (category `general`) is dropped by the service's own
  // category check whenever general analytics is off. That is intended; do
  // not work around it.
  Future<void> _setBrews(AnalyticsService analytics, bool value) async {
    final previous = analytics.brewsEnabled;
    await analytics.setBrewsEnabled(value);
    SettingsAnalytics.settingChanged(
      key: SettingKey.analyticsBrews,
      value: SettingsAnalytics.onOff(value),
      previous: SettingsAnalytics.onOff(previous),
      source: SettingSource.settings,
    );
  }

  Future<void> _setBeans(AnalyticsService analytics, bool value) async {
    final previous = analytics.beansEnabled;
    await analytics.setBeansEnabled(value);
    SettingsAnalytics.settingChanged(
      key: SettingKey.analyticsBeans,
      value: SettingsAnalytics.onOff(value),
      previous: SettingsAnalytics.onOff(previous),
      source: SettingSource.settings,
    );
  }

  Future<void> _setGeneral(AnalyticsService analytics, bool value) async {
    await analytics.setGeneralEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analytics = context.watch<AnalyticsService>();

    return SettingsPageScaffold(
      title: l10n.settingsPrivacyDataTitle,
      children: [
        SettingsSectionHeader(title: l10n.settingsUsageAnalyticsHeader),
        Semantics(
          identifier: 'settingsAnalyticsBrewsSwitch',
          container: true,
          child: AppSwitchListTile(
            title: l10n.settingsAnalyticsBrews,
            value: analytics.brewsEnabled,
            onChanged: (value) => _setBrews(analytics, value),
          ),
        ),
        Semantics(
          identifier: 'settingsAnalyticsBeansSwitch',
          container: true,
          child: AppSwitchListTile(
            title: l10n.settingsAnalyticsBeans,
            value: analytics.beansEnabled,
            onChanged: (value) => _setBeans(analytics, value),
          ),
        ),
        Semantics(
          identifier: 'settingsAnalyticsGeneralSwitch',
          container: true,
          child: AppSwitchListTile(
            title: l10n.settingsAnalyticsGeneral,
            value: analytics.generalEnabled,
            onChanged: (value) => _setGeneral(analytics, value),
          ),
        ),
        SettingsSectionHeader(title: l10n.settingsYourDataHeader),
        const DataExportSection(),
        SettingsNavRow(
          identifier: 'settingsPrivacyPolicyRow',
          icon: Icons.privacy_tip_outlined,
          title: l10n.privacyPolicyTitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _PrivacyPolicyPage()),
          ),
        ),
      ],
    );
  }
}

/// Full-screen rendering of the bundled privacy policy document.
///
/// A private page pushed with a plain [MaterialPageRoute] (no AutoRoute): it
/// has no deep link of its own and is only ever reached from this page. The
/// document is the same asset the Info screen shows — web vs. native — but
/// here it scrolls the full height instead of the Info screen's half-screen
/// cap.
class _PrivacyPolicyPage extends StatefulWidget {
  const _PrivacyPolicyPage();

  @override
  State<_PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<_PrivacyPolicyPage> {
  Future<String>? _policy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load once, here rather than in initState: DefaultAssetBundle.of needs
    // an inherited-widget lookup, which initState must not perform.
    _policy ??= DefaultAssetBundle.of(context).loadString(
      kIsWeb
          ? 'assets/data/privacy_policy_web.md'
          : 'assets/data/privacy_policy.md',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'privacyPolicyBackButton',
          button: true,
          container: true,
          child: const SmartBackButton(),
        ),
        title: Text(l10n.privacyPolicyTitle),
      ),
      body: FutureBuilder<String>(
        future: _policy,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Markdown scrolls itself (shrinkWrap defaults to false), so it
            // shows the whole document, not the Info screen's half cap.
            return Markdown(
              data: snapshot.data!,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.base),
              child: Text(l10n.privacyPolicyLoadFailed),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
