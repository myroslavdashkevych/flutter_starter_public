import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/data/character/character_repository_impl.dart';
import 'package:injectable/injectable.dart';

@module
abstract class CharacterModule {
  @Named(characterCacheTtlName)
  Duration characterCacheTtl(AppConfig config) =>
      Duration(minutes: config.characterCacheTtlMinutes);
}
