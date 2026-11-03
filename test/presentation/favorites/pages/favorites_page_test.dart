import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/favorites/usecases/toggle_favorite_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:flutter_starter/presentation/favorites/pages/favorites_page.dart';
import 'package:flutter_starter/presentation/favorites/widgets/remove_favorite_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository authRepository;
  late FakeFavoritesRepository favorites;

  const guestMessage = 'Sign in to save favorites';
  final signInButton = find.widgetWithText(FilledButton, 'Sign in');

  FavoritesCubit buildCubit() => FavoritesCubit(
    authRepository,
    favorites,
    ToggleFavoriteUseCase(favorites, FakeAnalyticsService()),
  );

  setUp(() {
    authRepository = signedInAuthRepository();
    favorites = FakeFavoritesRepository();
  });

  Widget app(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider(create: (_) => buildCubit(), child: child),
  );

  group('FavoritesPage', () {
    var signInTaps = 0;
    final selected = <int>[];

    setUp(() {
      signInTaps = 0;
      selected.clear();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          FavoritesPage(
            onSignIn: () => signInTaps++,
            onItemSelected: selected.add,
            favoriteToggleBuilder: favoriteToggleBuilder(
              authRepository,
              favorites,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a guest is asked to sign in', (tester) async {
      when(authRepository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
      await pumpPage(tester);

      expect(find.text(guestMessage), findsOneWidget);

      await tester.tap(signInButton);

      expect(signInTaps, 1);
    });

    testWidgets('an unknown auth state shows a progress indicator', (
      tester,
    ) async {
      when(authRepository.authStateChanges)
          .thenAnswer((_) => const Stream<AppUser?>.empty());
      await tester.pumpWidget(
        app(
          FavoritesPage(
            onSignIn: () {},
            onItemSelected: (_) {},
            favoriteToggleBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(guestMessage), findsNothing);
    });

    testWidgets('no favorites shows the hint', (tester) async {
      await pumpPage(tester);

      expect(find.textContaining('No favorites yet'), findsOneWidget);
      expect(find.text(guestMessage), findsNothing);
    });

    testWidgets('lists the items in order and opens one', (tester) async {
      favorites = FakeFavoritesRepository([testItem(2), testItem(1)]);
      await pumpPage(tester);

      final first = tester.getTopLeft(find.text('Item 2'));
      final second = tester.getTopLeft(find.text('Item 1'));
      expect(first.dy, lessThan(second.dy));

      await tester.tap(find.text('Item 1'));

      expect(selected, [1]);
    });

    testWidgets('removing a favorite takes it off the list at once', (
      tester,
    ) async {
      favorites = FakeFavoritesRepository([testItem(2), testItem(1)]);
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.favorite).first);
      await tester.pumpAndSettle();

      expect(find.text('Item 2'), findsNothing);
      expect(find.text('Item 1'), findsOneWidget);
      // The remaining tile keeps its own toggle state.
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('removing the last favorite shows the hint', (tester) async {
      favorites = FakeFavoritesRepository([testItem(1)]);
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

    testWidgets('removes the favorite and reports it once', (tester) async {
      favorites = FakeFavoritesRepository([testItem(1)]);
      await pumpButton(tester);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(favorites.items, isEmpty);
      expect(removed, 1);
      expect(button, findsNothing);
    });

    testWidgets('a failure shows a message and keeps the button', (
      tester,
    ) async {
      favorites = FakeFavoritesRepository([testItem(1)])
        ..toggleFailure = const Failure.cache();
      await pumpButton(tester);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(removed, 0);
      expect(button, findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('is hidden when the item is not a favorite', (tester) async {
      await pumpButton(tester);

      expect(button, findsNothing);
      expect(removed, 0);
    });
  });
}
