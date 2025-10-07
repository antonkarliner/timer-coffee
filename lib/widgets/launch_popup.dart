import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure correct import path
import 'package:flutter_markdown/flutter_markdown.dart';

class LaunchPopupWidget extends StatefulWidget {
  @override
  _LaunchPopupWidgetState createState() => _LaunchPopupWidgetState();
}

class _LaunchPopupWidgetState extends State<LaunchPopupWidget> {
  // Session-only guard to prevent multiple dialogs in the same app run
  static bool _shownThisSession = false;

  // Determine whether the given platform target (from the popup model)
  // matches the current runtime/platform. If the platform is null treat as
  // "all" (show everywhere). Normalizes common names.
  bool _platformMatches(String? platform) {
    if (platform == null) return true;
    final normalized = platform.trim().toLowerCase();
    if (normalized == 'all') return true;

    if (kIsWeb) {
      return normalized == 'web';
    } else {
      // Use TargetPlatform (web-safe) instead of dart:io's Platform.
      if (defaultTargetPlatform == TargetPlatform.iOS)
        return normalized == 'ios';
      if (defaultTargetPlatform == TargetPlatform.android)
        return normalized == 'android';
      // Other non-web platforms are not targeted specifically; only 'all' will show
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForNewPopup();
    });
  }

  void checkForNewPopup() async {
    // Session guard: prevent duplicates during the same app run
    if (_shownThisSession) return;

    final prefs = await SharedPreferences.getInstance();
    final locale = Localizations.localeOf(context).languageCode;

    // Fetch latest popup (remote-first via provider)
    final popup = await Provider.of<RecipeProvider>(context, listen: false)
        .fetchLatestLaunchPopup(locale);

    if (popup == null) return; // nothing to show
    // Platform gating: skip popups that don't target this platform
    if (!_platformMatches(popup.platform)) return;

    final idKey = 'lastPopupId_$locale';
    final legacyDateKey = 'lastPopupDate_$locale';

    final savedId = prefs.getInt(idKey);
    // If we've already saved the id, nothing to do
    if (savedId != null && savedId == popup.id) return;

    // Legacy migration: if user had seen same popup by createdAt date, mark id and skip
    final legacyDate = prefs.getString(legacyDateKey);
    if (savedId == null && legacyDate != null) {
      final currentPopupDate = popup.createdAt.toIso8601String();
      if (legacyDate == currentPopupDate) {
        await prefs.setInt(idKey, popup.id);
        return;
      }
    }

    if (!mounted) return;

    // Set session guard before showing to avoid racing rebuilds
    _shownThisSession = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.whatsnewtitle),
          content: SingleChildScrollView(
            child: _buildMarkdown(context, popup.content),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.whatsnewclose,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                await prefs.setInt(idKey, popup.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarkdown(BuildContext context, String data) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium;
    final linkColor = Colors.lightBlue;

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: baseStyle,
      a: baseStyle?.copyWith(color: linkColor),
    );

    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      selectable: false,
      softLineBreak: true,
      onTapLink: (text, href, title) async {
        if (href == null) return;
        if (href.startsWith('app://')) {
          final routePath = href.substring(6);
          if (mounted) {
            context.router.pushPath(routePath);
          }
          return;
        }
        // External or mailto links
        final uri = Uri.parse(href);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch $href')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This widget does not need to display anything itself
  }
}
