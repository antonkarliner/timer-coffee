import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';

/// Stateless bean selection row used in Recipe Detail.
/// All state and side effects (SharedPreferences, providers) must be handled by the caller.
class BeanSelectionRow extends StatelessWidget {
  final String? selectedBeanUuid;
  final String? selectedBeanName;
  final String? originalRoasterLogoUrl;
  final String? mirrorRoasterLogoUrl;

  /// Called when the user taps the button to choose beans.
  final VoidCallback onSelectBeans;

  /// Called when the user taps the clear (cancel) icon.
  final VoidCallback onClearSelection;

  const BeanSelectionRow({
    Key? key,
    required this.selectedBeanUuid,
    required this.selectedBeanName,
    required this.originalRoasterLogoUrl,
    required this.mirrorRoasterLogoUrl,
    required this.onSelectBeans,
    required this.onClearSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Give RoasterLogo a unique key that changes on every bean selection
    final Key? roasterLogoKey = selectedBeanUuid != null
        ? ValueKey(
            selectedBeanUuid! +
                (originalRoasterLogoUrl ?? '') +
                (mirrorRoasterLogoUrl ?? ''),
          )
        : null;

    const double logoHeight = 24.0;
    const double maxWidthFactor = 2.0; // 24 × 2 = 48 px max width

    return Row(
      children: [
        Text('${loc.beans}: ', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: onSelectBeans,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Stack(
              children: [
                Center(
                  child: selectedBeanUuid == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            loc.selectBeans,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (originalRoasterLogoUrl != null ||
                                mirrorRoasterLogoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: logoHeight,
                                  width: logoHeight * maxWidthFactor,
                                  child: RoasterLogo(
                                    key: roasterLogoKey,
                                    originalUrl: originalRoasterLogoUrl,
                                    mirrorUrl: mirrorRoasterLogoUrl,
                                    height: logoHeight,
                                    width: logoHeight * maxWidthFactor,
                                    borderRadius: 4,
                                    forceFit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (originalRoasterLogoUrl != null ||
                                mirrorRoasterLogoUrl != null)
                              const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedBeanName ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                ),
                if (selectedBeanUuid != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: onClearSelection,
                      child: SizedBox(
                        width: 48,
                        child: Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.cancel,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
