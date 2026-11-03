import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class StorageModule {
  @lazySingleton
  SharedPreferencesAsync get sharedPreferences => SharedPreferencesAsync();

  @lazySingleton
  HiveInterface get hive => Hive;
}
