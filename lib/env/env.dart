import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(obfuscate: true, useConstantCase: true)
  static final String supaUrl = _Env.supaUrl;

  @EnviedField(obfuscate: true, useConstantCase: true)
  static final String supaKey = _Env.supaKey;

  @EnviedField(obfuscate: true, useConstantCase: true)
  static final String oneSignalAppId = _Env.oneSignalAppId;

  @EnviedField(obfuscate: true, useConstantCase: true)
  static final String bannerCountry = _Env.bannerCountry;
}
