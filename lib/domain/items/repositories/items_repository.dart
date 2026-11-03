import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';

abstract class ItemsRepository {
  Future<Result<Paginated<Item>>> getPage({
    required int page,
    String? query,
    bool forceRefresh = false,
  });

  Future<Result<Item>> getById(int id);
}
