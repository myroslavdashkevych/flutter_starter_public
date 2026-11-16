import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/repository/character_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetCharacterPageUseCase
    implements
        UseCase<
          Paginated<Character>,
          ({int page, String? query, bool forceRefresh})
        > {
  GetCharacterPageUseCase(this._repository);

  final CharacterRepository _repository;

  /// A blank `query` means no search.
  @override
  Future<Result<Paginated<Character>>> call(
    ({int page, String? query, bool forceRefresh}) params,
  ) {
    final trimmedQuery = params.query?.trim();
    return _repository.getPage(
      page: params.page,
      query: trimmedQuery == null || trimmedQuery.isEmpty ? null : trimmedQuery,
      forceRefresh: params.forceRefresh,
    );
  }
}
