import 'dart:async';

import 'package:flutter_starter/app/notification/notification_wiring.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/notification_message.dart';
import 'package:flutter_starter/domain/repository/notification_repository.dart';
import 'package:flutter_starter/domain/use_case/notification/initialize_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/register_for_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/show_foreground_notification_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_foreground_notifications_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_notification_registration_ids_use_case.dart';
import 'package:flutter_starter/domain/use_case/notification/watch_opened_notifications_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class _MockRepository extends Mock implements NotificationRepository {}

GoRouter _router() => GoRouter(
  initialLocation: '/character-list',
  routes: [
    GoRoute(
      path: '/character-list',
      builder: (_, _) => const Text('characters'),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) =>
              Text('character ${state.pathParameters['id']}'),
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

    for (final route in [
      '/character-list',
      '/character-list/1',
      '/character-list/1?source=push',
    ]) {
      test('NTF-6: accepts $route', () {
        expect(isOpenableRoute(router, route), isTrue);
      });
    }

    for (final route in [
      '',
      'characters/1',
      '/unknown',
      '/character-list/abc',
      'https://example.com/character-list/1',
      '//example.com/character-list/1',
      'myapp://character-list/1',
      ':not a uri',
    ]) {
      test('NTF-7: rejects "$route"', () {
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
        watchOpened: WatchOpenedNotificationsUseCase(repository),
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

    testWidgets('NTF-6: a tap with a valid route opens that screen', (
      tester,
    ) async {
      await start(tester);

      opened.add(const NotificationMessage(route: '/character-list/1'));
      await tester.pumpAndSettle();

      expect(find.text('character 1'), findsOneWidget);
    });

    testWidgets('NTF-6: the launch message arriving at once opens its screen', (
      tester,
    ) async {
      opened.add(const NotificationMessage(route: '/character-list/2'));
      await start(tester);
      await tester.pumpAndSettle();

      expect(find.text('character 2'), findsOneWidget);
    });

    testWidgets('NTF-7: an invalid route is ignored', (tester) async {
      await start(tester);

      opened.add(const NotificationMessage(route: '/unknown'));
      await tester.pumpAndSettle();

      expect(find.text('characters'), findsOneWidget);
    });

    testWidgets('a tap without a route stays on the current screen', (
      tester,
    ) async {
      await start(tester);

      opened.add(const NotificationMessage(title: 'No route'));
      await tester.pumpAndSettle();

      expect(find.text('characters'), findsOneWidget);
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
        initialize: InitializeNotificationsUseCase(repository),
        watchRegistrationIds: WatchNotificationRegistrationIdsUseCase(
          repository,
        ),
        watchForeground: WatchForegroundNotificationsUseCase(repository),
        showForeground: ShowForegroundNotificationUseCase(repository),
        register: RegisterForNotificationsUseCase(repository),
        talker: talker,
        channelName: 'General',
      );
    });

    tearDown(() async {
      await foreground.close();
      await registrationIds.close();
    });

    test('NTF-4: initializes with the channel name and registers', () {
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

    test('NTF-4: shows a foreground message with text', () async {
      const message = NotificationMessage(
        title: 'T',
        route: '/character-list/1',
      );
      foreground.add(message);
      await pumpEventQueue();

      verify(() => repository.showForeground(message)).called(1);
    });

    test('does not show a data-only foreground message', () async {
      foreground.add(const NotificationMessage(route: '/character-list/1'));
      await pumpEventQueue();

      verifyNever(() => repository.showForeground(any()));
    });
  });
}
