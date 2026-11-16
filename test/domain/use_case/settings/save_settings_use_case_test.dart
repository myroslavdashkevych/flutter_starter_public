import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/use_case/settings/save_settings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/mock.dart';

void main() {
  const settings = AppSettings(themePreference: ThemePreference.dark);

  late MockSettingsRepository repository;

  setUpAll(registerFallbackValues);

  setUp(() => repository = MockSettingsRepository());

  test('saves the settings and passes the success through', () async {
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));

    final result = await SaveSettingsUseCase(repository)((settings: settings));

    expect(result, isA<Ok<void>>());
    verify(() => repository.save(settings)).called(1);
  });

  test('passes a failure through', () async {
    when(() => repository.save(any()))
        .thenAnswer((_) async => const Err(Failure.cache()));

    final result = await SaveSettingsUseCase(repository)((settings: settings));

    expect(
      result,
      isA<Err<void>>().having(
        (err) => err.failure,
        'failure',
        const Failure.cache(),
      ),
    );
  });
}
