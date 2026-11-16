import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/repository/character_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetCharacterDetailUseCase implements UseCase<Character, ({int id})> {
  GetCharacterDetailUseCase(this._repository);

  final CharacterRepository _repository;

  @override
  Future<Result<Character>> call(({int id}) params) =>
      _repository.getById(params.id);
}
