import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AppElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool isFullWidth;

  const AppElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.width,
    this.padding,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        minimumSize: width != null
            ? Size(width!, height ?? AppButton.heightMedium)
            : (isFullWidth
                ? Size(double.infinity, height ?? AppButton.heightMedium)
                : Size.fromHeight(height ?? AppButton.heightMedium)),
        padding: padding ?? AppButton.paddingMedium,
        elevation: AppButton.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppButton.radius),
        ),
        textStyle: AppButton.label,
      ),
      onPressed: isLoading ? null : onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? foregroundColor;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool isFullWidth;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.foregroundColor,
    this.height,
    this.width,
    this.padding,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? theme.colorScheme.primary,
        minimumSize: width != null
            ? Size(width!, height ?? AppButton.heightMedium)
            : (isFullWidth
                ? Size(double.infinity, height ?? AppButton.heightMedium)
                : Size.fromHeight(height ?? AppButton.heightMedium)),
        padding: padding ?? AppButton.paddingMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppButton.radius),
        ),
        textStyle: AppButton.label,
      ),
      onPressed: isLoading ? null : onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
