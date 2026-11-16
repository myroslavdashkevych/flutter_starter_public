import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_detail_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_character_opened_use_case.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_event.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/character_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  late MockCharacterRepository repository;

  CharacterDetailBloc build() => CharacterDetailBloc(
    GetCharacterDetailUseCase(repository),
    TrackCharacterOpenedUseCase(FakeAnalyticsService()),
  );

  setUp(() {
    repository = MockCharacterRepository();
  });

  blocTest<CharacterDetailBloc, CharacterDetailState>(
    'CHR-14: emits the loaded character',
    setUp: () {
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testCharacter(1)));
    },
    build: build,
    act: (bloc) => bloc.add(const CharacterDetailOpened(1)),
    expect: () => [
      const CharacterDetailState.loading(),
      CharacterDetailState.loaded(testCharacter(1)),
    ],
  );

  blocTest<CharacterDetailBloc, CharacterDetailState>(
    'CHR-15: emits the failure, and retry returns to loading',
    setUp: () {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const CharacterDetailOpened(1));
      await pumpEventQueue();
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testCharacter(1)));
      bloc.add(const CharacterDetailRetried(1));
    },
    expect: () => [
      const CharacterDetailState.loading(),
      const CharacterDetailState.failure(Failure.network()),
      const CharacterDetailState.loading(),
      CharacterDetailState.loaded(testCharacter(1)),
    ],
  );

  final first = Completer<Result<Character>>();
  blocTest<CharacterDetailBloc, CharacterDetailState>(
    'a retry replaces a running load, whose late result is dropped',
    setUp: () {
      when(() => repository.getById(1)).thenAnswer((_) => first.future);
    },
    build: build,
    act: (bloc) async {
      bloc.add(const CharacterDetailOpened(1));
      await pumpEventQueue();
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testCharacter(1)));
      bloc.add(const CharacterDetailRetried(1));
      await pumpEventQueue();
      first.complete(const Err(Failure.network()));
    },
    expect: () => [
      const CharacterDetailState.loading(),
      CharacterDetailState.loaded(testCharacter(1)),
    ],
  );

  test(
    'CHR-18: open logs select_content once; a retry does not log again',
    () async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
      final analytics = FakeAnalyticsService();
      final bloc = CharacterDetailBloc(
        GetCharacterDetailUseCase(repository),
        TrackCharacterOpenedUseCase(analytics),
      );
      addTearDown(bloc.close);

      bloc.add(const CharacterDetailOpened(1));
      await pumpEventQueue();
      bloc.add(const CharacterDetailRetried(1));
      await pumpEventQueue();

      expect(analytics.events, [
        const AnalyticsEvent.characterOpened(characterId: 1),
      ]);
    },
  );
}
