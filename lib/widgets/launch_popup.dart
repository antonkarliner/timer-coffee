import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      String filePath = 'assets/data/$locale/startpopup/$currentVersion.json';

      try {
        String jsonString = await loadAsset(filePath);
        String fileContent = jsonDecode(jsonString)['content'];

        if (fileContent.isNotEmpty) {
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
                          child: _buildRichText(context, fileContent),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<String>(
                          future: getVersionNumber(),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '${AppLocalizations.of(context)!.appversion}: ${snapshot.data}',
                                style: const TextStyle(
                                    fontSize: 16.0, color: Colors.grey),
                              );
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
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
      } catch (e) {
        // Log error or handle file not found scenario
        print("Error loading the asset: $e");
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
