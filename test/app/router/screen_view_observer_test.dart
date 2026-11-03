import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_starter/app/router/screen_view_observer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> screens;
  late ScreenViewObserver observer;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    screens = [];
    observer = ScreenViewObserver(screens.add);
    navigatorKey = GlobalKey();
  });

  Route<void> page(String? name) => MaterialPageRoute(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox(),
  );

  NavigatorState navigator() => navigatorKey.currentState!;

  Future<void> pumpNavigator(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        onGenerateRoute: (_) => page('first'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a push reports the new screen', (tester) async {
    await pumpNavigator(tester);

    unawaited(navigator().push(page('second')));
    await tester.pumpAndSettle();

    expect(screens, ['first', 'second']);
    expect(observer.currentName, 'second');
  });

  testWidgets('a pop reports the screen returned to', (tester) async {
    await pumpNavigator(tester);
    unawaited(navigator().push(page('second')));
    await tester.pumpAndSettle();
    screens.clear();

    navigator().pop();
    await tester.pumpAndSettle();

    expect(screens, ['first']);
    expect(observer.currentName, 'first');
  });

  testWidgets('a replace reports the new screen', (tester) async {
    await pumpNavigator(tester);
    screens.clear();

    navigator().pushReplacement<void, void>(page('other'));
    await tester.pumpAndSettle();

    expect(screens, ['other']);
    expect(observer.currentName, 'other');
  });

  testWidgets('a dialog reports nothing, opened or closed', (tester) async {
    await pumpNavigator(tester);
    screens.clear();

    unawaited(
      showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (_) => const AlertDialog(title: Text('dialog')),
      ),
    );
    await tester.pumpAndSettle();
    expect(screens, isEmpty);

    navigator().pop();
    await tester.pumpAndSettle();

    expect(screens, isEmpty);
    expect(observer.currentName, 'first');
  });

  testWidgets('a bottom sheet reports nothing', (tester) async {
    await pumpNavigator(tester);
    screens.clear();

    unawaited(
      showModalBottomSheet<void>(
        context: navigatorKey.currentContext!,
        builder: (_) => const Text('sheet'),
      ),
    );
    await tester.pumpAndSettle();
    navigator().pop();
    await tester.pumpAndSettle();

    expect(screens, isEmpty);
  });

  testWidgets('a route without a name reports nothing on push', (tester) async {
    await pumpNavigator(tester);
    screens.clear();

    unawaited(navigator().push(page(null)));
    await tester.pumpAndSettle();

    expect(screens, isEmpty);
  });

  testWidgets('ignores a route of another navigator', (tester) async {
    final inner = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: const RouteSettings(name: 'first'),
          builder: (_) =>
              Navigator(key: inner, onGenerateRoute: (_) => page('inner')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final route = page('inner second');
    unawaited(inner.currentState!.push(route));
    await tester.pumpAndSettle();
    screens.clear();

    observer.didPush(route, null);

    expect(screens, isEmpty);
    expect(observer.currentName, 'first');
  });

  testWidgets('a pop to a route without a name asks for the covered screen', (
    tester,
  ) async {
    observer = ScreenViewObserver(screens.add, coveredScreenName: () => 'tab');
    await pumpNavigator(tester);
    unawaited(navigator().push(page(null)));
    await tester.pumpAndSettle();
    unawaited(navigator().push(page('auth')));
    await tester.pumpAndSettle();
    screens.clear();

    navigator().pop();
    await tester.pumpAndSettle();

    expect(screens, ['tab']);
  });
}
