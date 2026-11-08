import 'package:flutter_starter/app/observability/usage_data_collection.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_analytics_service.dart';
import '../../helpers/fake_crash_reporting_service.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockSettingsRepository repository;
  late SettingsCubit cubit;
  late FakeCrashReportingService crashReporting;
  late FakeAnalyticsService analytics;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
    cubit = SettingsCubit(repository);
    crashReporting = FakeCrashReportingService();
    analytics = FakeAnalyticsService();
    addTearDown(cubit.close);
  });

  Future<void> sync({required bool collectionAllowed}) async {
    final subscription = await syncUsageDataCollection(
      settingsCubit: cubit,
      collectionAllowed: collectionAllowed,
      crashReporting: crashReporting,
      analytics: analytics,
    );
    addTearDown(subscription.cancel);
  }

  void expectCollection({required bool enabled}) {
    expect(crashReporting.collectionEnabled, enabled);
    expect(analytics.collectionEnabled, enabled);
  }

  Future<void> loadSetting({required bool sharing}) async {
    when(() => repository.load())
        .thenAnswer((_) async => AppSettings(usageDataSharing: sharing));
    await cubit.load();
  }

  test(
    'SET-7: on start, collects when the rule and the setting allow it',
    () async {
      await loadSetting(sharing: true);

      await sync(collectionAllowed: true);

      expectCollection(enabled: true);
    },
  );

  test('SET-7: on start, a setting turned off stops collection', () async {
    await loadSetting(sharing: false);

    await sync(collectionAllowed: true);

    expectCollection(enabled: false);
  });

  test('SET-7: the rule wins over a setting turned on', () async {
    await loadSetting(sharing: true);

    await sync(collectionAllowed: false);

    expectCollection(enabled: false);
  });

  test('SET-7: a change applies right away, in both directions', () async {
    await loadSetting(sharing: true);
    await sync(collectionAllowed: true);

    await cubit.setUsageDataSharing(false);
    await Future<void>.delayed(Duration.zero);
    expectCollection(enabled: false);

    await cubit.setUsageDataSharing(true);
    await Future<void>.delayed(Duration.zero);
    expectCollection(enabled: true);
  });

  test('SET-7: turning the setting on does not override the rule', () async {
    await loadSetting(sharing: false);
    await sync(collectionAllowed: false);

    await cubit.setUsageDataSharing(true);
    await Future<void>.delayed(Duration.zero);

    expectCollection(enabled: false);
  });

  test('other settings do not touch collection', () async {
    await loadSetting(sharing: true);
    await sync(collectionAllowed: true);
    crashReporting.collectionEnabled = null;
    analytics.collectionEnabled = null;

    await cubit.setTheme(ThemePreference.dark);
    await Future<void>.delayed(Duration.zero);

    expect(crashReporting.collectionEnabled, isNull);
    expect(analytics.collectionEnabled, isNull);
  });
}
