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
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final snowEffectProvider = Provider.of<SnowEffectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'settingsBackButton',
          child: const BackButton(),
        ),
        title: Semantics(
          identifier: 'settingsTitle',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.settings),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          Semantics(
            identifier: 'settingsThemeTile',
            child: ListTile(
              title: Text(AppLocalizations.of(context)!.settingstheme),
              trailing: Text(_getLocalizedThemeModeText()),
              onTap: _changeTheme,
            ),
          ),
          Semantics(
            identifier: 'settingsLangTile',
            child: ListTile(
              title: Text(AppLocalizations.of(context)!.settingslang),
              trailing: FutureBuilder<String>(
                future: _getLanguageName(recipeProvider.currentLocale),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              onTap: _changeLocale,
            ),
          ),
          _buildAboutSection(context, snowEffectProvider),
        ],
      ),
    );
  }

  Widget _buildAboutSection(
      BuildContext context, SnowEffectProvider snowEffectProvider) {
    return Semantics(
      identifier: 'aboutSection',
      child: Column(
        children: [
          Semantics(
            identifier: 'authorExpansionTile',
            child: ExpansionTile(
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
          ),
          Semantics(
            identifier: 'contributorsExpansionTile',
            child: ExpansionTile(
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
                        child: Text(AppLocalizations.of(context)!
                            .errorLoadingContributors),
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
          ),
          Semantics(
            identifier: 'licenseExpansionTile',
            child: ExpansionTile(
              title: Text(AppLocalizations.of(context)!.license),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.licensetext),
                      TextButton(
                        onPressed: () => _launchURL(
                            'https://www.gnu.org/licenses/gpl-3.0.html'),
                        child: Text(
                          AppLocalizations.of(context)!.licensebutton,
                          style: const TextStyle(
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            identifier: 'privacyPolicyExpansionTile',
            child: ExpansionTile(
              title: const Text('Privacy Policy'),
              children: <Widget>[
                FutureBuilder<String>(
                  future: loadPrivacyPolicy(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
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
          ),
          Semantics(
            identifier: 'accountManagementExpansionTile',
            child: ExpansionTile(
              title: Text(AppLocalizations.of(context)!.accountManagement),
              children: [
                Semantics(
                  identifier: 'deleteAccountListTile',
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.deleteAccount),
                    enabled: !_isAnonymous,
                    onTap: _showDeleteAccountConfirmation,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            identifier: 'seasonSpecialsExpansionTile',
            child: ExpansionTile(
              title: Text(AppLocalizations.of(context)!.seasonspecials),
              children: [
                Semantics(
                  identifier: 'snowListTile',
                  child: ListTile(
                    leading: const Icon(Icons.ac_unit),
                    title: Text(AppLocalizations.of(context)!.snow),
                    onTap: () => snowEffectProvider.toggleSnowEffect(),
                  ),
                ),
                Semantics(
                  identifier: 'snowListTile',
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(
                      '${AppLocalizations.of(context)!.yearlyStatsAppBarTitle} – 2024',
                    ),
                    onTap: () {
                      context.router.push(const YearlyStatsStoryRoute());
                    },
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.0,
            runSpacing: 2.0,
            children: [
              Semantics(
                identifier: 'websiteButton',
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL('https://www.timer.coffee'),
                  icon: const Icon(Icons.explore),
                  label: Text(AppLocalizations.of(context)!.website),
                ),
              ),
              Semantics(
                identifier: 'sourceCodeButton',
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(
                      'https://github.com/antonkarliner/coffee-timer'),
                  icon: const Icon(Icons.code),
                  label: Text(AppLocalizations.of(context)!.sourcecode),
                ),
              ),
              if (kIsWeb || !Platform.isIOS)
                Semantics(
                  identifier: 'supportNonIOSButton',
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _launchURL('https://www.buymeacoffee.com/timercoffee'),
                    icon: const Icon(Icons.local_cafe),
                    label: Text(AppLocalizations.of(context)!.support),
                  ),
                ),
              if (!kIsWeb && Platform.isIOS)
                Semantics(
                  identifier: 'supportIOSButton',
                  child: ElevatedButton.icon(
                    onPressed: () => context.router.push(const DonationRoute()),
                    icon: const Icon(Icons.local_cafe),
                    label: Text(AppLocalizations.of(context)!.support),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            identifier: 'appVersionText',
            child: FutureBuilder<String>(
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
          ),
        ],
      ),
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
              Semantics(
                identifier: 'themeLightListTile',
                child: ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: Text(AppLocalizations.of(context)!.settingsthemelight),
                  onTap: () => Navigator.pop(context, ThemeMode.light),
                ),
              ),
              Semantics(
                identifier: 'themeDarkListTile',
                child: ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: Text(AppLocalizations.of(context)!.settingsthemedark),
                  onTap: () => Navigator.pop(context, ThemeMode.dark),
                ),
              ),
              Semantics(
                identifier: 'themeSystemListTile',
                child: ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title:
                      Text(AppLocalizations.of(context)!.settingsthemesystem),
                  onTap: () => Navigator.pop(context, ThemeMode.system),
                ),
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
              return Semantics(
                identifier: 'locale${localeModel.locale}ListTile',
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localeModel.localeName),
                  onTap: () =>
                      Navigator.pop(context, Locale(localeModel.locale)),
                ),
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
        return AppLocalizations.of(context)!.settingsthemesystem;
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

    final RegExp linkRegExp = RegExp(r'\[(@?.*?)\]\((.*?)\)');

    for (final contributor in contributors) {
      final Iterable<RegExpMatch> matches =
          linkRegExp.allMatches(contributor.content);
      int lastMatchEnd = 0;

      for (final match in matches) {
        final String precedingText =
            contributor.content.substring(lastMatchEnd, match.start);
        if (precedingText.isNotEmpty) {
          spanList.add(TextSpan(text: precedingText, style: defaultStyle));
        }

        final String linkText = match.group(1)!;
        final String url = match.group(2)!;

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

      final String remainingText = contributor.content.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        final String formattedRemainingText =
            (remainingText.startsWith(' ') || remainingText.startsWith('\n'))
                ? remainingText
                : ' $remainingText';
        spanList
            .add(TextSpan(text: formattedRemainingText, style: defaultStyle));
      }

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

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteAccountTitle),
          content: Text(AppLocalizations.of(context)!.deleteAccountWarning),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.deleteAccount),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      // Sign out the current user
      await Supabase.instance.client.auth.signOut();

      // Call the clean-before-deletion function
      final response = await Supabase.instance.client.functions.invoke(
        'clean-before-deletion',
        body: {'user_id': _userId},
      );

      if (response.status != 200) {
        throw Exception('Failed to clean user data: ${response.data}');
      }

      // Sign in anonymously
      await Supabase.instance.client.auth.signInAnonymously();

      // Update state
      setState(() {
        _isAnonymous = true;
        _userId = Supabase.instance.client.auth.currentUser?.id;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.accountDeleted)),
      );
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.accountDeletionError)),
      );
    }
  }
}
