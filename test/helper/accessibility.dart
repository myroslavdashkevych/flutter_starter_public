import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_starter/presentation/_shared/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _PendingCacheManager extends Mock implements BaseCacheManager {}

/// Builds a screen in its main state with [theme].
typedef AccessibilityPump = Future<void> Function(
  WidgetTester tester,
  ThemeData theme,
);

/// Checks ACC-1 to ACC-4 on the screen that [pump] builds.
void testAccessibility(AccessibilityPump pump) {
  group('accessibility', () {
    testWidgets('ACC-1: every tap target has a label', (tester) async {
      await _checkOnPhone(tester, () async {
        await pump(tester, AppTheme.light);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    });

    testWidgets('ACC-2: tap targets meet the minimum size', (tester) async {
      await _checkOnPhone(tester, () async {
        await pump(tester, AppTheme.light);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      });
    });

    // One test per theme: MaterialApp animates a theme change, so switching
    // themes in one tree would check the old theme.
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      testWidgets(
        'ACC-3: text contrast meets WCAG AA in the ${theme.brightness.name} '
        'theme',
        (tester) async {
          await _checkOnPhone(tester, () async {
            await pump(tester, theme);
            final context = tester.element(find.byType(Scaffold).first);
            expect(Theme.of(context).brightness, theme.brightness);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          });
        },
      );
    }

    testWidgets('ACC-4: no overflow at 200% text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _checkOnPhone(tester, () async {
        await pump(tester, AppTheme.light);
        final context = tester.element(find.byType(Scaffold).first);
        expect(MediaQuery.textScalerOf(context).scale(10), 20);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

/// Runs [check] on a phone-sized view with semantics enabled, with network
/// images that stay loading.
Future<void> _checkOnPhone(
  WidgetTester tester,
  Future<void> Function() check,
) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // The default cache manager needs path_provider, which has no
  // implementation in tests; whether its failure surfaces depends on the
  // order of the tests.
  final cacheManager = _PendingCacheManager();
  when(
    () => cacheManager.getFileStream(
      any(),
      key: any(named: 'key'),
      headers: any(named: 'headers'),
      withProgress: any(named: 'withProgress'),
    ),
  ).thenAnswer((_) => StreamController<FileResponse>().stream);
  final defaultCacheManager = CachedNetworkImageProvider.defaultCacheManager;
  CachedNetworkImageProvider.defaultCacheManager = cacheManager;
  addTearDown(
    () => CachedNetworkImageProvider.defaultCacheManager = defaultCacheManager,
  );
  imageCache.clear();
  // Disposed in the test body: the binding checks for live handles before
  // tear-downs run.
  final semantics = tester.ensureSemantics();
  try {
    await check();
  } finally {
    semantics.dispose();
  }
}
