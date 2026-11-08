import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_bloc.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_state.dart';
import 'package:flutter_starter/presentation/items_list/pages/items_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockItemsRepository repository;
  ItemsListBloc? bloc;
  final selected = <int>[];

  final loaded = ItemsListState(
    status: ItemsListStatus.loaded,
    items: [testItem(1), testItem(2)],
    page: 1,
    hasMore: true,
    generation: 1,
  );

  Future<void> pumpPage(
    WidgetTester tester,
    ItemsListState state, {
    Widget Function(Item item)? toggleBuilder,
  }) async {
    // Created here so its debounce timer runs on the test's fake clock.
    final currentBloc = bloc ??= ItemsListBloc(
      GetItemsPageUseCase(repository),
      FakeAnalyticsService(),
    );
    currentBloc.emit(state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: currentBloc,
          child: ItemsListPage(
            onItemSelected: selected.add,
            favoriteToggleBuilder:
                toggleBuilder ?? (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    repository = MockItemsRepository();
    bloc = null;
    selected.clear();
  });

  tearDown(() async => bloc?.close());

  group('favorite toggle', () {
    testWidgets('FAV-2: is hidden from a guest', (tester) async {
      final authRepository = MockAuthRepository();
      when(authRepository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
      await pumpPage(
        tester,
        loaded,
        toggleBuilder: favoriteToggleBuilder(
          authRepository,
          FakeFavoritesRepository([testItem(1)]),
        ),
      );
      await tester.pump();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('FAV-1: shows a signed-in user the state of every item', (
      tester,
    ) async {
      await pumpPage(
        tester,
        loaded,
        toggleBuilder: favoriteToggleBuilder(
          signedInAuthRepository(),
          FakeFavoritesRepository([testItem(1)]),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('tapping it does not open the item', (tester) async {
      final favorites = FakeFavoritesRepository();
      await pumpPage(
        tester,
        loaded,
        toggleBuilder: favoriteToggleBuilder(
          signedInAuthRepository(),
          favorites,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pump();

      expect(favorites.items, [testItem(1)]);
      expect(selected, isEmpty);
    });
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpPage(tester, const ItemsListState());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ITM-7: shows the failure and retries', (tester) async {
    when(() => repository.getPage(page: 1))
        .thenAnswer((_) async => Ok(testPage(1)));
    await pumpPage(
      tester,
      const ItemsListState(
        status: ItemsListStatus.failure,
        failure: Failure.network(),
      ),
    );
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => repository.getPage(page: 1)).called(1);
  });

  testWidgets('ITM-6: tells an empty list from an empty search', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const ItemsListState(status: ItemsListStatus.loaded, generation: 1),
    );
    expect(find.text('No items to show.'), findsOneWidget);

    await pumpPage(
      tester,
      const ItemsListState(
        status: ItemsListStatus.loaded,
        query: 'zzz',
        generation: 2,
      ),
    );
    expect(find.text('Nothing matches your search.'), findsOneWidget);
  });

  testWidgets('ITM-1: shows the items and reports the tapped one', (
    tester,
  ) async {
    await pumpPage(tester, loaded);

    expect(find.text('Human · Alive'), findsNWidgets(2));
    await tester.tap(find.text('Item 2'));

    expect(selected, [2]);
  });

  testWidgets('ITM-3: shows the progress of loading more', (tester) async {
    await pumpPage(tester, loaded.copyWith(isLoadingMore: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('ITM-7: shows an inline retry when loading more fails', (
    tester,
  ) async {
    when(() => repository.getPage(page: 2))
        .thenAnswer((_) async => Ok(testPage(2, ids: [3], hasMore: false)));
    await pumpPage(
      tester,
      loaded.copyWith(loadMoreFailure: const Failure.server(500)),
    );
    expect(find.text('Item 1'), findsOneWidget);
    expect(
      find.text('The server returned an error. Try again later.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => repository.getPage(page: 2)).called(1);
  });

  testWidgets('ITM-19: a refresh failure shows one snack bar', (tester) async {
    await pumpPage(tester, loaded);

    bloc!.emit(loaded.copyWith(refreshFailure: const Failure.network()));
    await tester.pump();
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);

    bloc!.emit(
      loaded.copyWith(
        refreshFailure: const Failure.network(),
        items: [testItem(3)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('ITM-3: scrolling past 80% requests the next page', (
    tester,
  ) async {
    when(() => repository.getPage(page: 2))
        .thenAnswer((_) async => Ok(testPage(2, ids: [99], hasMore: false)));
    await pumpPage(
      tester,
      loaded.copyWith(items: List.generate(30, (index) => testItem(index))),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    verifyNever(() => repository.getPage(page: 2));

    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pump();
    verify(() => repository.getPage(page: 2)).called(1);
  });

  testWidgets('ITM-2: typing sends a search event', (tester) async {
    when(() => repository.getPage(page: 1, query: 'rick'))
        .thenAnswer((_) async => Ok(testPage(1, ids: [5], hasMore: false)));
    await pumpPage(tester, loaded);

    await tester.enterText(find.byType(TextField), 'rick');
    await tester.pump(ItemsListBloc.searchDebounce);
    await tester.pump();
    await tester.pump();

    expect(find.text('Item 5'), findsOneWidget);
  });
}
