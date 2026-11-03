import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/repositories/items_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetItemDetailsUseCase {
  GetItemDetailsUseCase(this._repository);

  final ItemsRepository _repository;

  Future<Result<Item>> call(int id) => _repository.getById(id);
}
