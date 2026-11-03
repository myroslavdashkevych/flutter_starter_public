import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_starter/app/notifications/notifications_wiring.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/notifications/entities/notification_message.dart';
import 'package:flutter_starter/domain/notifications/repositories/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

GoRouter _router() => GoRouter(
  initialLocation: '/items',
  routes: [
    GoRoute(
      path: '/items',
      builder: (_, _) => const Text('items'),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => Text('item ${state.pathParameters['id']}'),
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(const NotificationMessage()));

  group('isOpenableRoute', () {
    late GoRouter router;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      router = _router();
    });

    tearDown(() => router.dispose());

    for (final route in ['/items', '/items/1', '/items/1?source=push']) {
      test('accepts $route', () {
        expect(isOpenableRoute(router, route), isTrue);
      });
    }

    for (final route in [
      '',
      'items/1',
      '/unknown',
      '/items/abc',
      'https://example.com/items/1',
      '//example.com/items/1',
      'myapp://items/1',
      ':not a uri',
    ]) {
      test('rejects "$route"', () {
        expect(isOpenableRoute(router, route), isFalse);
      });
    }
  });

  group('openTappedNotifications', () {
    late _MockRepository repository;
    late StreamController<NotificationMessage> opened;
    late GoRouter router;

    Future<void> start(WidgetTester tester) async {
      router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      openTappedNotifications(
        repository: repository,
        router: router,
        talker: Talker(),
      );
    }

    setUp(() {
      repository = _MockRepository();
      opened = StreamController();
      when(repository.openedMessages).thenAnswer((_) => opened.stream);
    });

    tearDown(() => opened.close());

    testWidgets('a tap with a valid route opens that screen', (tester) async {
      await start(tester);

      opened.add(const NotificationMessage(route: '/items/1'));
      await tester.pumpAndSettle();

      expect(find.text('item 1'), findsOneWidget);
    });

    testWidgets('the launch message arriving at once opens its screen', (
      tester,
    ) async {
      opened.add(const NotificationMessage(route: '/items/2'));
      await start(tester);
      await tester.pumpAndSettle();

      expect(find.text('item 2'), findsOneWidget);
    });

    testWidgets('an invalid route is ignored', (tester) async {
      await start(tester);

      opened.add(const NotificationMessage(route: '/unknown'));
      await tester.pumpAndSettle();

      expect(find.text('items'), findsOneWidget);
    });

    testWidgets('a tap without a route stays on the current screen', (
      tester,
    ) async {
      await start(tester);

      opened.add(const NotificationMessage(title: 'No route'));
      await tester.pumpAndSettle();

      expect(find.text('items'), findsOneWidget);
    });
  });

  group('setUpNotifications', () {
    late _MockRepository repository;
    late StreamController<NotificationMessage> foreground;
    late StreamController<String> registrationIds;
    late Talker talker;

    setUp(() async {
      repository = _MockRepository();
      foreground = StreamController();
      registrationIds = StreamController();
      talker = Talker();
      when(() => repository.initialize(channelName: any(named: 'channelName')))
          .thenAnswer((_) async => const Ok(null));
      when(repository.register).thenAnswer((_) async => const Ok(null));
      when(repository.registrationIdChanges)
          .thenAnswer((_) => registrationIds.stream);
      when(repository.foregroundMessages).thenAnswer((_) => foreground.stream);
      when(() => repository.showForeground(any()))
          .thenAnswer((_) async => const Ok(null));

      await setUpNotifications(
        repository: repository,
        talker: talker,
        channelName: 'General',
      );
    });

    tearDown(() async {
      await foreground.close();
      await registrationIds.close();
    });

    test('initializes with the channel name and registers', () {
      verifyInOrder([
        () => repository.initialize(channelName: 'General'),
        repository.registrationIdChanges,
        repository.register,
      ]);
    });

    test('logs the registration ID', () async {
      registrationIds.add('fid-1');
      await pumpEventQueue();

      expect(
        talker.history.any((log) => log.message?.contains('fid-1') ?? false),
        isTrue,
      );
    });

    test('shows a foreground message with text', () async {
      const message = NotificationMessage(title: 'T', route: '/items/1');
      foreground.add(message);
      await pumpEventQueue();

      verify(() => repository.showForeground(message)).called(1);
    });

    test('does not show a data-only foreground message', () async {
      foreground.add(const NotificationMessage(route: '/items/1'));
      await pumpEventQueue();

      verifyNever(() => repository.showForeground(any()));
    });
  });
}
