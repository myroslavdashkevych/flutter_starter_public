import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/domain/settings/repositories/settings_repository.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_starter/presentation/settings/pages/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<Result<void>> save(AppSettings settings) async => const Ok(null);
}

void main() {
  final privacyPolicyUrl = Uri.parse('https://example.invalid/privacy');
  const failureMessage =
      'Could not open the page. Check your connection and try again.';

  Future<void> pumpPage(
    WidgetTester tester, {
    Future<bool> Function(Uri url)? onOpenLink,
    VoidCallback? onLogs,
    VoidCallback? onTestCrash,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => SettingsCubit(_FakeSettingsRepository()),
          child: SettingsPage(
            appVersion: '1.2.3 (4)',
            privacyPolicyUrl: privacyPolicyUrl,
            onOpenLink: onOpenLink ?? (_) async => true,
            onLogs: onLogs,
            onTestCrash: onTestCrash,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapPrivacyPolicy(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Privacy policy'), 100);
    await tester.ensureVisible(find.text('Privacy policy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('groups the entries into sections', (tester) async {
    tester.view.physicalSize = const Size(2400, 9000);
    addTearDown(tester.view.reset);
    await pumpPage(tester, onLogs: () {}, onTestCrash: () {});

    final order = [
      'Appearance',
      'Theme',
      'Language',
      'Privacy',
      'Share usage data',
      'Privacy policy',
      'About',
      'App version',
      'Logs',
      'Test crash',
    ].map((text) => topOf(tester, text)).toList();

    expect(order, [...order]..sort());
  });

  testWidgets('SET-11: hides the dev entries without their callbacks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 9000);
    addTearDown(tester.view.reset);
    await pumpPage(tester);

    expect(find.text('Logs'), findsNothing);
    expect(find.text('Test crash'), findsNothing);
  });

  testWidgets('SET-6: the switch shows the setting and changes it', (
    tester,
  ) async {
    await pumpPage(tester);
    final tile = find.widgetWithText(SwitchListTile, 'Share usage data');
    await tester.scrollUntilVisible(tile, 100);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });

  testWidgets('SET-9: opens the privacy policy without a message', (
    tester,
  ) async {
    final opened = <Uri>[];
    await pumpPage(
      tester,
      onOpenLink: (url) async {
        opened.add(url);
        return true;
      },
    );

    await tapPrivacyPolicy(tester);

    expect(opened, [privacyPolicyUrl]);
    expect(find.text(failureMessage), findsNothing);
  });

  testWidgets('SET-9: copies the link from the message when opening fails', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpPage(tester, onOpenLink: (_) async => false);

    await tapPrivacyPolicy(tester);

    expect(find.text(failureMessage), findsOneWidget);

    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();

    expect(copied, privacyPolicyUrl.toString());
  });
}
