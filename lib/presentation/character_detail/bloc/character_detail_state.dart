import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_detail_state.freezed.dart';

@freezed
sealed class CharacterDetailState with _$CharacterDetailState {
  const factory CharacterDetailState.loading() = CharacterDetailLoading;

  const factory CharacterDetailState.loaded(Character character) =
      CharacterDetailLoaded;

  const factory CharacterDetailState.failure(Failure failure) =
      CharacterDetailFailed;
}
