import 'dart:io';
import 'package:image/image.dart' as img;

class ImageResizer {
  /// Resize an image file to a max dimension of 1024px while preserving aspect ratio.
  /// Returns the same file path with resized bytes written.
  static Future<File> resizeToMax1024(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return imageFile;

    final resized = img.copyResize(
      decoded,
      width: decoded.width > decoded.height ? 1024 : null,
      height: decoded.height > decoded.width ? 1024 : null,
    );

    final resizedImageFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(resized));
    return resizedImageFile;
  }
}
