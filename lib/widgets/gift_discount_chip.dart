import 'package:flutter/material.dart';

import '../models/gift_offer_model.dart';
import '../theme/design_tokens.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class DiscountChipData {
  final String label;
  final Color bg;
  final Color fg;
  const DiscountChipData({required this.label, required this.bg, required this.fg});
}

/// Returns a discount chip widget or null if no discount info is available.
Widget? buildDiscountChip(BuildContext context, GiftOffer offer) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;
  final data = _buildData(offer, theme, l10n);
  if (data == null) return null;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: data.bg,
      borderRadius: BorderRadius.circular(AppRadius.card),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Text(
      data.label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: data.fg,
      ),
    ),
  );
}

DiscountChipData? _buildData(
    GiftOffer offer, ThemeData theme, AppLocalizations l10n) {
  final hasPercent = offer.discountMinPercent != null || offer.discountMaxPercent != null;
  final label = _buildLabel(offer, l10n);
  if (label == null) return null;

  if (hasPercent) {
    final value = offer.discountMaxPercent ?? offer.discountMinPercent ?? 0;
    final bucket = _bucket(value);
    final colors = _percentColors(bucket);
    return DiscountChipData(label: label, bg: colors.bg, fg: colors.fg);
  }

  // Non-percentage text discount
  final bg = theme.colorScheme.primaryContainer;
  final fg = theme.colorScheme.onPrimaryContainer;
  return DiscountChipData(label: label, bg: bg, fg: fg);
}

String? _buildLabel(GiftOffer offer, AppLocalizations l10n) {
  final minP = offer.discountMinPercent;
  final maxP = offer.discountMaxPercent;

  String fmt(num v) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  // Percent logic first (localized via l10n).
  if (minP != null || maxP != null) {
    final value = maxP ?? minP!;
    final percentStr = fmt(value);
    if (minP != null && maxP != null) {
      return l10n.giftDiscountUpToOff(percentStr);
    }
    return l10n.giftDiscountOff(percentStr);
  }

  if (offer.discountText != null && offer.discountText!.trim().isNotEmpty) {
    return offer.discountText!.trim();
  }

  if (offer.discountLabel != null && offer.discountLabel!.trim().isNotEmpty) {
    return offer.discountLabel!;
  }

  return null;
}

int _bucket(double value) {
  if (value >= 30) return 3;
  if (value >= 16) return 2;
  if (value >= 5) return 1;
  return 0; // treat <5% as lowest bucket
}

_ColorPair _percentColors(int bucket) {
  switch (bucket) {
    case 3:
      return _ColorPair(Colors.redAccent.shade200, Colors.white);
    case 2:
      return _ColorPair(const Color(0xFFC26B2B), Colors.white); // copper / orange
    case 1:
      return _ColorPair(const Color(0xFF2E8B57), Colors.white); // green
    default:
      return _ColorPair(Colors.grey.shade300, Colors.black87);
  }
}

class _ColorPair {
  final Color bg;
  final Color fg;
  const _ColorPair(this.bg, this.fg);
}
