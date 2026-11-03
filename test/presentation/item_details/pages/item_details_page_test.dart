import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/usecases/get_item_details_use_case.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_cubit.dart';
import 'package:flutter_starter/presentation/item_details/pages/item_details_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fake_analytics_service.dart';
import '../../../helpers/fake_favorites_repository.dart';
import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockItemsRepository repository;
  late ItemDetailsCubit cubit;

  Future<void> pumpPage(
    WidgetTester tester, {
    Widget Function(Item item)? toggleBuilder,
    WidgetBuilder? notFoundActionBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: ItemDetailsPage(
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
    repository = MockItemsRepository();
    cubit = ItemDetailsCubit(
      GetItemDetailsUseCase(repository),
      FakeAnalyticsService(),
    );
  });

  tearDown(() => cubit.close());

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('shows all the fields', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => repository.getById(1)).thenAnswer((_) async => Ok(testItem(1)));
    await cubit.load(1);
    await pumpPage(tester);

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Alive'), findsOneWidget);
    expect(find.text('Human'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
    expect(find.text('Citadel'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows the failure and retries', (tester) async {
    when(() => repository.getById(1))
        .thenAnswer((_) async => const Err(Failure.notFound()));
    await cubit.load(1);
    await pumpPage(tester);
    expect(find.text('Nothing was found.'), findsOneWidget);

    when(() => repository.getById(1)).thenAnswer((_) async => Ok(testItem(1)));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Item 1'), findsOneWidget);
  });

  group('opened from favorites', () {
    Widget action(BuildContext _) => const Text('Remove action');

    testWidgets('a missing item shows the action instead of a retry', (
      tester,
    ) async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.notFound()));
      await cubit.load(1);
      await pumpPage(tester, notFoundActionBuilder: action);

      expect(find.text('Nothing was found.'), findsOneWidget);
      expect(find.text('Remove action'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('other failures keep the retry', (tester) async {
      when(() => repository.getById(1))
          .thenAnswer((_) async => const Err(Failure.network()));
      await cubit.load(1);
      await pumpPage(tester, notFoundActionBuilder: action);

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Remove action'), findsNothing);
    });
  });

  group('favorite toggle', () {
    final toggle = find.byType(IconButton);

    Future<void> pumpLoaded(WidgetTester tester, Stream<AppUser?> users) async {
      final authRepository = MockAuthRepository();
      when(authRepository.authStateChanges).thenAnswer((_) => users);
      when(() => repository.getById(1))
          .thenAnswer((_) async => Ok(testItem(1)));
      await cubit.load(1);
      await pumpPage(
        tester,
        toggleBuilder: favoriteToggleBuilder(
          authRepository,
          FakeFavoritesRepository(),
        ),
      );
      await tester.pump();
    }

    testWidgets('is hidden from a guest', (tester) async {
      await pumpLoaded(tester, Stream.value(null));

      expect(toggle, findsNothing);
    });

    testWidgets('is shown to a signed-in user and flips', (tester) async {
      await pumpLoaded(tester, Stream.value(testUser));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(toggle);
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('is not shown before the item has loaded', (tester) async {
      final authRepository = signedInAuthRepository();
      await pumpPage(
        tester,
        toggleBuilder: favoriteToggleBuilder(
          authRepository,
          FakeFavoritesRepository(),
        ),
      );

      expect(toggle, findsNothing);
    });
  });
}
