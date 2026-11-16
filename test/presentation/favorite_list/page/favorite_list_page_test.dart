import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/app_localizations_delegate.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_bloc.dart';
import 'package:flutter_starter/presentation/favorite_list/page/favorite_list_page.dart';
import 'package:flutter_starter/presentation/favorite_list/widget/remove_favorite_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/accessibility.dart';
import '../../../helper/auth_fixture.dart';
import '../../../helper/character_fixture.dart';
import '../../../helper/fake_favorite_repository.dart';
import '../../../helper/mock.dart';

void main() {
  late MockAuthRepository authRepository;
  late FakeFavoriteRepository favorites;

  const guestMessage = 'Sign in to save favorites';
  final signInButton = find.widgetWithText(FilledButton, 'Sign in');

  FavoriteListBloc buildBloc() => favoriteListBloc(authRepository, favorites);

  setUp(() {
    authRepository = signedInAuthRepository();
    favorites = FakeFavoriteRepository();
  });

  Widget app(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider(create: (_) => buildBloc(), child: child),
  );

  group('FavoriteListPage', () {
    var signInTaps = 0;
    final selected = <int>[];

    setUp(() {
      signInTaps = 0;
      selected.clear();
    });

    Future<void> pumpPage(WidgetTester tester, {ThemeData? theme}) async {
      await tester.pumpWidget(
        app(
          FavoriteListPage(
            onSignIn: () => signInTaps++,
            onCharacterSelected: selected.add,
            favoriteToggleBuilder: favoriteToggleBuilder(
              authRepository,
              favorites,
            ),
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
    }

    testAccessibility((tester, theme) async {
      favorites = FakeFavoriteRepository([testCharacter(2), testCharacter(1)]);
      await pumpPage(tester, theme: theme);
    });

    testWidgets('FAV-6: a guest is asked to sign in', (tester) async {
      when(authRepository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
      await pumpPage(tester);

      expect(find.text(guestMessage), findsOneWidget);

      await tester.tap(signInButton);

      expect(signInTaps, 1);
    });

    testWidgets('FAV-12: an unknown auth state shows a progress indicator', (
      tester,
    ) async {
      when(authRepository.authStateChanges)
          .thenAnswer((_) => const Stream<AppUser?>.empty());
      await tester.pumpWidget(
        app(
          FavoriteListPage(
            onSignIn: () {},
            onCharacterSelected: (_) {},
            favoriteToggleBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(guestMessage), findsNothing);
    });

    testWidgets('FAV-13: no favorites shows the hint', (tester) async {
      await pumpPage(tester);

      expect(find.textContaining('No favorites yet'), findsOneWidget);
      expect(find.text(guestMessage), findsNothing);
    });

    testWidgets('FAV-5, FAV-14: lists the characters in order and opens one', (
      tester,
    ) async {
      favorites = FakeFavoriteRepository([testCharacter(2), testCharacter(1)]);
      await pumpPage(tester);

      final first = tester.getTopLeft(find.text('Character 2'));
      final second = tester.getTopLeft(find.text('Character 1'));
      expect(first.dy, lessThan(second.dy));

      await tester.tap(find.text('Character 1'));

      expect(selected, [1]);
    });

    testWidgets('FAV-15: removing a favorite takes it off the list at once', (
      tester,
    ) async {
      favorites = FakeFavoriteRepository([testCharacter(2), testCharacter(1)]);
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.favorite).first);
      await tester.pumpAndSettle();

      expect(find.text('Character 2'), findsNothing);
      expect(find.text('Character 1'), findsOneWidget);
      // The remaining tile keeps its own toggle state.
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('FAV-13: removing the last favorite shows the hint', (
      tester,
    ) async {
      favorites = FakeFavoriteRepository([testCharacter(1)]);
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      expect(find.textContaining('No favorites yet'), findsOneWidget);
    });
  });

  group('RemoveFavoriteButton', () {
    var removed = 0;
    final button = find.widgetWithText(FilledButton, 'Remove from favorites');

    setUp(() => removed = 0);

    Future<void> pumpButton(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: RemoveFavoriteButton(id: 1, onRemoved: () => removed++),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('FAV-10: removes the favorite and reports it once', (
      tester,
    ) async {
      favorites = FakeFavoriteRepository([testCharacter(1)]);
      await pumpButton(tester);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(favorites.characters, isEmpty);
      expect(removed, 1);
      expect(button, findsNothing);
    });

    testWidgets('a failure shows a message and keeps the button', (
      tester,
    ) async {
      favorites = FakeFavoriteRepository([testCharacter(1)])
        ..toggleFailure = const Failure.cache();
      await pumpButton(tester);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(removed, 0);
      expect(button, findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('is hidden when the character is not a favorite', (
      tester,
    ) async {
      await pumpButton(tester);

      expect(button, findsNothing);
      expect(removed, 0);
    });
  });
}
