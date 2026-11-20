// lib/widgets/roasters/roaster_tile.dart

import 'package:flutter/material.dart';
import 'package:coffee_timer/models/roaster_profile_model.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';

class RoasterTile extends StatelessWidget {
  final RoasterProfileModel roaster;
  final VoidCallback onTap;

  const RoasterTile({
    super.key,
    required this.roaster,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVerified =
        roaster.adminUserId != null && roaster.adminUserId!.isNotEmpty;
    final location = roaster.locationLabel;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Logo container
            SizedBox(
              width: 56,
              height: 56,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: RoasterLogo(
                    placeholderIcon: Icons.storefront_outlined,
                    originalUrl: roaster.roasterLogoUrl,
                    mirrorUrl: roaster.roasterLogoMirrorUrl,
                    height: 48,
                    width: 48,
                    borderRadius: AppRadius.small,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          roaster.roasterName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isVerified) ...[
                        SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.verified,
                          size: AppIconSize.small,
                          color: colorScheme.tertiary,
                        ),
                      ],
                    ],
                  ),
                  if (location != null) ...[
                    SizedBox(height: 2),
                    Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
