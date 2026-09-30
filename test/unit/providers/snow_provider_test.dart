import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The provider loads fire-and-forget in its constructor; let the pending
  // SharedPreferences futures settle before asserting.
  Future<void> drain() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to off with no stored value', () async {
    final provider = SnowEffectProvider();
    await drain();

    expect(provider.isSnowing, isFalse);
  });

  test('loads true from prefs', () async {
    SharedPreferences.setMockInitialValues({SnowEffectProvider.prefKey: true});
    final provider = SnowEffectProvider();
    await drain();

    expect(provider.isSnowing, isTrue);
  });

  test('load notifies listeners when the stored value differs', () async {
    SharedPreferences.setMockInitialValues({SnowEffectProvider.prefKey: true});
    final provider = SnowEffectProvider();
    var notified = 0;
    provider.addListener(() => notified++);
    await drain();

    expect(notified, 1);
  });

  test('load stays silent when the stored value matches the default',
      () async {
    final provider = SnowEffectProvider();
    var notified = 0;
    provider.addListener(() => notified++);
    await drain();

    expect(notified, 0);
  });

  test('setSnowEffect persists', () async {
    final provider = SnowEffectProvider();
    await drain();

    await provider.setSnowEffect(true);

    expect(provider.isSnowing, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SnowEffectProvider.prefKey), isTrue);
  });

  test('toggleSnowEffect persists', () async {
    SharedPreferences.setMockInitialValues({SnowEffectProvider.prefKey: true});
    final provider = SnowEffectProvider();
    await drain();

    await provider.toggleSnowEffect();

    expect(provider.isSnowing, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SnowEffectProvider.prefKey), isFalse);
  });

  test('setSnowEffect with an unchanged value does not notify', () async {
    final provider = SnowEffectProvider();
    await drain();
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.setSnowEffect(false);

    expect(notified, 0);
  });

  test('a set that races the startup load wins over the stored value',
      () async {
    SharedPreferences.setMockInitialValues({SnowEffectProvider.prefKey: false});
    final provider = SnowEffectProvider();
    // The user's set lands before the constructor's async load resolves.
    await provider.setSnowEffect(true);
    await drain();

    expect(provider.isSnowing, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SnowEffectProvider.prefKey), isTrue);
  });
}
