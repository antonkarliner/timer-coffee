import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    String currentLanguage = _getLanguageName(recipeProvider.currentLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingstheme),
            trailing: Text(_getLocalizedThemeModeText()),
            onTap: _changeTheme,
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingslang),
            trailing: Text(currentLanguage),
            onTap: _changeLocale,
          ),

          _buildAboutSection(context),
          // Add more settings options here if needed
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        // Author, Contributors, License, and other sections from AboutScreen
        ExpansionTile(
          title: Text(AppLocalizations.of(context)!.author),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.authortext,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text(AppLocalizations.of(context)!.contributors),
          children: <Widget>[
            FutureBuilder<String>(
              future: loadContributors(Localizations.localeOf(context)),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      height: 300, // Adjust as necessary
                      child: Markdown(
                        data: snapshot.data!,
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(context).textTheme.bodyLarge!,
                        ),
                        onTapLink: (text, url, title) => _launchURL(url!),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      AppLocalizations.of(context)!.errorLoadingContributors,
                    ),
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
        ExpansionTile(
          title: Text(AppLocalizations.of(context)!.license),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.licensetext),
                  TextButton(
                    onPressed: () =>
                        _launchURL('https://www.gnu.org/licenses/gpl-3.0.html'),
                    child: Text(
                      AppLocalizations.of(context)!.licensebutton,
                      style:
                          const TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('Privacy Policy'),
          children: <Widget>[
            FutureBuilder<String>(
              future: loadPrivacyPolicy(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Set a maximum height for the Markdown content
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0, // space between buttons
          runSpacing: 2.0, // space between lines
          children: [
            ElevatedButton.icon(
              onPressed: () => _launchURL('https://www.timer.coffee'),
              icon: const Icon(Icons.explore),
              label: Text(AppLocalizations.of(context)!.website),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  _launchURL('https://github.com/antonkarliner/coffee-timer'),
              icon: const Icon(Icons.code),
              label: Text(AppLocalizations.of(context)!.sourcecode),
            ),
            if (kIsWeb ||
                !Platform.isIOS) // Existing condition for non-iOS platforms
              ElevatedButton.icon(
                onPressed: () =>
                    _launchURL('https://www.buymeacoffee.com/timercoffee'),
                icon: const Icon(Icons.local_cafe),
                label: Text(AppLocalizations.of(context)!.support),
              ),
            if (!kIsWeb && Platform.isIOS) // New condition specifically for iOS
              ElevatedButton.icon(
                onPressed: () {
                  context.router
                      .push(const DonationRoute()); // Your routing logic
                },
                icon: const Icon(Icons.local_cafe),
                label: Text(AppLocalizations.of(context)!.support),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FutureBuilder<String>(
          future: getVersionNumber(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return Text(
                '${AppLocalizations.of(context)!.appversion}: ${snapshot.data}',
                style: const TextStyle(fontSize: 16.0, color: Colors.grey),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ],
    );
  }

  void _changeTheme() async {
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                title: Text(AppLocalizations.of(context)!.settingsthemelight),
                onTap: () => Navigator.pop(context, ThemeMode.light),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.settingsthemedark),
                onTap: () => Navigator.pop(context, ThemeMode.dark),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.settingsthemesystem),
                onTap: () => Navigator.pop(context, ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      Provider.of<ThemeProvider>(context, listen: false).setThemeMode(result);
    }
  }

  void _changeLocale() async {
    final result = await showModalBottomSheet<Locale>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('English'),
                onTap: () => Navigator.pop(context, const Locale('en')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Español'), // Spanish
                onTap: () => Navigator.pop(context, const Locale('es')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Português'), // Portuguese
                onTap: () => Navigator.pop(context, const Locale('pt')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Deutsch'), // German
                onTap: () => Navigator.pop(context, const Locale('de')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Français'), // French
                onTap: () => Navigator.pop(context, const Locale('fr')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Русский'), // Russian
                onTap: () => Navigator.pop(context, const Locale('ru')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Polski'), // Polish
                onTap: () => Navigator.pop(context, const Locale('pl')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('العربية'), // Arabic
                trailing: const Badge(
                  label: Text('Beta', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.brown,
                ),
                onTap: () => Navigator.pop(context, const Locale('ar')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('中文'), // Chinese
                trailing: const Badge(
                  label: Text('Beta', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.brown,
                ),
                onTap: () => Navigator.pop(context, const Locale('zh')),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('日本語'), // Japanese
                trailing: const Badge(
                  label: Text('Beta', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.brown,
                ),
                onTap: () => Navigator.pop(context, const Locale('ja')),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      _setLocale(result);
    }
  }

  String _getLocalizedThemeModeText() {
    var themeMode =
        Provider.of<ThemeProvider>(context, listen: false).themeMode;
    switch (themeMode) {
      case ThemeMode.light:
        return AppLocalizations.of(context)!.settingsthemelight;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.settingsthemedark;
      case ThemeMode.system:
        return AppLocalizations.of(context)!.settingsthemesystem;
      default:
        return AppLocalizations.of(context)!
            .settingsthemesystem; // Default case
    }
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'ru':
        return 'Русский';
      case 'pl':
        return 'Polski';
      case 'ar':
        return 'العربية';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return 'Unknown';
    }
  }

  void _setLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.toString());

    Provider.of<RecipeProvider>(context, listen: false).setLocale(newLocale);

    context.router.replace(const SettingsRoute());
  }

  Future<String> loadContributors(Locale locale) async {
    String localePath = locale.languageCode; // 'en', 'ru', etc.
    String filePath = 'assets/data/$localePath/CONTRIBUTORS.md';
    return await rootBundle.loadString(filePath);
  }

  Future<String> loadPrivacyPolicy() async {
    String filePath = kIsWeb
        ? 'assets/data/privacy_policy_web.md'
        : 'assets/data/privacy_policy.md';
    return await rootBundle.loadString(filePath);
  }

  Future<String> getVersionNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }
}
