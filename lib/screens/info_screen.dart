import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_router.gr.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';

@RoutePage()
class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool _isAnonymous = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isAnonymous = user?.isAnonymous ?? true;
      _userId = user?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snowEffectProvider = Provider.of<SnowEffectProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Text(l10n.about),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Author
          ExpansionTile(
            title: Text(l10n.author),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.authortext,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          // Contributors
          ListTile(
            title: Text(l10n.contributors),
            onTap: () => _launchURL(
                'https://github.com/antonkarliner/timer-coffee/blob/main/CONTRIBUTORS.md'),
          ),
          // License
          ExpansionTile(
            title: Text(l10n.license),
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.licensetext),
                    AppTextButton(
                      label: l10n.licensebutton,
                      onPressed: () => _launchURL(
                          'https://www.gnu.org/licenses/gpl-3.0.html'),
                      isFullWidth: false,
                      height: AppButton.heightSmall,
                      padding: AppButton.paddingSmall,
                      textStyle: AppButton.label
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Privacy Policy
          ExpansionTile(
            title: const Text('Privacy Policy'),
            children: [
              FutureBuilder<String>(
                future: loadPrivacyPolicy(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Markdown(
                            data: snapshot.data!,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context).textTheme.bodyLarge!,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Error loading Privacy Policy'),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ],
          ),
          // Seasonal specials
          ExpansionTile(
            title: Text(l10n.seasonspecials),
            children: [
              ListTile(
                leading: const Icon(Icons.ac_unit),
                title: Text(l10n.snow),
                onTap: () => snowEffectProvider.toggleSnowEffect(),
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text(l10n.holidayGiftBoxTitle),
                onTap: () => context.router.push(const GiftBoxListRoute()),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text('${l10n.yearlyStatsAppBarTitle} – 2024'),
                onTap: () => context.router.push(const YearlyStatsStoryRoute()),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text('${l10n.yearlyStatsAppBarTitle} – 2025'),
                onTap: () =>
                    context.router.push(const YearlyStatsStory25Route()),
              ),
            ],
          ),
          // Links and support
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppElevatedButton(
                        label: l10n.website,
                        onPressed: () => _launchURL('https://www.timer.coffee'),
                        icon: Icons.explore,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        height: AppButton.heightSmall,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppElevatedButton(
                        label: l10n.sourcecode,
                        onPressed: () => _launchURL(
                            'https://github.com/antonkarliner/coffee-timer'),
                        icon: Icons.code,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        height: AppButton.heightSmall,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppElevatedButton(
                        label: 'Instagram',
                        onPressed: () => _launchURL(
                            'https://www.instagram.com/timercoffeeapp'),
                        icon: FontAwesomeIcons.instagram,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        height: AppButton.heightSmall,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppElevatedButton(
                        label: l10n.supportButtonLabel,
                        onPressed: () =>
                            _launchURL('mailto:support@timer.coffee'),
                        icon: Icons.mail_outline,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        height: AppButton.heightSmall,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: IntrinsicWidth(
                    child: AppElevatedButton(
                      label: l10n.support,
                      onPressed: kIsWeb || !Platform.isIOS
                          ? () => _launchURL(
                              'https://www.buymeacoffee.com/timercoffee')
                          : () => context.router.push(const DonationRoute()),
                      icon: Icons.local_cafe,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      height: AppButton.heightSmall,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      isFullWidth: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // App version and build number
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final info = snapshot.data!;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        Text(
                          '${l10n.appversion}: ${info.version}',
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.grey),
                        ),
                        Text(
                          'Build: ${info.buildNumber}',
                          style: const TextStyle(
                              fontSize: 16.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }

  Future<String> loadPrivacyPolicy() async {
    final filePath = kIsWeb
        ? 'assets/data/privacy_policy_web.md'
        : 'assets/data/privacy_policy.md';
    return await DefaultAssetBundle.of(context).loadString(filePath);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(url)),
      );
    }
  }

  void _showDeleteAccountConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          AppTextButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
          AppTextButton(
            label: l10n.deleteAccount,
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Supabase.instance.client.auth.signOut();
      final response = await Supabase.instance.client.functions.invoke(
        'clean-before-deletion',
        body: {'user_id': _userId},
      );
      if (response.status != 200) {
        throw Exception('Failed to clean user data: ${response.data}');
      }
      await Supabase.instance.client.auth.signInAnonymously();
      setState(() {
        _isAnonymous = true;
        _userId = Supabase.instance.client.auth.currentUser?.id;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeletionError)),
      );
    }
  }
}
