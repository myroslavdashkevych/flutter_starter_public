import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';

abstract interface class CharacterRepository {
  Future<Result<Paginated<Character>>> getPage({
    required int page,
    String? query,
    bool forceRefresh = false,
  });

  Future<Result<Character>> getById(int id);
}
