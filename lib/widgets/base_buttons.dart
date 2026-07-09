import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AppElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double? elevation;
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
    this.iconWidget,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.elevation,
    this.height,
    this.width,
    this.padding,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedForegroundColor =
        foregroundColor ?? theme.colorScheme.onPrimary;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: resolvedForegroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      minimumSize: width != null
          ? Size(width!, height ?? AppButton.heightMedium)
          : (isFullWidth
              ? Size(double.infinity, height ?? AppButton.heightMedium)
              : Size(0, height ?? AppButton.heightMedium)),
      padding: padding ?? AppButton.paddingMedium,
      elevation: elevation ?? AppButton.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppButton.radius),
      ),
      textStyle: AppButton.label,
    );

    final labelChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(resolvedForegroundColor),
            ),
          )
        : Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
          );

    if (iconWidget != null) {
      return ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget!,
            const SizedBox(width: 8),
            isLoading ? labelChild : Flexible(child: labelChild),
          ],
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            isLoading ? labelChild : Flexible(child: labelChild),
          ],
        ),
      );
    }

    return ElevatedButton(
      style: buttonStyle,
      onPressed: isLoading ? null : onPressed,
      child: labelChild,
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? foregroundColor;
  final TextStyle? textStyle;
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
    this.textStyle,
    this.height,
    this.width,
    this.padding,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedForegroundColor =
        foregroundColor ?? theme.colorScheme.primary;

    final buttonStyle = TextButton.styleFrom(
      foregroundColor: resolvedForegroundColor,
      minimumSize: width != null
          ? Size(width!, height ?? AppButton.heightMedium)
          : (isFullWidth
              ? Size(double.infinity, height ?? AppButton.heightMedium)
              : Size(0, height ?? AppButton.heightMedium)),
      padding: padding ?? AppButton.paddingMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppButton.radius),
      ),
      textStyle: textStyle ?? AppButton.label,
    );

    final labelChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(resolvedForegroundColor),
            ),
          )
        : Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
          );

    if (icon != null) {
      return TextButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            isLoading ? labelChild : Flexible(child: labelChild),
          ],
        ),
      );
    }

    return TextButton(
      style: buttonStyle,
      onPressed: isLoading ? null : onPressed,
      child: labelChild,
    );
  }
}
