import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/utils/version_vector.dart';

void main() {
  group('construction', () {
    test('creates with given device and version', () {
      final v = VersionVector('device-1', 5);
      expect(v.deviceId, 'device-1');
      expect(v.version, 5);
    });

    test('initial factory creates version 1', () {
      final v = VersionVector.initial('device-1');
      expect(v.deviceId, 'device-1');
      expect(v.version, 1);
    });

    test('legacy factory creates legacy marker', () {
      final v = VersionVector.legacy();
      expect(v.isLegacy, isTrue);
    });

    test('non-legacy is not legacy', () {
      final v = VersionVector('device-1', 1);
      expect(v.isLegacy, isFalse);
    });
  });

  group('increment', () {
    test('increments version by 1', () {
      final v = VersionVector('device-1', 3);
      final incremented = v.increment();
      expect(incremented.deviceId, 'device-1');
      expect(incremented.version, 4);
    });

    test('legacy increment generates new deviceId with version 1', () {
      final v = VersionVector.legacy();
      final incremented = v.increment();
      expect(incremented.isLegacy, isFalse);
      expect(incremented.version, 1);
      expect(incremented.deviceId, isNotEmpty);
    });

    test('increment does not mutate original', () {
      final v = VersionVector('device-1', 3);
      v.increment();
      expect(v.version, 3);
    });
  });

  group('merge', () {
    test('takes maximum version from same device', () {
      final a = VersionVector('device-1', 5);
      final b = VersionVector('device-1', 3);
      final merged = VersionVector.merge(a, b);
      expect(merged.version, 5);
      expect(merged.deviceId, 'device-1');
    });

    test('merge is commutative', () {
      final a = VersionVector('device-1', 5);
      final b = VersionVector('device-1', 3);
      expect(VersionVector.merge(a, b), equals(VersionVector.merge(b, a)));
    });

    test('throws on different device IDs', () {
      final a = VersionVector('device-1', 1);
      final b = VersionVector('device-2', 1);
      expect(() => VersionVector.merge(a, b), throwsArgumentError);
    });

    test('merging equal versions returns same version', () {
      final a = VersionVector('device-1', 4);
      final b = VersionVector('device-1', 4);
      expect(VersionVector.merge(a, b).version, 4);
    });
  });

  group('isNewerThan', () {
    test('higher version is newer', () {
      final newer = VersionVector('device-1', 5);
      final older = VersionVector('device-1', 3);
      expect(newer.isNewerThan(older), isTrue);
    });

    test('lower version is not newer', () {
      final older = VersionVector('device-1', 3);
      final newer = VersionVector('device-1', 5);
      expect(older.isNewerThan(newer), isFalse);
    });

    test('same version on different device uses lexicographic order', () {
      final z = VersionVector('z-device', 1);
      final a = VersionVector('a-device', 1);
      expect(z.isNewerThan(a), isTrue);
      expect(a.isNewerThan(z), isFalse);
    });

    test('same version and same device is not newer', () {
      final a = VersionVector('device-1', 3);
      final b = VersionVector('device-1', 3);
      expect(a.isNewerThan(b), isFalse);
    });
  });

  group('serialization', () {
    test('toString produces JSON with device and version', () {
      final v = VersionVector('device-1', 5);
      final json = v.toString();
      expect(json, contains('device-1'));
      expect(json, contains('5'));
    });

    test('fromString round-trips correctly', () {
      final original = VersionVector('device-1', 42);
      final deserialized = VersionVector.fromString(original.toString());
      expect(deserialized, equals(original));
    });

    test('fromJson round-trips correctly', () {
      final original = VersionVector('device-1', 7);
      final deserialized = VersionVector.fromJson(original.toJson());
      expect(deserialized, equals(original));
    });

    test('initial factory round-trips through JSON', () {
      final v = VersionVector.initial('my-device');
      final restored = VersionVector.fromString(v.toString());
      expect(restored.deviceId, 'my-device');
      expect(restored.version, 1);
    });
  });

  group('equality', () {
    test('same deviceId and version are equal', () {
      final a = VersionVector('device-1', 3);
      final b = VersionVector('device-1', 3);
      expect(a, equals(b));
    });

    test('different version are not equal', () {
      final a = VersionVector('device-1', 3);
      final b = VersionVector('device-1', 4);
      expect(a, isNot(equals(b)));
    });

    test('different deviceId are not equal', () {
      final a = VersionVector('device-1', 3);
      final b = VersionVector('device-2', 3);
      expect(a, isNot(equals(b)));
    });
  });
}
