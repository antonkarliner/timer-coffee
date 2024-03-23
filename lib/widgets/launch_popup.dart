import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LaunchPopupWidget extends StatefulWidget {
  @override
  _LaunchPopupWidgetState createState() => _LaunchPopupWidgetState();
}

class _LaunchPopupWidgetState extends State<LaunchPopupWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkVersionAndShowPopup();
    });
  }

  void checkVersionAndShowPopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    bool isPopupShown =
        prefs.getBool('popupShownForVersion_$currentVersion') ?? false;

    if (!isPopupShown) {
      String locale = Localizations.localeOf(context).languageCode;
      // Use RecipeProvider to get the start popup
      final startPopup =
          await Provider.of<RecipeProvider>(context, listen: false)
              .fetchStartPopup(currentVersion, locale);

      if (startPopup != null && startPopup.content.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.whatsnewtitle),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 500),
                        child: _buildRichText(context, startPopup.content),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${AppLocalizations.of(context)!.appversion}: $currentVersion',
                        style:
                            const TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.whatsnewclose),
                    onPressed: () {
                      prefs.setBool(
                          'popupShownForVersion_$currentVersion', true);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  Future<String> loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      return ''; // If there's an error loading the file, return an empty string
    }
  }

  Widget _buildRichText(BuildContext context, String text) {
    RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    Iterable<Match> matches = linkRegExp.allMatches(text);

    TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyMedium!;

    if (matches.isNotEmpty) {
      List<TextSpan> spans = [];
      int lastMatchEnd = 0;

      for (Match match in matches) {
        String preText = text.substring(lastMatchEnd, match.start);
        if (preText.isNotEmpty) {
          spans.add(TextSpan(text: preText, style: defaultTextStyle));
        }

        String linkText = match.group(1)!;
        String linkUrl = match.group(2)!;

        if (linkUrl.startsWith("app://")) {
          // Handle internal app navigation
          String routePath = linkUrl.substring(6); // Remove the 'app://' part
          spans.add(
            TextSpan(
              text: linkText,
              style: defaultTextStyle.copyWith(color: Colors.lightBlue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.router.pushNamed(routePath);
                },
            ),
          );
        } else {
          // Handle both external links and mailto links
          spans.add(
            TextSpan(
              text: linkText,
              style: defaultTextStyle.copyWith(color: Colors.lightBlue),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  Uri url = Uri.parse(linkUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    // Handle failure to launch URL
                    // This could be due to a misformatted URL or lack of suitable app to handle the URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch $linkUrl')),
                    );
                  }
                },
            ),
          );
        }

        lastMatchEnd = match.end;
      }

      // Append any remaining text after the last match
      String remainingText = text.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText, style: defaultTextStyle));
      }

      return RichText(text: TextSpan(children: spans));
    } else {
      // If there are no matches, just return the text
      return Text(text, style: defaultTextStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This widget does not need to display anything itself
  }

  Future<String> getVersionNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
