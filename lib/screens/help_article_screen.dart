import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';

import '../models/help_models.dart';
import '../providers/database_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../widgets/smart_back_button.dart';

@RoutePage()
class HelpArticleScreen extends StatefulWidget {
  final String slug;
  final String? title;

  const HelpArticleScreen({
    super.key,
    @PathParam('slug') required this.slug,
    this.title,
  });

  @override
  State<HelpArticleScreen> createState() => _HelpArticleScreenState();
}

class _HelpArticleScreenState extends State<HelpArticleScreen> {
  HelpArticleModel? _article;
  bool _loading = true;
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale == null || _lastLocale != locale) {
      _lastLocale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(locale));
    }
  }

  Future<void> _load(Locale locale) async {
    setState(() => _loading = true);
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final article = await db.getHelpArticle(widget.slug, locale.languageCode);
    if (!mounted) return;
    setState(() {
      _article = article;
      _loading = false;
    });
  }

  Future<void> _onTapLink(String? href) async {
    if (href == null) return;
    if (href.startsWith('app://')) {
      context.router.pushPath(href.substring(6));
      return;
    }
    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Text(widget.title ?? _article?.title ?? l10n.helpAndFAQ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final article = _article;
    if (article == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.helpEmptyState,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          Center(
            child: AppElevatedButton(
              label: l10n.helpRetry,
              onPressed: () => _load(Localizations.localeOf(context)),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
          ),
        ],
      );
    }
    return Markdown(
      data: article.body,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.lg,
      ),
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        a: AppTextStyles.body.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: theme.colorScheme.primary,
        ),
        p: AppTextStyles.body.copyWith(height: 1.5),
        pPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        h1: AppTextStyles.headline,
        h1Padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.base,
        ),
        h2: AppTextStyles.title,
        h2Padding: const EdgeInsets.only(
          top: AppSpacing.base,
          bottom: AppSpacing.sm,
        ),
        h3: AppTextStyles.fieldLabel,
        h3Padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        blockSpacing: AppSpacing.base,
        listIndent: AppSpacing.lg,
        listBullet: AppTextStyles.body,
        listBulletPadding: const EdgeInsets.only(right: AppSpacing.sm),
      ),
      softLineBreak: true,
      onTapLink: (text, href, title) => _onTapLink(href),
      sizedImageBuilder: (config) {
        final alt = config.alt?.trim();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: CachedNetworkImage(
              imageUrl: config.uri.toString(),
              width: config.width,
              height: config.height,
              imageBuilder: (context, imageProvider) {
                final image = Image(
                  image: imageProvider,
                  width: config.width,
                  height: config.height,
                );
                if (alt == null || alt.isEmpty) return image;
                return Semantics(
                  image: true,
                  label: alt,
                  child: ExcludeSemantics(child: image),
                );
              },
              placeholder: (context, url) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.base),
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Semantics(
                label: l10n.helpImageLoadFailed,
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          size: AppIconSize.large,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.helpImageLoadFailed,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
