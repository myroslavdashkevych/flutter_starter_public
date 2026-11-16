import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_detail_use_case.dart';
import 'package:flutter_starter/domain/use_case/character/track_character_opened_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/app_localizations_delegate.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_event.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_state.dart';
import 'package:flutter_starter/presentation/character_detail/page/character_detail_page.dart';
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
  late CharacterDetailBloc bloc;

  Future<void> pumpPage(
    WidgetTester tester, {
    Widget Function(Character character)? toggleBuilder,
    WidgetBuilder? notFoundActionBuilder,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: CharacterDetailPage(
            id: 1,
            favoriteToggleBuilder:
                toggleBuilder ?? (_) => const SizedBox.shrink(),
            notFoundActionBuilder: notFoundActionBuilder,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    repository = MockCharacterRepository();
    bloc = CharacterDetailBloc(
      GetCharacterDetailUseCase(repository),
      TrackCharacterOpenedUseCase(FakeAnalyticsService()),
    );
  });

  tearDown(() => bloc.close());

  // The bloc is made in setUp, outside the fake time of the widget test, so
  // its events run only in real async code.
  Future<void> load(WidgetTester tester) => tester.runAsync(() async {
    bloc.add(const CharacterDetailOpened(1));
    await bloc.stream.firstWhere((state) => state is! CharacterDetailLoading);
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('CHR-14: shows all the fields', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => repository.getById(1))
        .thenAnswer((_) async => Ok(testCharacter(1)));
    await load(tester);
    await pumpPage(tester);

    expect(find.text('Character 1'), findsOneWidget);
    expect(find.text('Alive'), findsOneWidget);
    expect(find.text('Human'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
    expect(find.text('Citadel'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('CHR-15: shows the failure and retries', (tester) async {
    when(() => repository.getById(1))
        .thenAnswer((_) async => const Err(Failure.notFound()));
    await load(tester);
    await pumpPage(tester);
    expect(find.text('Nothing was found.'), findsOneWidget);

    when(() => repository.getById(1))
        .thenAnswer((_) async => Ok(testCharacter(1)));
    await tester.tap(find.text('Retry'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((state) => state is CharacterDetailLoaded),
    );
    await tester.pump();

    expect(find.text('Character 1'), findsOneWidget);
  });

  group('opened from favorites', () {
    Widget action(BuildContext _) => const Text('Remove action');

    testWidgets(
      'FAV-10: a missing character shows the action instead of a retry',
      (tester) async {
        when(() => repository.getById(1))
            .thenAnswer((_) async => const Err(Failure.notFound()));
        await load(tester);
        await pumpPage(tester, notFoundActionBuilder: action);

        expect(find.text('Nothing was found.'), findsOneWidget);
        expect(find.text('Remove action'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      },
    );

    testWidgets('FAV-10: other failures keep the retry', (tester) async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
      await load(tester);
      await pumpPage(tester, notFoundActionBuilder: action);

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Remove action'), findsNothing);
    });
  });

  group('favorite toggle', () {
    final toggle = find.byType(IconButton);

    // Like Firebase, every listener gets its own stream with the current user.
    Future<void> pumpLoaded(WidgetTester tester, AppUser? user) async {
      final authRepository = MockAuthRepository();
      when(authRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(user));
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testCharacter(1)));
      await load(tester);
      await pumpPage(
        tester,
        toggleBuilder: favoriteToggleBuilder(
          authRepository,
          FakeFavoriteRepository(),
        ),
      );
      await tester.pump();
    }

    testWidgets('FAV-2: is hidden from a guest', (tester) async {
      await pumpLoaded(tester, null);

      expect(toggle, findsNothing);
    });

    testWidgets('FAV-1: is shown to a signed-in user and flips', (
      tester,
    ) async {
      await pumpLoaded(tester, testUser);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(toggle);
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('is not shown before the character has loaded', (tester) async {
      final authRepository = signedInAuthRepository();
      await pumpPage(
        tester,
        toggleBuilder: favoriteToggleBuilder(
          authRepository,
          FakeFavoriteRepository(),
        ),
      );

      expect(toggle, findsNothing);
    });
  });

  testAccessibility((tester, theme) async {
    when(() => repository.getById(1))
        .thenAnswer((_) async => Ok(testCharacter(1)));
    await load(tester);
    await pumpPage(
      tester,
      toggleBuilder: favoriteToggleBuilder(
        signedInAuthRepository(),
        FakeFavoriteRepository(),
      ),
      theme: theme,
    );
    await tester.pump();
  });
}
