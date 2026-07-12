/// Result class for parallel image processing operations
/// Contains all data needed for the image processing pipeline
class ImageProcessingResult {
  /// Base64 encoded image data for sending to Edge function
  final String base64Image;

  /// Original file name for logging and identification
  final String fileName;

  /// Whether processing was successful
  final bool success;

  /// Error message if processing failed
  final String? error;

  /// Performance metrics for this specific image
  final Map<String, dynamic> performanceMetrics;

  /// Image index in the original input array
  final int imageIndex;

  const ImageProcessingResult({
    required this.base64Image,
    required this.fileName,
    required this.success,
    required this.imageIndex,
    this.error,
    this.performanceMetrics = const {},
  });

  /// Create a successful result
  factory ImageProcessingResult.success({
    required String base64Image,
    required String fileName,
    required int imageIndex,
    Map<String, dynamic> performanceMetrics = const {},
  }) {
    return ImageProcessingResult(
      base64Image: base64Image,
      fileName: fileName,
      success: true,
      imageIndex: imageIndex,
      performanceMetrics: performanceMetrics,
    );
  }

  /// Create a failed result
  factory ImageProcessingResult.failure({
    required String fileName,
    required int imageIndex,
    required String error,
    Map<String, dynamic> performanceMetrics = const {},
  }) {
    return ImageProcessingResult(
      base64Image: '', // Empty base64 for failed images
      fileName: fileName,
      success: false,
      imageIndex: imageIndex,
      error: error,
      performanceMetrics: performanceMetrics,
    );
  }

  @override
  String toString() {
    return 'ImageProcessingResult(fileName: $fileName, success: $success, error: $error)';
  }
}
