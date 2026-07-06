import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('withValues preserves RGB channels and requested alpha', () {
    const base = Color.fromARGB(255, 18, 52, 86);
    const tolerance = 1e-10;

    final migrated = base.withValues(alpha: 0.55);

    expect(migrated.r, closeTo(base.r, tolerance));
    expect(migrated.g, closeTo(base.g, tolerance));
    expect(migrated.b, closeTo(base.b, tolerance));
    expect(migrated.a, closeTo(0.55, tolerance));
  });

  test('production Dart sources do not use deprecated withOpacity', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => file.readAsStringSync().contains('.withOpacity('))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
