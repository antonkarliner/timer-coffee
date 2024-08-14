import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';

class VersionVector {
  final String deviceId;
  final int version;

  static const String _legacyDeviceId = 'legacy';
  static const int _legacyVersion = 0;

  VersionVector(this.deviceId, this.version);

  factory VersionVector.fromJson(Map<String, dynamic> json) {
    return VersionVector(json['deviceId'], json['version']);
  }

  factory VersionVector.legacy() {
    return VersionVector(_legacyDeviceId, _legacyVersion);
  }

  factory VersionVector.initial(String deviceId) {
    return VersionVector(deviceId, 1);
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'version': version,
      };

  bool get isLegacy => deviceId == _legacyDeviceId && version == _legacyVersion;

  VersionVector increment() {
    if (isLegacy) {
      // Generate a new UUID for the device ID when upgrading from legacy
      String newDeviceId = Uuid().v4();
      return VersionVector(newDeviceId, 1);
    }
    return VersionVector(deviceId, version + 1);
  }

  static VersionVector merge(VersionVector a, VersionVector b) {
    if (a.deviceId != b.deviceId) {
      throw ArgumentError(
          'Cannot merge version vectors from different devices');
    }
    return VersionVector(a.deviceId, max(a.version, b.version));
  }

  @override
  String toString() {
    return json.encode(toJson());
  }

  static VersionVector fromString(String str) {
    return VersionVector.fromJson(json.decode(str));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionVector &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          version == other.version;

  @override
  int get hashCode => deviceId.hashCode ^ version.hashCode;
}
