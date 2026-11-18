import 'package:dio/dio.dart';
import 'package:flutter_starter/app/config/app_config.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/di/config_module/network_module.dart';
import 'package:flutter_starter/data/_shared/data_source/network/token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

class _MockTokenProvider extends Mock implements TokenProvider {}

class _NetworkModule extends NetworkModule {}

void main() {
  final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));

  /// Both clients of [flavor], as DI builds them.
  List<Dio> clients(Flavor flavor) {
    final config = AppConfig(
      flavor: flavor,
      rickAndMortyApiBaseUrl: 'https://characters.invalid',
      backendBaseUrl: 'https://backend.invalid',
      characterCacheTtlMinutes: 30,
      privacyPolicyUrl: 'https://privacy.invalid',
      usageDataSharingDefault: true,
    );
    final module = _NetworkModule();
    return [
      module.publicDio(config, talker),
      module.backendDio(config, _MockTokenProvider(), talker),
    ];
  }

  TalkerDioLoggerSettings loggerSettings(Dio dio) =>
      dio.interceptors.whereType<TalkerDioLogger>().single.settings;

  test('OBS-6: prod logs requests without their bodies', () {
    for (final dio in clients(Flavor.prod)) {
      final settings = loggerSettings(dio);

      expect(settings.printRequestData, isFalse);
      expect(settings.printResponseData, isFalse);
      expect(settings.printErrorData, isFalse);
    }
  });

  test('OBS-6: dev logs requests with their bodies', () {
    for (final dio in clients(Flavor.dev)) {
      final settings = loggerSettings(dio);

      expect(settings.printRequestData, isTrue);
      expect(settings.printResponseData, isTrue);
      expect(settings.printErrorData, isTrue);
    }
  });
}
