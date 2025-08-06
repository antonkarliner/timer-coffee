import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';

/// Result class for roaster logo fetching operations.
///
/// Encapsulates the success/failure state and provides clear access to logo URLs
/// or error information. This design makes error handling explicit and prevents
/// null-related issues in consuming code.
class RoasterLogoResult {
  /// The original logo URL, if available
  final String? originalUrl;

  /// The mirror logo URL, if available
  final String? mirrorUrl;

  /// Whether the operation was successful
  final bool isSuccess;

  /// Error message if the operation failed
  final String? errorMessage;

  const RoasterLogoResult._({
    this.originalUrl,
    this.mirrorUrl,
    required this.isSuccess,
    this.errorMessage,
  });

  /// Creates a successful result with logo URLs
  factory RoasterLogoResult.success({
    String? originalUrl,
    String? mirrorUrl,
  }) {
    return RoasterLogoResult._(
      originalUrl: originalUrl,
      mirrorUrl: mirrorUrl,
      isSuccess: true,
    );
  }

  /// Creates a failed result with error message
  factory RoasterLogoResult.failure(String errorMessage) {
    return RoasterLogoResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  /// Whether any logo URL is available
  bool get hasAnyLogo => originalUrl != null || mirrorUrl != null;

  /// Whether both logo URLs are available
  bool get hasBothLogos => originalUrl != null && mirrorUrl != null;

  /// Returns the preferred logo URL (original first, then mirror)
  String? get preferredUrl => originalUrl ?? mirrorUrl;
}

/// Service for handling roaster logo fetching operations.
///
/// This service centralizes all roaster logo-related operations including
/// fetching logo URLs with caching, error handling, and result state management.
/// It follows the existing service patterns with provider integration and
/// provides a clean interface for UI components.
///
/// The service is designed to be:
/// - **Reusable**: Can be used across different screens that need roaster logos
/// - **Cacheable**: Leverages DatabaseProvider's built-in caching mechanism
/// - **Error-resilient**: Gracefully handles network failures and missing data
/// - **Type-safe**: Uses explicit result types instead of nullable returns
/// - **Provider-compatible**: Integrates seamlessly with the existing Provider pattern
///
/// Example usage:
/// ```dart
/// final logoService = RoasterLogoService();
/// final result = await logoService.fetchRoasterLogos(context, 'Blue Bottle Coffee');
///
/// if (result.isSuccess && result.hasAnyLogo) {
///   // Use result.originalUrl and result.mirrorUrl
///   RoasterLogo(
///     originalUrl: result.originalUrl,
///     mirrorUrl: result.mirrorUrl,
///   )
/// } else {
///   // Handle error or show fallback
///   Icon(Icons.coffee)
/// }
/// ```
class RoasterLogoService {
  const RoasterLogoService();

  /// Fetches roaster logo URLs for the given roaster name.
  ///
  /// This method leverages the DatabaseProvider's caching mechanism to efficiently
  /// retrieve logo URLs. The cache is handled transparently by the DatabaseProvider,
  /// so subsequent calls for the same roaster will be served from memory.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing the DatabaseProvider
  /// - [roasterName]: The name of the roaster to fetch logos for
  ///
  /// **Returns:**
  /// A [RoasterLogoResult] containing:
  /// - Success state with original and mirror URLs (if available)
  /// - Failure state with error message (if operation failed)
  ///
  /// **Error Handling:**
  /// - Network failures are caught and returned as failure results
  /// - Missing data is handled gracefully (success with null URLs)
  /// - Provider access errors are caught and reported
  ///
  /// **Caching:**
  /// The underlying DatabaseProvider handles caching automatically:
  /// - First call: Fetches from network and caches result
  /// - Subsequent calls: Returns cached result immediately
  /// - Cache key is based on normalized roaster name
  ///
  /// **Example:**
  /// ```dart
  /// final result = await logoService.fetchRoasterLogos(context, 'Stumptown');
  /// if (result.isSuccess) {
  ///   if (result.hasAnyLogo) {
  ///     // Display logo using result.originalUrl or result.mirrorUrl
  ///   } else {
  ///     // No logos available, show fallback
  ///   }
  /// } else {
  ///   // Handle error: result.errorMessage
  /// }
  /// ```
  Future<RoasterLogoResult> fetchRoasterLogos(
    BuildContext context,
    String roasterName,
  ) async {
    try {
      // Validate input
      if (roasterName.trim().isEmpty) {
        return RoasterLogoResult.failure('Roaster name cannot be empty');
      }

      // Access DatabaseProvider through Provider pattern
      final databaseProvider =
          Provider.of<DatabaseProvider>(context, listen: false);

      // Fetch logo URLs using the cached method
      // This leverages DatabaseProvider's built-in caching and error handling
      final logoUrls =
          await databaseProvider.fetchCachedRoasterLogoUrls(roasterName);

      // Extract URLs from the result map
      final originalUrl = logoUrls['original'];
      final mirrorUrl = logoUrls['mirror'];

      // Return successful result with the fetched URLs
      return RoasterLogoResult.success(
        originalUrl: originalUrl,
        mirrorUrl: mirrorUrl,
      );
    } catch (error) {
      // Handle any errors that occur during the operation
      final errorMessage =
          'Failed to fetch roaster logos for "$roasterName": $error';

      // Log error for debugging (in production, consider using a proper logging service)
      debugPrint('RoasterLogoService Error: $errorMessage');

      return RoasterLogoResult.failure(errorMessage);
    }
  }

  /// Checks if logos are available for the given roaster without fetching them.
  ///
  /// This is a convenience method that can be used to determine whether to show
  /// a logo placeholder or attempt to load logos. It uses the same caching
  /// mechanism as [fetchRoasterLogos], so if logos have been fetched before,
  /// this will return immediately from cache.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing the DatabaseProvider
  /// - [roasterName]: The name of the roaster to check
  ///
  /// **Returns:**
  /// A [Future<bool>] indicating whether any logos are available
  ///
  /// **Note:** This method will trigger a network request if the roaster
  /// hasn't been cached yet. For pure cache-only checks, additional
  /// methods could be added to DatabaseProvider.
  ///
  /// **Example:**
  /// ```dart
  /// final hasLogos = await logoService.hasLogosAvailable(context, 'Blue Bottle');
  /// if (hasLogos) {
  ///   // Proceed to fetch and display logos
  /// } else {
  ///   // Show fallback immediately
  /// }
  /// ```
  Future<bool> hasLogosAvailable(
    BuildContext context,
    String roasterName,
  ) async {
    try {
      final result = await fetchRoasterLogos(context, roasterName);
      return result.isSuccess && result.hasAnyLogo;
    } catch (error) {
      // If there's an error checking availability, assume no logos
      debugPrint(
          'RoasterLogoService: Error checking logo availability for "$roasterName": $error');
      return false;
    }
  }

  /// Fetches logos for multiple roasters in parallel.
  ///
  /// This method is useful when you need to fetch logos for multiple roasters
  /// simultaneously, such as in a list view. It leverages Dart's concurrent
  /// execution to improve performance.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing the DatabaseProvider
  /// - [roasterNames]: List of roaster names to fetch logos for
  ///
  /// **Returns:**
  /// A [Map<String, RoasterLogoResult>] where keys are roaster names and
  /// values are the corresponding logo results
  ///
  /// **Performance:**
  /// - Requests are executed concurrently using Future.wait
  /// - Cached results are returned immediately
  /// - Failed requests don't block successful ones
  ///
  /// **Example:**
  /// ```dart
  /// final roasters = ['Stumptown', 'Blue Bottle', 'Intelligentsia'];
  /// final results = await logoService.fetchMultipleRoasterLogos(context, roasters);
  ///
  /// for (final entry in results.entries) {
  ///   final roasterName = entry.key;
  ///   final result = entry.value;
  ///   if (result.isSuccess && result.hasAnyLogo) {
  ///     // Display logo for this roaster
  ///   }
  /// }
  /// ```
  Future<Map<String, RoasterLogoResult>> fetchMultipleRoasterLogos(
    BuildContext context,
    List<String> roasterNames,
  ) async {
    try {
      // Remove duplicates and empty names
      final uniqueRoasters =
          roasterNames.where((name) => name.trim().isNotEmpty).toSet().toList();

      if (uniqueRoasters.isEmpty) {
        return {};
      }

      // Fetch all logos concurrently
      final futures = uniqueRoasters
          .map((roasterName) => fetchRoasterLogos(context, roasterName));

      final results = await Future.wait(futures);

      // Build result map
      final resultMap = <String, RoasterLogoResult>{};
      for (int i = 0; i < uniqueRoasters.length; i++) {
        resultMap[uniqueRoasters[i]] = results[i];
      }

      return resultMap;
    } catch (error) {
      debugPrint(
          'RoasterLogoService: Error fetching multiple roaster logos: $error');

      // Return failure results for all requested roasters
      final errorResult =
          RoasterLogoResult.failure('Batch fetch failed: $error');
      return Map.fromEntries(
          roasterNames.map((name) => MapEntry(name, errorResult)));
    }
  }
}
