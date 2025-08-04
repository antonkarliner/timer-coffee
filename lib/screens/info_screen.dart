import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_router.gr.dart';

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
                    TextButton(
                      onPressed: () => _launchURL(
                          'https://www.gnu.org/licenses/gpl-3.0.html'),
                      child: Text(
                        l10n.licensebutton,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
                leading: const Icon(Icons.calendar_month),
                title: Text('${l10n.yearlyStatsAppBarTitle} – 2024'),
                onTap: () => context.router.push(const YearlyStatsStoryRoute()),
              ),
            ],
          ),
          // Links and support
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0,
              runSpacing: 2.0,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchURL('https://www.timer.coffee'),
                  icon: const Icon(Icons.explore),
                  label: Text(l10n.website),
                ),
                ElevatedButton.icon(
                  onPressed: () => _launchURL(
                      'https://github.com/antonkarliner/coffee-timer'),
                  icon: const Icon(Icons.code),
                  label: Text(l10n.sourcecode),
                ),
                if (kIsWeb || !Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _launchURL('https://www.buymeacoffee.com/timercoffee'),
                    icon: const Icon(Icons.local_cafe),
                    label: Text(l10n.support),
                  ),
                if (!kIsWeb && Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: () => context.router.push(const DonationRoute()),
                    icon: const Icon(Icons.local_cafe),
                    label: Text(l10n.support),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // App version
          FutureBuilder<String>(
            future: getVersionNumber(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      '${l10n.appversion}: ${snapshot.data}',
                      style:
                          const TextStyle(fontSize: 16.0, color: Colors.grey),
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

  Future<String> getVersionNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(l10n.deleteAccount),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
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
