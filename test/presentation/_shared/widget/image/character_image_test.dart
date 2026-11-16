import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_starter/presentation/_shared/widget/image/character_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockCacheManager extends Mock implements BaseCacheManager {}

void main() {
  const urlA = 'https://example.invalid/a.jpeg';
  const urlB = 'https://example.invalid/b.jpeg';
  final brokenIcon = find.byIcon(Icons.broken_image_outlined);

  late _MockCacheManager cacheManager;

  void verifyDownloads(String url, int count) {
    verify(
      () => cacheManager.getFileStream(
        url,
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).called(count);
  }

  Future<void> pumpImage(WidgetTester tester, String url) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterImage(url: url, cacheManager: cacheManager),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> waitForRetry(WidgetTester tester) async {
    await tester.pump(CharacterImage.retryDelay);
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    cacheManager = _MockCacheManager();
    imageCache.clear();
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => Stream.error(Exception('Too many requests')));
  });

  testWidgets('CHR-9: retries a failed download, then shows the icon', (
    tester,
  ) async {
    await pumpImage(tester, urlA);
    expect(brokenIcon, findsNothing);

    for (var retry = 0; retry < CharacterImage.maxRetries; retry++) {
      await waitForRetry(tester);
    }
    expect(brokenIcon, findsOneWidget);

    await waitForRetry(tester);
    verifyDownloads(urlA, CharacterImage.maxRetries + 1);
  });

  testWidgets('CHR-9: waits for the delay before retrying', (tester) async {
    await pumpImage(tester, urlA);

    await tester.pump(CharacterImage.retryDelay - const Duration(seconds: 1));
    await tester.pump();

    verifyDownloads(urlA, 1);
  });

  testWidgets('CHR-9: a new url starts with all its retries', (tester) async {
    await pumpImage(tester, urlA);
    for (var retry = 0; retry < CharacterImage.maxRetries; retry++) {
      await waitForRetry(tester);
    }
    expect(brokenIcon, findsOneWidget);

    await pumpImage(tester, urlB);
    await waitForRetry(tester);

    expect(brokenIcon, findsNothing);
  });

  testWidgets('removing the image cancels the retry', (tester) async {
    await pumpImage(tester, urlA);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(CharacterImage.retryDelay);

    verifyDownloads(urlA, 1);
  });
}
