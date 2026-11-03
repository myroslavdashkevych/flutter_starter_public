import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/data/items/repositories/items_repository_impl.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ItemsModule {
  @Named(itemsCacheTtlName)
  Duration itemsCacheTtl(AppConfig config) =>
      Duration(minutes: config.itemsCacheTtlMinutes);
}
