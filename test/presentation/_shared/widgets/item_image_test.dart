import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter/presentation/_shared/widgets/item_image.dart';
import 'package:flutter_test/flutter_test.dart';
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
        home: ItemImage(url: url, cacheManager: cacheManager),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> waitForRetry(WidgetTester tester) async {
    await tester.pump(ItemImage.retryDelay);
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

  testWidgets('retries a failed download, then shows the icon', (tester) async {
    await pumpImage(tester, urlA);
    expect(brokenIcon, findsNothing);

    for (var retry = 0; retry < ItemImage.maxRetries; retry++) {
      await waitForRetry(tester);
    }
    expect(brokenIcon, findsOneWidget);

    await waitForRetry(tester);
    verifyDownloads(urlA, ItemImage.maxRetries + 1);
  });

  testWidgets('waits for the delay before retrying', (tester) async {
    await pumpImage(tester, urlA);

    await tester.pump(ItemImage.retryDelay - const Duration(seconds: 1));
    await tester.pump();

    verifyDownloads(urlA, 1);
  });

  testWidgets('a new url starts with all its retries', (tester) async {
    await pumpImage(tester, urlA);
    for (var retry = 0; retry < ItemImage.maxRetries; retry++) {
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
    await tester.pump(ItemImage.retryDelay);

    verifyDownloads(urlA, 1);
  });
}
