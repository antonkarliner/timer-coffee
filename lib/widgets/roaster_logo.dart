// lib/widgets/roaster_logo.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffeico/coffeico.dart'; // Ensure this import is correct based on your project structure

class RoasterLogo extends StatelessWidget {
  final String? originalUrl;
  final String? mirrorUrl;
  final double height;
  final double borderRadius;

  const RoasterLogo({
    Key? key,
    required this.originalUrl,
    required this.mirrorUrl,
    this.height = 40.0,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (originalUrl == null && mirrorUrl == null) {
      return Icon(
        Coffeico.bag_with_bean,
        size: height,
      );
    }

    // Choose the first available URL
    final imageUrl = originalUrl ?? mirrorUrl!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) =>
            Icon(Coffeico.bag_with_bean, size: height),
        errorWidget: (context, url, error) {
          // If originalUrl failed and mirrorUrl exists, try mirrorUrl
          if (url == originalUrl && mirrorUrl != null) {
            return CachedNetworkImage(
              imageUrl: mirrorUrl!,
              placeholder: (context, url) =>
                  Icon(Coffeico.bag_with_bean, size: height),
              errorWidget: (context, url, error) =>
                  Icon(Coffeico.bag_with_bean, size: height),
              height: height,
              fit: BoxFit.contain,
            );
          }
          // If mirror also fails or not available
          return Icon(
            Coffeico.bag_with_bean,
            size: height,
          );
        },
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
