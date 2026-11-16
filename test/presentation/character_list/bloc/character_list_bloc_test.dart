import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_page_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_search_use_case.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_bloc.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_event.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/character_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/mock.dart';

void main() {
  late MockCharacterRepository repository;

  const failure = Failure.network();
  final afterDebounce =
      CharacterListBloc.searchDebounce + const Duration(milliseconds: 100);
  final firstPage = testPage(1, ids: [1, 2]);
  final loaded = CharacterListState(
    status: CharacterListStatus.loaded,
    characters: firstPage.items,
    page: 1,
    hasMore: true,
    generation: 1,
  );

  CharacterListBloc build() => CharacterListBloc(
    GetCharacterPageUseCase(repository),
    TrackSearchUseCase(FakeAnalyticsService()),
  );

  void stubPage(
    int page,
    Future<Result<Paginated<Character>>> Function() answer, {
    String? query,
    bool forceRefresh = false,
  }) {
    when(
      () => repository.getPage(
        page: page,
        query: query,
        forceRefresh: forceRefresh,
      ),
    ).thenAnswer((_) => answer());
  }

  setUp(() {
    repository = MockCharacterRepository();
  });

  group('load', () {
    blocTest<CharacterListBloc, CharacterListState>(
      'emits loading, then the first page',
      setUp: () => stubPage(1, () async => Ok(firstPage)),
      build: build,
      act: (bloc) => bloc.add(const CharacterListLoadRequested()),
      expect: () => [const CharacterListState(generation: 1), loaded],
    );

    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-7: emits the failure, and retry loads again',
      setUp: () => stubPage(1, () async => const Err(failure)),
      build: build,
      act: (bloc) async {
        bloc.add(const CharacterListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        stubPage(1, () async => Ok(firstPage));
        bloc.add(const CharacterListLoadRequested());
      },
      expect: () => [
        const CharacterListState(generation: 1),
        const CharacterListState(
          status: CharacterListStatus.failure,
          failure: failure,
          generation: 1,
        ),
        const CharacterListState(generation: 2),
        loaded.copyWith(generation: 2),
      ],
    );

    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-6: an empty result is a loaded state without characters',
      setUp: () =>
          stubPage(1, () async => Ok(testPage(1, ids: [], hasMore: false))),
      build: build,
      act: (bloc) => bloc.add(const CharacterListLoadRequested()),
      expect: () => [
        const CharacterListState(generation: 1),
        const CharacterListState(
          status: CharacterListStatus.loaded,
          page: 1,
          generation: 1,
        ),
      ],
    );

    final slowFirst = Completer<Result<Paginated<Character>>>();
    blocTest<CharacterListBloc, CharacterListState>(
      'a new load replaces a running one without waiting for it',
      setUp: () => stubPage(1, () => slowFirst.future),
      build: build,
      act: (bloc) async {
        bloc.add(const CharacterListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        stubPage(1, () async => Ok(firstPage));
        bloc.add(const CharacterListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        slowFirst.complete(Ok(testPage(1, ids: [9])));
      },
      expect: () => [
        const CharacterListState(generation: 1),
        const CharacterListState(generation: 2),
        loaded.copyWith(generation: 2),
      ],
    );
  });

  group('search', () {
    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-2: debounces typing and restarts pagination with the last query',
      setUp: () => stubPage(
        1,
        () async => Ok(testPage(1, ids: [3], hasMore: false)),
        query: 'rick',
      ),
      build: build,
      seed: () => loaded.copyWith(page: 4),
      act: (bloc) async {
        bloc
          ..add(const CharacterListSearchChanged('r'))
          ..add(const CharacterListSearchChanged('ri'))
          ..add(const CharacterListSearchChanged('rick'));
      },
      wait: afterDebounce,
      expect: () => [
        const CharacterListState(query: 'rick', generation: 2),
        CharacterListState(
          status: CharacterListStatus.loaded,
          query: 'rick',
          characters: [testCharacter(3)],
          page: 1,
          generation: 2,
        ),
      ],
      verify: (_) {
        verify(() => repository.getPage(page: 1, query: 'rick')).called(1);
        verifyNever(() => repository.getPage(page: 1, query: 'r'));
      },
    );

    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-2: an unchanged query does nothing',
      build: build,
      seed: () => loaded.copyWith(query: 'rick'),
      act: (bloc) => bloc.add(const CharacterListSearchChanged('rick')),
      wait: afterDebounce,
      expect: () => const <CharacterListState>[],
    );

    test('CHR-5: a slower earlier search cannot replace a newer one', () async {
      final slow = Completer<Result<Paginated<Character>>>();
      stubPage(1, () => slow.future, query: 'a');
      stubPage(1, () async => Ok(testPage(1, ids: [9])), query: 'b');
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const CharacterListSearchChanged('a'));
      await Future<void>.delayed(afterDebounce);
      bloc.add(const CharacterListSearchChanged('b'));
      await Future<void>.delayed(afterDebounce);
      slow.complete(Ok(testPage(1, ids: [8])));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.query, 'b');
      expect(bloc.state.characters, [testCharacter(9)]);
    });
  });

  group('search analytics', () {
    late FakeAnalyticsService analytics;
    late CharacterListBloc bloc;

    setUp(() {
      analytics = FakeAnalyticsService();
      bloc = CharacterListBloc(
        GetCharacterPageUseCase(repository),
        TrackSearchUseCase(analytics),
      );
      stubPage(1, () async => Ok(firstPage), query: 'rick');
      stubPage(1, () async => Ok(firstPage));
    });

    tearDown(() => bloc.close());

    Future<void> search(String query) async {
      bloc.add(CharacterListSearchChanged(query));
      await Future<void>.delayed(afterDebounce);
    }

    test(
      'CHR-17: logs only the term that remains after the debounce',
      () async {
        bloc
          ..add(const CharacterListSearchChanged('r'))
          ..add(const CharacterListSearchChanged('ri'));
        await search('rick');

        expect(analytics.events, [const AnalyticsEvent.searched(term: 'rick')]);
      },
    );

    test(
      'CHR-17: clearing the field or repeating the term logs nothing',
      () async {
        await search('rick');
        await search('rick');
        await search('');

        expect(analytics.events, hasLength(1));
      },
    );
  });

  group('next page', () {
    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-3: appends the next page',
      setUp: () =>
          stubPage(2, () async => Ok(testPage(2, ids: [3], hasMore: false))),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const CharacterListNextPageRequested()),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          characters: [testCharacter(1), testCharacter(2), testCharacter(3)],
          page: 2,
          hasMore: false,
        ),
      ],
    );

    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-7: a failure keeps the list, and retry clears it',
      setUp: () => stubPage(2, () async => const Err(failure)),
      build: build,
      seed: () => loaded,
      act: (bloc) async {
        bloc.add(const CharacterListNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        stubPage(2, () async => Ok(testPage(2, ids: [3])));
        bloc.add(const CharacterListNextPageRequested());
      },
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(loadMoreFailure: failure),
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          characters: [testCharacter(1), testCharacter(2), testCharacter(3)],
          page: 2,
        ),
      ],
    );

    test('CHR-3: a request while one is running is ignored', () async {
      final slow = Completer<Result<Paginated<Character>>>();
      stubPage(2, () => slow.future);
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const CharacterListNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CharacterListNextPageRequested());
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.getPage(page: 2)).called(1);
      slow.complete(Ok(testPage(2, ids: [3], hasMore: false)));
    });

    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-3: does nothing on the last page',
      build: build,
      seed: () => loaded.copyWith(hasMore: false),
      act: (bloc) => bloc.add(const CharacterListNextPageRequested()),
      expect: () => const <CharacterListState>[],
    );

    test('CHR-5: a result arriving after a new search is dropped', () async {
      final slow = Completer<Result<Paginated<Character>>>();
      stubPage(2, () => slow.future);
      stubPage(1, () async => Ok(testPage(1, ids: [9])), query: 'rick');
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const CharacterListNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CharacterListSearchChanged('rick'));
      await Future<void>.delayed(afterDebounce);
      slow.complete(Ok(testPage(2, ids: [3])));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.query, 'rick');
      expect(bloc.state.characters, [testCharacter(9)]);
      expect(bloc.state.page, 1);
      expect(bloc.state.isLoadingMore, isFalse);
    });

    test('CHR-5: a failure arriving after a refresh is dropped', () async {
      final slow = Completer<Result<Paginated<Character>>>();
      stubPage(2, () => slow.future);
      stubPage(1, () async => Ok(testPage(1, ids: [7])), forceRefresh: true);
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const CharacterListNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CharacterListRefreshRequested());
      await Future<void>.delayed(Duration.zero);
      slow.complete(const Err(failure));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.characters, [testCharacter(7)]);
      expect(bloc.state.page, 1);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.loadMoreFailure, isNull);
    });
  });

  group('refresh', () {
    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-4: forces page 1 and replaces the list',
      setUp: () => stubPage(
        1,
        () async => Ok(testPage(1, ids: [7])),
        forceRefresh: true,
      ),
      build: build,
      seed: () => loaded.copyWith(page: 3),
      act: (bloc) => bloc.add(const CharacterListRefreshRequested()),
      expect: () => [
        loaded.copyWith(page: 3, isRefreshing: true, generation: 2),
        loaded.copyWith(characters: [testCharacter(7)], generation: 2),
      ],
    );

    blocTest<CharacterListBloc, CharacterListState>(
      'CHR-19: a failure keeps the list and is reported once',
      setUp: () =>
          stubPage(1, () async => const Err(failure), forceRefresh: true),
      build: build,
      seed: () => loaded,
      act: (bloc) async {
        bloc.add(const CharacterListRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CharacterListRefreshRequested());
      },
      expect: () => [
        loaded.copyWith(isRefreshing: true, generation: 2),
        loaded.copyWith(refreshFailure: failure, generation: 2),
        loaded.copyWith(isRefreshing: true, generation: 3),
        loaded.copyWith(refreshFailure: failure, generation: 3),
      ],
    );

    blocTest<CharacterListBloc, CharacterListState>(
      'does nothing until the list is loaded',
      build: build,
      act: (bloc) => bloc.add(const CharacterListRefreshRequested()),
      expect: () => const <CharacterListState>[],
    );

    final slowRefresh = Completer<Result<Paginated<Character>>>();
    blocTest<CharacterListBloc, CharacterListState>(
      'a refresh while one runs starts no second request',
      setUp: () => stubPage(1, () => slowRefresh.future, forceRefresh: true),
      build: build,
      seed: () => loaded,
      act: (bloc) async {
        bloc.add(const CharacterListRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CharacterListRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        slowRefresh.complete(Ok(testPage(1, ids: [7])));
      },
      expect: () => [
        loaded.copyWith(isRefreshing: true, generation: 2),
        loaded.copyWith(characters: [testCharacter(7)], generation: 2),
      ],
      verify: (_) =>
          verify(() => repository.getPage(page: 1, forceRefresh: true))
              .called(1),
    );

    test('CHR-5: a result arriving after a new search is dropped', () async {
      final slow = Completer<Result<Paginated<Character>>>();
      stubPage(1, () => slow.future, forceRefresh: true);
      stubPage(1, () async => Ok(testPage(1, ids: [9])), query: 'rick');
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const CharacterListRefreshRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CharacterListSearchChanged('rick'));
      await Future<void>.delayed(afterDebounce);
      slow.complete(Ok(testPage(1, ids: [7])));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.characters, [testCharacter(9)]);
      expect(bloc.state.isRefreshing, isFalse);
    });
  });
}
