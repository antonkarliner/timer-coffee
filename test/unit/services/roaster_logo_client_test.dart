import 'dart:typed_data';

import 'package:coffee_timer/services/roaster_logo_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enforces byte limits while reading a streamed logo', () async {
    final response = http.StreamedResponse(
      Stream.fromIterable([
        [1, 2],
        [3],
      ]),
      200,
    );
    await expectLater(
      RoasterLogoClient.readBounded(response, limit: 2),
      throwsFormatException,
    );
  });

  test('normalizes ordinary raster logos on this renderer', () async {
    final original = img.Image(width: 600, height: 300);
    final png = Uint8List.fromList(img.encodePng(original));

    final decoded = img.decodePng(await RoasterLogoClient.normalizedRaster(png));

    expect(decoded?.width, 512);
    expect(decoded?.height, 256);
  });
}
