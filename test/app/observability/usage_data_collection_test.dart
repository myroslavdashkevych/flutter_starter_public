import 'package:flutter_starter/app/observability/usage_data_collection.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/use_case/settings/load_settings_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/save_settings_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/set_usage_data_collection_use_case.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helper/fake_analytics_service.dart';
import '../../helper/fake_crash_reporting_service.dart';
import '../../helper/mock.dart';

void main() {
  late MockSettingsRepository repository;
  late SettingsBloc settingsBloc;
  late FakeCrashReportingService crashReporting;
  late FakeAnalyticsService analytics;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
    settingsBloc = SettingsBloc(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    );
    crashReporting = FakeCrashReportingService();
    analytics = FakeAnalyticsService();
    addTearDown(settingsBloc.close);
  });

  Future<void> sync({required bool collectionAllowed}) async {
    final subscription = await syncUsageDataCollection(
      settingsBloc: settingsBloc,
      collectionAllowed: collectionAllowed,
      setUsageDataCollection: SetUsageDataCollectionUseCase(
        crashReporting,
        analytics,
      ),
    );
    addTearDown(subscription.cancel);
  }

  void expectCollection({required bool enabled}) {
    expect(crashReporting.collectionEnabled, enabled);
    expect(analytics.collectionEnabled, enabled);
  }

  Future<void> loadSetting({required bool sharing}) async {
    when(() => repository.load())
        .thenAnswer((_) async => Ok(AppSettings(usageDataSharing: sharing)));
    settingsBloc.add(const SettingsLoadRequested());
    await settingsBloc.stream.firstWhere((state) => state.isLoaded);
  }

  Future<void> change(SettingsEvent event) async {
    settingsBloc.add(event);
    await pumpEventQueue();
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

    await change(const SettingsUsageDataSharingChanged(false));
    expectCollection(enabled: false);

    await change(const SettingsUsageDataSharingChanged(true));
    expectCollection(enabled: true);
  });

  test('SET-7: turning the setting on does not override the rule', () async {
    await loadSetting(sharing: false);
    await sync(collectionAllowed: false);

    await change(const SettingsUsageDataSharingChanged(true));

    expectCollection(enabled: false);
  });

  test('other settings do not touch collection', () async {
    await loadSetting(sharing: true);
    await sync(collectionAllowed: true);
    crashReporting.collectionEnabled = null;
    analytics.collectionEnabled = null;

    await change(const SettingsThemeChanged(ThemePreference.dark));

    expect(crashReporting.collectionEnabled, isNull);
    expect(analytics.collectionEnabled, isNull);
  });
}
