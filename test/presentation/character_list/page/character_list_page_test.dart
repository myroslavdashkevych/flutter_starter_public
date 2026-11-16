import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_page_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_search_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/app_localizations_delegate.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_bloc.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_state.dart';
import 'package:flutter_starter/presentation/character_list/page/character_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/accessibility.dart';
import '../../../helper/auth_fixture.dart';
import '../../../helper/character_fixture.dart';
import '../../../helper/fake_analytics_service.dart';
import '../../../helper/fake_favorite_repository.dart';
import '../../../helper/mock.dart';

void main() {
  late MockCharacterRepository repository;
  CharacterListBloc? bloc;
  final selected = <int>[];

  final loaded = CharacterListState(
    status: CharacterListStatus.loaded,
    characters: [testCharacter(1), testCharacter(2)],
    page: 1,
    hasMore: true,
    generation: 1,
  );

  Future<void> pumpPage(
    WidgetTester tester,
    CharacterListState state, {
    Widget Function(Character character)? toggleBuilder,
    ThemeData? theme,
  }) async {
    // Created here so its debounce timer runs on the test's fake clock. In
    // that fake zone the future of close() never completes, so it is not
    // awaited (as BlocProvider does not await it either).
    var currentBloc = bloc;
    if (currentBloc == null) {
      currentBloc = bloc = CharacterListBloc(
        GetCharacterPageUseCase(repository),
        TrackSearchUseCase(FakeAnalyticsService()),
      );
      addTearDown(() => unawaited(currentBloc!.close()));
    }
    currentBloc.emit(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: currentBloc,
          child: CharacterListPage(
            onCharacterSelected: selected.add,
            favoriteToggleBuilder:
                toggleBuilder ?? (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    repository = MockCharacterRepository();
    bloc = null;
    selected.clear();
  });

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
          FakeFavoriteRepository([testCharacter(1)]),
        ),
      );
      await tester.pump();

      expect(find.text('Character 1'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('FAV-1: shows a signed-in user the state of every character', (
      tester,
    ) async {
      await pumpPage(
        tester,
        loaded,
        toggleBuilder: favoriteToggleBuilder(
          signedInAuthRepository(),
          FakeFavoriteRepository([testCharacter(1)]),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('tapping it does not open the character', (tester) async {
      final favorites = FakeFavoriteRepository();
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

      expect(favorites.characters, [testCharacter(1)]);
      expect(selected, isEmpty);
    });

    testWidgets('ACC-1: the favorite toggle announces its action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpPage(
          tester,
          loaded,
          toggleBuilder: favoriteToggleBuilder(
            signedInAuthRepository(),
            FakeFavoriteRepository(),
          ),
        );
        await tester.pump();

        final tooltips = tester
            .widgetList(find.byType(IconButton))
            .map(
              (button) => tester.getSemantics(find.byWidget(button)).tooltip,
            );
        expect(tooltips, [
          for (final _ in loaded.characters) 'Add to favorites',
        ]);
      } finally {
        semantics.dispose();
      }
    });
  });

  testAccessibility((tester, theme) async {
    await pumpPage(
      tester,
      loaded,
      toggleBuilder: favoriteToggleBuilder(
        signedInAuthRepository(),
        FakeFavoriteRepository([testCharacter(1)]),
      ),
      theme: theme,
    );
    await tester.pump();
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpPage(tester, const CharacterListState());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CHR-7: shows the failure and retries', (tester) async {
    when(() => repository.getPage(page: 1))
        .thenAnswer((_) async => Ok(testPage(1)));
    await pumpPage(
      tester,
      const CharacterListState(
        status: CharacterListStatus.failure,
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

  testWidgets('CHR-6: tells an empty list from an empty search', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const CharacterListState(
        status: CharacterListStatus.loaded,
        generation: 1,
      ),
    );
    expect(find.text('No characters to show.'), findsOneWidget);

    await pumpPage(
      tester,
      const CharacterListState(
        status: CharacterListStatus.loaded,
        query: 'zzz',
        generation: 2,
      ),
    );
    expect(find.text('Nothing matches your search.'), findsOneWidget);
  });

  testWidgets('CHR-1: shows the characters and reports the tapped one', (
    tester,
  ) async {
    await pumpPage(tester, loaded);

    expect(find.text('Human · Alive'), findsNWidgets(2));
    await tester.tap(find.text('Character 2'));

    expect(selected, [2]);
  });

  testWidgets('CHR-3: shows the progress of loading more', (tester) async {
    await pumpPage(tester, loaded.copyWith(isLoadingMore: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Character 1'), findsOneWidget);
  });

  testWidgets('CHR-7: shows an inline retry when loading more fails', (
    tester,
  ) async {
    when(() => repository.getPage(page: 2))
        .thenAnswer((_) async => Ok(testPage(2, ids: [3], hasMore: false)));
    await pumpPage(
      tester,
      loaded.copyWith(loadMoreFailure: const Failure.server(500)),
    );
    expect(find.text('Character 1'), findsOneWidget);
    expect(
      find.text('The server returned an error. Try again later.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => repository.getPage(page: 2)).called(1);
  });

  testWidgets('CHR-19: a refresh failure shows one snack bar', (tester) async {
    await pumpPage(tester, loaded);

    bloc!.emit(loaded.copyWith(refreshFailure: const Failure.network()));
    await tester.pump();
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Character 1'), findsOneWidget);

    bloc!.emit(
      loaded.copyWith(
        refreshFailure: const Failure.network(),
        characters: [testCharacter(3)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('CHR-3: scrolling past 80% requests the next page', (
    tester,
  ) async {
    when(() => repository.getPage(page: 2))
        .thenAnswer((_) async => Ok(testPage(2, ids: [99], hasMore: false)));
    await pumpPage(
      tester,
      loaded.copyWith(
        characters: List.generate(30, (index) => testCharacter(index)),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    verifyNever(() => repository.getPage(page: 2));

    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pump();
    verify(() => repository.getPage(page: 2)).called(1);
  });

  testWidgets('CHR-2: typing sends a search event', (tester) async {
    when(() => repository.getPage(page: 1, query: 'rick'))
        .thenAnswer((_) async => Ok(testPage(1, ids: [5], hasMore: false)));
    await pumpPage(tester, loaded);

    await tester.enterText(find.byType(TextField), 'rick');
    await tester.pump(CharacterListBloc.searchDebounce);
    await tester.pump();
    await tester.pump();

    expect(find.text('Character 5'), findsOneWidget);
  });
}
