import 'dart:io';

import 'package:coffee_timer/models/contributor_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import '../providers/snow_provider.dart';

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
    final snowEffectProvider = Provider.of<SnowEffectProvider>(context);

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
            trailing: FutureBuilder<String>(
              future: _getLanguageName(recipeProvider.currentLocale),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot
                      .data!); // Display the dynamically fetched locale name
                } else {
                  return const CircularProgressIndicator(); // Show loading indicator while fetching
                }
              },
            ),
            onTap: _changeLocale,
          ),

          _buildAboutSection(context, Provider.of<SnowEffectProvider>(context)),
          // Add more settings options here if needed
        ],
      ),
    );
  }

  Widget _buildAboutSection(
      BuildContext context, SnowEffectProvider snowEffectProvider) {
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
            FutureBuilder<List<ContributorModel>>(
              future: Provider.of<RecipeProvider>(context, listen: false)
                  .fetchAllContributorsForCurrentLocale(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<ContributorModel>> snapshot) {
                if (snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildRichText(context, snapshot.data!),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        AppLocalizations.of(context)!.errorLoadingContributors),
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
        ExpansionTile(
          title: Text(AppLocalizations.of(context)!.seasonspecials),
          children: [
            ListTile(
                leading: const Icon(Icons.ac_unit),
                title: Text(AppLocalizations.of(context)!.snow),
                onTap: () {
                  snowEffectProvider
                      .toggleSnowEffect(); // This calls the function
                }),
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
                leading: const Icon(Icons.light_mode),
                title: Text(AppLocalizations.of(context)!.settingsthemelight),
                onTap: () => Navigator.pop(context, ThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(AppLocalizations.of(context)!.settingsthemedark),
                onTap: () => Navigator.pop(context, ThemeMode.dark),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_medium),
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
    final supportedLocales =
        await Provider.of<RecipeProvider>(context, listen: false)
            .fetchAllSupportedLocales();

    final result = await showModalBottomSheet<Locale>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: supportedLocales.length,
            itemBuilder: (BuildContext context, int index) {
              final localeModel = supportedLocales[index];
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(localeModel.localeName),
                onTap: () => Navigator.pop(context, Locale(localeModel.locale)),
              );
            },
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

  Future<String> _getLanguageName(Locale locale) async {
    return Provider.of<RecipeProvider>(context, listen: false)
        .getLocaleName(locale.languageCode);
  }

  void _setLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.toString());

    Provider.of<RecipeProvider>(context, listen: false).setLocale(newLocale);

    context.router.replace(const SettingsRoute());
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

  Widget _buildRichText(
      BuildContext context, List<ContributorModel> contributors) {
    List<TextSpan> spanList = [];
    final TextStyle defaultStyle = Theme.of(context).textTheme.bodyLarge!;
    final TextStyle linkStyle = const TextStyle(color: Colors.blue);

    // Define the RegExp here
    final RegExp linkRegExp = RegExp(r'\[(@?.*?)\]\((.*?)\)');

    for (final contributor in contributors) {
      final Iterable<RegExpMatch> matches =
          linkRegExp.allMatches(contributor.content);
      int lastMatchEnd = 0;

      for (final match in matches) {
        // Text before the link
        final String precedingText =
            contributor.content.substring(lastMatchEnd, match.start);
        if (precedingText.isNotEmpty) {
          spanList.add(TextSpan(text: precedingText, style: defaultStyle));
        }

        // Extract link text and URL
        final String linkText = match.group(1)!;
        final String url = match.group(2)!;

        // Add link TextSpan
        spanList.add(TextSpan(
          text: linkText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
        ));

        lastMatchEnd = match.end;
      }

      // Handle text after the last link or if no links are present
      final String remainingText = contributor.content.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        // Insert a space if the remaining text does not start with a space or newline
        final String formattedRemainingText =
            (remainingText.startsWith(' ') || remainingText.startsWith('\n'))
                ? remainingText
                : ' $remainingText';
        spanList
            .add(TextSpan(text: formattedRemainingText, style: defaultStyle));
      }

      // Add a newline for separation between entries
      spanList.add(const TextSpan(text: '\n\n'));
    }

    return RichText(text: TextSpan(children: spanList, style: defaultStyle));
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }
}
