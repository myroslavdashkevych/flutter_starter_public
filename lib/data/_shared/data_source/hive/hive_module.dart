import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

@module
abstract class HiveModule {
  @lazySingleton
  HiveInterface get hive => Hive;
}
