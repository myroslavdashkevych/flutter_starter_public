import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/repositories/items_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetItemsPageUseCase {
  GetItemsPageUseCase(this._repository);

  final ItemsRepository _repository;

  /// A blank [query] means no search.
  Future<Result<Paginated<Item>>> call({
    required int page,
    String? query,
    bool forceRefresh = false,
  }) {
    final trimmedQuery = query?.trim();
    return _repository.getPage(
      page: page,
      query: trimmedQuery == null || trimmedQuery.isEmpty ? null : trimmedQuery,
      forceRefresh: forceRefresh,
    );
  }
}
