import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_bloc.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_event.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockItemsRepository repository;

  const failure = Failure.network();
  final afterDebounce =
      ItemsListBloc.searchDebounce + const Duration(milliseconds: 100);
  final firstPage = testPage(1, ids: [1, 2]);
  final loaded = ItemsListState(
    status: ItemsListStatus.loaded,
    items: firstPage.items,
    page: 1,
    hasMore: true,
    generation: 1,
  );

  ItemsListBloc build() =>
      ItemsListBloc(GetItemsPageUseCase(repository), FakeAnalyticsService());

  void stubPage(
    int page,
    Future<Result<Paginated<Item>>> Function() answer, {
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
    repository = MockItemsRepository();
  });

  group('load', () {
    blocTest<ItemsListBloc, ItemsListState>(
      'emits loading, then the first page',
      setUp: () => stubPage(1, () async => Ok(firstPage)),
      build: build,
      act: (bloc) => bloc.add(const ItemsListLoadRequested()),
      expect: () => [const ItemsListState(generation: 1), loaded],
    );

    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-7: emits the failure, and retry loads again',
      setUp: () => stubPage(1, () async => const Err(failure)),
      build: build,
      act: (bloc) async {
        bloc.add(const ItemsListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        stubPage(1, () async => Ok(firstPage));
        bloc.add(const ItemsListLoadRequested());
      },
      expect: () => [
        const ItemsListState(generation: 1),
        const ItemsListState(
          status: ItemsListStatus.failure,
          failure: failure,
          generation: 1,
        ),
        const ItemsListState(generation: 2),
        loaded.copyWith(generation: 2),
      ],
    );

    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-6: an empty result is a loaded state without items',
      setUp: () =>
          stubPage(1, () async => Ok(testPage(1, ids: [], hasMore: false))),
      build: build,
      act: (bloc) => bloc.add(const ItemsListLoadRequested()),
      expect: () => [
        const ItemsListState(generation: 1),
        const ItemsListState(
          status: ItemsListStatus.loaded,
          page: 1,
          generation: 1,
        ),
      ],
    );
  });

  group('search', () {
    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-2: debounces typing and restarts pagination with the last query',
      setUp: () => stubPage(
        1,
        () async => Ok(testPage(1, ids: [3], hasMore: false)),
        query: 'rick',
      ),
      build: build,
      seed: () => loaded.copyWith(page: 4),
      act: (bloc) async {
        bloc
          ..add(const ItemsListSearchChanged('r'))
          ..add(const ItemsListSearchChanged('ri'))
          ..add(const ItemsListSearchChanged('rick'));
      },
      wait: afterDebounce,
      expect: () => [
        const ItemsListState(query: 'rick', generation: 2),
        ItemsListState(
          status: ItemsListStatus.loaded,
          query: 'rick',
          items: [testItem(3)],
          page: 1,
          generation: 2,
        ),
      ],
      verify: (_) {
        verify(() => repository.getPage(page: 1, query: 'rick')).called(1);
        verifyNever(() => repository.getPage(page: 1, query: 'r'));
      },
    );

    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-2: an unchanged query does nothing',
      build: build,
      seed: () => loaded.copyWith(query: 'rick'),
      act: (bloc) => bloc.add(const ItemsListSearchChanged('rick')),
      wait: afterDebounce,
      expect: () => const <ItemsListState>[],
    );

    test('ITM-5: a slower earlier search cannot replace a newer one', () async {
      final slow = Completer<Result<Paginated<Item>>>();
      stubPage(1, () => slow.future, query: 'a');
      stubPage(1, () async => Ok(testPage(1, ids: [9])), query: 'b');
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const ItemsListSearchChanged('a'));
      await Future<void>.delayed(afterDebounce);
      bloc.add(const ItemsListSearchChanged('b'));
      await Future<void>.delayed(afterDebounce);
      slow.complete(Ok(testPage(1, ids: [8])));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.query, 'b');
      expect(bloc.state.items, [testItem(9)]);
    });
  });

  group('search analytics', () {
    late FakeAnalyticsService analytics;
    late ItemsListBloc bloc;

    setUp(() {
      analytics = FakeAnalyticsService();
      bloc = ItemsListBloc(GetItemsPageUseCase(repository), analytics);
      stubPage(1, () async => Ok(firstPage), query: 'rick');
      stubPage(1, () async => Ok(firstPage));
    });

    tearDown(() => bloc.close());

    Future<void> search(String query) async {
      bloc.add(ItemsListSearchChanged(query));
      await Future<void>.delayed(afterDebounce);
    }

    test(
      'ITM-17: logs only the term that remains after the debounce',
      () async {
        bloc
          ..add(const ItemsListSearchChanged('r'))
          ..add(const ItemsListSearchChanged('ri'));
        await search('rick');

        expect(analytics.events, [
          [
            AnalyticsEvents.search,
            {AnalyticsParams.searchTerm: 'rick'},
          ],
        ]);
      },
    );

    test(
      'ITM-17: clearing the field or repeating the term logs nothing',
      () async {
        await search('rick');
        await search('rick');
        await search('');

        expect(analytics.events, hasLength(1));
      },
    );
  });

  group('next page', () {
    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-3: appends the next page',
      setUp: () =>
          stubPage(2, () async => Ok(testPage(2, ids: [3], hasMore: false))),
      build: build,
      seed: () => loaded,
      act: (bloc) => bloc.add(const ItemsListNextPageRequested()),
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          items: [testItem(1), testItem(2), testItem(3)],
          page: 2,
          hasMore: false,
        ),
      ],
    );

    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-7: a failure keeps the list, and retry clears it',
      setUp: () => stubPage(2, () async => const Err(failure)),
      build: build,
      seed: () => loaded,
      act: (bloc) async {
        bloc.add(const ItemsListNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        stubPage(2, () async => Ok(testPage(2, ids: [3])));
        bloc.add(const ItemsListNextPageRequested());
      },
      expect: () => [
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(loadMoreFailure: failure),
        loaded.copyWith(isLoadingMore: true),
        loaded.copyWith(
          items: [testItem(1), testItem(2), testItem(3)],
          page: 2,
        ),
      ],
    );

    test('ITM-3: a request while one is running is ignored', () async {
      final slow = Completer<Result<Paginated<Item>>>();
      stubPage(2, () => slow.future);
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const ItemsListNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ItemsListNextPageRequested());
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.getPage(page: 2)).called(1);
      slow.complete(Ok(testPage(2, ids: [3], hasMore: false)));
    });

    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-3: does nothing on the last page',
      build: build,
      seed: () => loaded.copyWith(hasMore: false),
      act: (bloc) => bloc.add(const ItemsListNextPageRequested()),
      expect: () => const <ItemsListState>[],
    );

    test('ITM-5: a result arriving after a new search is dropped', () async {
      final slow = Completer<Result<Paginated<Item>>>();
      stubPage(2, () => slow.future);
      stubPage(1, () async => Ok(testPage(1, ids: [9])), query: 'rick');
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const ItemsListNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ItemsListSearchChanged('rick'));
      await Future<void>.delayed(afterDebounce);
      slow.complete(Ok(testPage(2, ids: [3])));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.query, 'rick');
      expect(bloc.state.items, [testItem(9)]);
      expect(bloc.state.page, 1);
      expect(bloc.state.isLoadingMore, isFalse);
    });

    test('ITM-5: a failure arriving after a refresh is dropped', () async {
      final slow = Completer<Result<Paginated<Item>>>();
      stubPage(2, () => slow.future);
      stubPage(1, () async => Ok(testPage(1, ids: [7])), forceRefresh: true);
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const ItemsListNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ItemsListRefreshRequested());
      await Future<void>.delayed(Duration.zero);
      slow.complete(const Err(failure));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items, [testItem(7)]);
      expect(bloc.state.page, 1);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.loadMoreFailure, isNull);
    });
  });

  group('refresh', () {
    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-4: forces page 1 and replaces the list',
      setUp: () => stubPage(
        1,
        () async => Ok(testPage(1, ids: [7])),
        forceRefresh: true,
      ),
      build: build,
      seed: () => loaded.copyWith(page: 3),
      act: (bloc) => bloc.add(const ItemsListRefreshRequested()),
      expect: () => [
        loaded.copyWith(page: 3, isRefreshing: true, generation: 2),
        loaded.copyWith(items: [testItem(7)], generation: 2),
      ],
    );

    blocTest<ItemsListBloc, ItemsListState>(
      'ITM-19: a failure keeps the list and is reported once',
      setUp: () =>
          stubPage(1, () async => const Err(failure), forceRefresh: true),
      build: build,
      seed: () => loaded,
      act: (bloc) async {
        bloc.add(const ItemsListRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ItemsListRefreshRequested());
      },
      expect: () => [
        loaded.copyWith(isRefreshing: true, generation: 2),
        loaded.copyWith(refreshFailure: failure, generation: 2),
        loaded.copyWith(isRefreshing: true, generation: 3),
        loaded.copyWith(refreshFailure: failure, generation: 3),
      ],
    );

    blocTest<ItemsListBloc, ItemsListState>(
      'does nothing until the list is loaded',
      build: build,
      act: (bloc) => bloc.add(const ItemsListRefreshRequested()),
      expect: () => const <ItemsListState>[],
    );

    test('ITM-5: a result arriving after a new search is dropped', () async {
      final slow = Completer<Result<Paginated<Item>>>();
      stubPage(1, () => slow.future, forceRefresh: true);
      stubPage(1, () async => Ok(testPage(1, ids: [9])), query: 'rick');
      final bloc = build()..emit(loaded);
      addTearDown(bloc.close);

      bloc.add(const ItemsListRefreshRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ItemsListSearchChanged('rick'));
      await Future<void>.delayed(afterDebounce);
      slow.complete(Ok(testPage(1, ids: [7])));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items, [testItem(9)]);
      expect(bloc.state.isRefreshing, isFalse);
    });
  });
}
