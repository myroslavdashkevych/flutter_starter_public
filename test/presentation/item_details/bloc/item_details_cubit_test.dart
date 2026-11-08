import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/usecases/get_item_details_use_case.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_cubit.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockItemsRepository repository;

  ItemDetailsCubit build() => ItemDetailsCubit(
    GetItemDetailsUseCase(repository),
    FakeAnalyticsService(),
  );

  setUp(() {
    repository = MockItemsRepository();
  });

  blocTest<ItemDetailsCubit, ItemDetailsState>(
    'ITM-14: emits the loaded item',
    setUp: () {
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testItem(1)));
    },
    build: build,
    act: (cubit) => cubit.load(1),
    expect: () => [
      const ItemDetailsState.loading(),
      ItemDetailsState.loaded(testItem(1)),
    ],
  );

  blocTest<ItemDetailsCubit, ItemDetailsState>(
    'ITM-15: emits the failure, and retry returns to loading',
    setUp: () {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(1);
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testItem(1)));
      await cubit.load(1);
    },
    expect: () => [
      const ItemDetailsState.loading(),
      const ItemDetailsState.failure(Failure.network()),
      const ItemDetailsState.loading(),
      ItemDetailsState.loaded(testItem(1)),
    ],
  );

  group('NTF-1: open onLoaded', () {
    test('runs after the item is loaded', () async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testItem(1)));
      final cubit = build();
      addTearDown(cubit.close);
      var calls = 0;

      await cubit.open(1, onLoaded: () => calls++);

      expect(calls, 1);
      expect(cubit.state, ItemDetailsState.loaded(testItem(1)));
    });

    test('does not run after a failure or a successful retry', () async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
      final cubit = build();
      addTearDown(cubit.close);
      var calls = 0;

      await cubit.open(1, onLoaded: () => calls++);
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testItem(1)));
      await cubit.load(1);

      expect(calls, 0);
    });

    test('does not run when the page was closed during loading', () async {
      final item = Completer<Result<Item>>();
      when(() => repository.getById(1)).thenAnswer((_) => item.future);
      final cubit = build();
      var calls = 0;

      final opening = cubit.open(1, onLoaded: () => calls++);
      await cubit.close();
      item.complete(Ok(testItem(1)));
      await opening;

      expect(calls, 0);
    });
  });

  test(
    'ITM-18: open logs select_content once; a retry does not log again',
    () async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
      final analytics = FakeAnalyticsService();
      final cubit = ItemDetailsCubit(
        GetItemDetailsUseCase(repository),
        analytics,
      );
      addTearDown(cubit.close);

      await cubit.open(1);
      await cubit.load(1);

      expect(analytics.events, [
        [
          AnalyticsEvents.selectContent,
          {
            AnalyticsParams.contentType: AnalyticsValues.itemContentType,
            AnalyticsParams.itemId: '1',
          },
        ],
      ]);
    },
  );
}
