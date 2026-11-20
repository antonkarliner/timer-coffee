import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'coffee_beans/coffee_bean_card.dart';
import 'roaster_logo.dart';

/// One in-stock bean as its own card — the shared container for the Hub's
/// "For you" picks and the roaster profile's "In stock now" section (plan
/// 017 phase 5d). Built like [BrewEntryCard]'s container so a pick reads as
/// its own entity, the way a brew diary entry does. Inside the roaster
/// section, which is already a card, it renders [embedded]: the same content
/// flat, so no shadowed card sits inside another (plan 088).
///
/// A dumb presentational widget on purpose: every string, image URL and
/// callback comes from the caller, which also decides which actions exist.
class StockBeanCard extends StatelessWidget {
  const StockBeanCard({
    super.key,
    required this.title,
    this.subtitle,
    this.body,
    this.imageUrl,
    this.logoUrl,
    this.logoMirrorUrl,
    this.actions = const <Widget>[],
    this.onTap,
    this.semanticsIdentifier,
    this.embedded = false,
  });

  /// Bean name. At most two lines.
  final String title;

  /// Secondary line (roaster, origin, markers). At most one line.
  final String? subtitle;

  /// Optional body text (a pick's reason). At most four lines.
  final String? body;

  /// The bean's product photo. Used only when it is a non-empty http/https
  /// URL; anything else falls back to [logoUrl]/[logoMirrorUrl] or the
  /// storefront placeholder. Loaded without Supabase URL rewriting — these
  /// are the roaster's own external images.
  final String? imageUrl;

  /// Roaster logo fallbacks for when there is no (working) photo.
  final String? logoUrl;
  final String? logoMirrorUrl;

  /// Trailing action buttons, aligned with the text. Callers wrap theirs in
  /// [AppTextButton] (48 dp minimum height ≥ the 44 dp tap target).
  final List<Widget> actions;

  /// Tap on the card itself (outside any action button).
  final VoidCallback? onTap;

  /// Semantic identifier for the whole card.
  final String? semanticsIdentifier;

  /// Fixed per call site. When true, renders a flat listing inside a
  /// container that is already a card.
  final bool embedded;

  /// Whether [imageUrl] is a usable product photo: non-empty http/https.
  static bool hasHttpImageUrl(String? raw) {
    if (raw == null) return false;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final listing = InkWell(
      onTap: onTap,
      borderRadius: embedded ? BorderRadius.circular(AppRadius.small) : null,
      child: Padding(
        padding: embedded
            ? const EdgeInsets.symmetric(vertical: AppSpacing.sm)
            : const EdgeInsets.all(AppSpacing.cardPadding),
        child: _buildContent(context),
      ),
    );
    return Semantics(
      identifier: semanticsIdentifier,
      child: embedded
          ? listing
          : Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              clipBehavior: Clip.antiAlias,
              child: listing,
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Photo beside the name; the reason and the actions run the full
    // width underneath. Beside an 80 pt photo a 140-character reason
    // was cut off after four short lines.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StockPhotoSlot(
              imageUrl: imageUrl,
              logoUrl: logoUrl,
              logoMirrorUrl: logoMirrorUrl,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.itemTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (body != null && body!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            body!,
            style: AppTextStyles.body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Wrap, not Row: localized action labels together can exceed
        // a 320 pt row and must wrap onto a second line.
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: actions,
          ),
        ],
      ],
    );
  }
}

/// The card's square leading slot: the product photo when usable, otherwise
/// the roaster logo, otherwise a storefront icon.
class _StockPhotoSlot extends StatelessWidget {
  const _StockPhotoSlot({
    required this.imageUrl,
    required this.logoUrl,
    required this.logoMirrorUrl,
  });

  final String? imageUrl;
  final String? logoUrl;
  final String? logoMirrorUrl;

  @override
  Widget build(BuildContext context) {
    final size = CoffeeBeanCard.photoSlotSize;
    final hasLogo = logoUrl != null || logoMirrorUrl != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: SizedBox(
        width: size,
        height: size,
        child: StockBeanCard.hasHttpImageUrl(imageUrl)
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Loading: a neutral box — no spinner.
                placeholder: (context, url) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                // Error: the roaster logo, or the storefront placeholder.
                errorWidget: (context, url, error) =>
                    hasLogo ? _logo(size) : _placeholder(context, size),
              )
            : hasLogo
                ? _logo(size)
                : _placeholder(context, size),
      ),
    );
  }

  Widget _logo(double size) => RoasterLogo(
        originalUrl: logoUrl,
        mirrorUrl: logoMirrorUrl,
        placeholderIcon: Icons.storefront_outlined,
        height: size,
        width: size,
        borderRadius: AppRadius.small,
        forceFit: BoxFit.contain,
      );

  Widget _placeholder(BuildContext context, double size) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.storefront_outlined,
          size: AppIconSize.medium,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}
