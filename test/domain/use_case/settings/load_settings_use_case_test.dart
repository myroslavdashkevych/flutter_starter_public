import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/use_case/settings/load_settings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/mock.dart';

void main() {
  late MockSettingsRepository repository;

  setUp(() => repository = MockSettingsRepository());

  test('passes stored settings through', () async {
    const stored = AppSettings(
      themePreference: ThemePreference.dark,
      localePreference: LocalePreference.uk,
      usageDataSharing: false,
    );
    when(() => repository.load()).thenAnswer((_) async => const Ok(stored));

    final result = await LoadSettingsUseCase(repository)(());

    expect(
      result,
      isA<Ok<AppSettings>>().having((ok) => ok.value, 'v', stored),
    );
  });

  test('passes the repository result through unchanged', () async {
    when(() => repository.load())
        .thenAnswer((_) async => const Err(Failure.cache()));

    final result = await LoadSettingsUseCase(repository)(());

    expect(
      result,
      isA<Err<AppSettings>>().having(
        (err) => err.failure,
        'failure',
        const Failure.cache(),
      ),
    );
  });
}
