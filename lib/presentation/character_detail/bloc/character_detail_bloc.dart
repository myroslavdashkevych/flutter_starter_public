import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_detail_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_character_opened_use_case.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_event.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class CharacterDetailBloc
    extends Bloc<CharacterDetailEvent, CharacterDetailState> {
  CharacterDetailBloc(this._getCharacterDetail, this._trackCharacterOpened)
    : super(const CharacterDetailState.loading()) {
    on<CharacterDetailLoad>(_onLoad, transformer: restartable());
  }

  final GetCharacterDetailUseCase _getCharacterDetail;
  final TrackCharacterOpenedUseCase _trackCharacterOpened;

  Future<void> _onLoad(
    CharacterDetailLoad event,
    Emitter<CharacterDetailState> emit,
  ) async {
    if (event is CharacterDetailOpened) {
      unawaited(_trackCharacterOpened((characterId: event.id)));
    }
    emit(const CharacterDetailState.loading());
    final result = await _getCharacterDetail((id: event.id));
    emit(switch (result) {
      Ok(:final value) => CharacterDetailState.loaded(value),
      Err(:final failure) => CharacterDetailState.failure(failure),
    });
  }
}
