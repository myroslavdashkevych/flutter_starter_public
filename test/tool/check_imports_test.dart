import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_imports.dart';

const _own = 'package:flutter_starter';

void main() {
  void expectAllowed(String path, String uri) {
    expect(checkImport(path, uri), isNull, reason: '$path -> $uri');
  }

  void expectForbidden(String path, String uri) {
    expect(checkImport(path, uri), isNotNull, reason: '$path -> $uri');
  }

  void expectLocationAccepted(Iterable<String> paths) {
    for (final path in paths) {
      expect(checkLocation(path), isNull, reason: path);
    }
  }

  void expectLocationRejected(Iterable<String> paths) {
    for (final path in paths) {
      expect(checkLocation(path), isNotNull, reason: path);
    }
  }

  String domain(String rest) => '$_own/domain/$rest';

  group('app', () {
    test('may import everything', () {
      for (final target in [
        'data/character/a.dart',
        'domain/entity/a.dart',
        'presentation/character_list/a.dart',
        'l10n/gen/a.dart',
        'shared/a.dart',
      ]) {
        expectAllowed('lib/app/app.dart', '$_own/$target');
      }
      expectAllowed('lib/app/app.dart', 'package:firebase_core/a.dart');
    });

    test('main.dart may import app', () {
      expectAllowed('lib/main.dart', '$_own/app/bootstrap.dart');
    });
  });

  group('shared', () {
    const path = 'lib/shared/logging/a.dart';

    test('may import shared and packages from the allowed list', () {
      expectAllowed(path, '$_own/shared/utils/b.dart');
      expectAllowed(path, 'package:talker/talker.dart');
      expectAllowed(path, 'package:injectable/injectable.dart');
      expectAllowed(path, 'package:meta/meta.dart');
      expectAllowed(path, 'package:collection/collection.dart');
      expectAllowed(path, 'dart:async');
    });

    test('must not import other packages', () {
      expectForbidden(path, 'package:flutter/foundation.dart');
      expectForbidden(path, 'package:dio/dio.dart');
      expectForbidden(path, 'package:shimmer/shimmer.dart');
    });

    test('must not import any layer, app or l10n', () {
      for (final module in ['domain', 'data', 'presentation', 'app', 'l10n']) {
        expectForbidden(path, '$_own/$module/a/b.dart');
      }
    });
  });

  group('domain', () {
    const path = 'lib/domain/entity/character.dart';

    test('may import shared and its own kind', () {
      expectAllowed(path, '$_own/shared/utils/a.dart');
      expectAllowed(path, domain('entity/other.dart'));
    });

    test('may import pure Dart packages from the allowed list', () {
      expectAllowed(path, 'package:freezed_annotation/freezed_annotation.dart');
      expectAllowed(path, 'package:meta/meta.dart');
      expectAllowed(path, 'package:collection/collection.dart');
      expectAllowed(path, 'package:stream_transform/stream_transform.dart');
      expectAllowed(path, 'dart:async');
    });

    test('must not import data, presentation, app or l10n', () {
      for (final module in ['data', 'presentation', 'app', 'l10n']) {
        expectForbidden(path, '$_own/$module/a/b.dart');
      }
    });

    test('must not import Flutter, dio, hive or firebase', () {
      expectForbidden(path, 'package:flutter/material.dart');
      expectForbidden(path, 'package:dio/dio.dart');
      expectForbidden(path, 'package:hive_ce/hive.dart');
      expectForbidden(path, 'package:firebase_auth/firebase_auth.dart');
    });

    test('must not import platform dart: libraries', () {
      for (final uri in [
        'dart:ui',
        'dart:io',
        'dart:ffi',
        'dart:isolate',
        'dart:html',
      ]) {
        expectForbidden(path, uri);
      }
    });

    test('must not import get_it', () {
      expect(
        checkImport(path, 'package:get_it/get_it.dart'),
        'domain must not import package:get_it/get_it.dart',
      );
    });

    test('may import only the main library of injectable', () {
      expectAllowed(path, 'package:injectable/injectable.dart');
      expectForbidden(path, 'package:injectable/src/a.dart');
    });
  });

  group('domain layout', () {
    test('accepts files in each kind, use case groups and _shared roles', () {
      expectLocationAccepted([
        'lib/domain/entity/character.dart',
        'lib/domain/repository/character_repository.dart',
        'lib/domain/use_case/character/get_characters_page_use_case.dart',
        'lib/domain/_shared/base/use_case/use_case.dart',
        'lib/domain/_shared/base/use_case/stream_use_case.dart',
        'lib/domain/_shared/service/analytics/analytics_service.dart',
        'lib/domain/_shared/service/crash_reporting/crash_reporting_service.dart',
        'lib/domain/_shared/wrapper/result/failure.dart',
        'lib/domain/_shared/wrapper/pagination/paginated.dart',
      ]);
    });

    test('rejects other _shared roles and wrong depths in _shared', () {
      expectLocationRejected([
        'lib/domain/_shared/a.dart',
        'lib/domain/_shared/other/a.dart',
        'lib/domain/_shared/other/sub/a.dart',
        'lib/domain/_shared/base/use_case.dart',
        'lib/domain/_shared/wrapper/result.dart',
        'lib/domain/_shared/wrapper/result/sub/a.dart',
        'lib/domain/_shared/service/crash_reporting_service.dart',
        'lib/domain/_shared/service/analytics/sub/a.dart',
      ]);
    });

    test('use case files live only in a group or in _shared/base/use_case', () {
      expect(
        checkLocation('lib/domain/_shared/service/a_use_case.dart'),
        '*_use_case.dart files live in domain/use_case',
      );
    });

    test('rejects a use case outside a group folder', () {
      expect(
        checkLocation('lib/domain/use_case/get_characters_page_use_case.dart'),
        startsWith('a use case lives in a group folder of domain/use_case'),
      );
    });

    test('rejects area folders and files outside a kind', () {
      expectLocationRejected([
        'lib/domain/character/a.dart',
        'lib/domain/result/result.dart',
        'lib/domain/service/a.dart',
        'lib/domain/a.dart',
      ]);
    });

    test('rejects subfolders, except one level in use_case', () {
      expectLocationRejected([
        'lib/domain/entity/sub/a.dart',
        'lib/domain/entity/base/a.dart',
        'lib/domain/use_case/character/sub/a.dart',
      ]);
    });
  });

  group('use case groups', () {
    List<String> rules(Map<String, String> files) =>
        checkFiles(files).map((v) => v.rule).toList();

    test('accepts a business area with a contract and observability', () {
      expect(
        rules({
          'lib/domain/repository/character_repository.dart': '',
          'lib/domain/use_case/character/a.dart': '',
          'lib/domain/use_case/observability/b.dart': '',
        }).where((rule) => rule.contains('not a use case group')),
        isEmpty,
      );
    });

    test('rejects a group without a contract, and base as a group', () {
      final found = rules({
        'lib/domain/repository/character_repository.dart': '',
        'lib/domain/use_case/profile/a.dart': '',
        'lib/domain/use_case/base/b.dart': '',
      });
      expect(
        found,
        contains(startsWith('domain/use_case/profile is not a use case group')),
      );
      expect(
        found,
        contains(startsWith('domain/use_case/base is not a use case group')),
      );
    });
  });

  group('domain imports by kind', () {
    const wrapper = '_shared/wrapper/result/result.dart';
    const base = '_shared/base/use_case/use_case.dart';
    const port = '_shared/service/analytics/analytics_service.dart';

    test('entities import only entities', () {
      const path = 'lib/domain/entity/character.dart';
      expectAllowed(path, domain('entity/other.dart'));
      for (final to in [
        wrapper,
        base,
        port,
        'repository/b.dart',
        'use_case/character/b.dart',
      ]) {
        expectForbidden(path, domain(to));
      }
    });

    test('_shared imports only _shared: wrappers only wrappers', () {
      const path = 'lib/domain/_shared/wrapper/result/result.dart';
      expectAllowed(path, domain('_shared/wrapper/result/failure.dart'));
      expectAllowed(path, domain('_shared/wrapper/pagination/paginated.dart'));
      for (final to in [
        base,
        port,
        'entity/b.dart',
        'repository/b.dart',
        'use_case/character/b.dart',
      ]) {
        expectForbidden(path, domain(to));
      }
    });

    test('base classes import only base and wrappers', () {
      const path = 'lib/domain/_shared/base/use_case/use_case.dart';
      expectAllowed(path, domain(wrapper));
      expectAllowed(path, domain('_shared/base/use_case/stream_use_case.dart'));
      for (final to in [port, 'entity/b.dart', 'repository/b.dart']) {
        expectForbidden(path, domain(to));
      }
    });

    test('repositories import only entities and wrappers', () {
      const path = 'lib/domain/repository/character_repository.dart';
      expectAllowed(path, domain('entity/character.dart'));
      expectAllowed(path, domain(wrapper));
      for (final to in [
        base,
        port,
        'repository/b.dart',
        'use_case/character/b.dart',
      ]) {
        expectForbidden(path, domain(to));
      }
    });

    test('services import only services', () {
      const path =
          'lib/domain/_shared/service/analytics/analytics_service.dart';
      expectAllowed(
        path,
        domain('_shared/service/analytics/analytics_event.dart'),
      );
      for (final to in [
        wrapper,
        base,
        'entity/b.dart',
        'repository/b.dart',
        'use_case/character/b.dart',
      ]) {
        expectForbidden(path, domain(to));
      }
    });

    test('use cases import everything except another use case', () {
      const path = 'lib/domain/use_case/character/get_character_use_case.dart';
      for (final to in [
        wrapper,
        base,
        port,
        'entity/b.dart',
        'repository/b.dart',
      ]) {
        expectAllowed(path, domain(to));
      }
    });

    test('a use case must not import another use case, in any group', () {
      const path = 'lib/domain/use_case/character/get_character_use_case.dart';
      for (final other in [
        'use_case/character/get_characters_use_case.dart',
        'use_case/auth/sign_in_use_case.dart',
      ]) {
        expect(
          checkImport(path, domain(other)),
          startsWith('a use case must not import another use case'),
          reason: other,
        );
      }
    });

    test('a base class must not import a use case either', () {
      const path = 'lib/domain/_shared/base/use_case/use_case.dart';
      expectForbidden(
        path,
        domain('use_case/character/get_characters_use_case.dart'),
      );
    });

    test('relative imports follow the same rules', () {
      const path = 'lib/domain/use_case/character/a_use_case.dart';
      expectAllowed(path, '../../entity/b.dart');
      expectAllowed(path, '../../_shared/base/use_case/use_case.dart');
      expectForbidden(path, 'b_use_case.dart');
      expectForbidden(path, '../auth/c_use_case.dart');
    });
  });

  group('data', () {
    const path =
        'lib/data/character/data_source/character_api_data_source.dart';

    test('may import shared, data/_shared and its own area', () {
      expectAllowed(path, '$_own/shared/utils/a.dart');
      expectAllowed(path, '$_own/data/_shared/data_source/network/a.dart');
      expectAllowed(path, '$_own/data/_shared/base/data_source/a.dart');
      expectAllowed(path, '$_own/data/character/model/a.dart');
    });

    test('may import data packages', () {
      expectAllowed(path, 'package:dio/dio.dart');
      expectAllowed(path, 'package:hive_ce/hive.dart');
      expectAllowed(path, 'dart:io');
    });

    test('may import only the non-UI libraries of Flutter', () {
      expectAllowed(path, 'package:flutter/foundation.dart');
      expectAllowed(path, 'package:flutter/services.dart');
      expectForbidden(path, 'package:flutter/material.dart');
      expectForbidden(path, 'package:flutter/widgets.dart');
      expectForbidden(path, 'package:flutter/cupertino.dart');
    });

    test('must not import presentation, app or l10n', () {
      for (final module in ['presentation', 'app', 'l10n']) {
        expectForbidden(path, '$_own/$module/a/b.dart');
      }
    });

    test('areas must not import each other', () {
      expectForbidden(path, '$_own/data/auth/model/a.dart');
      expectForbidden(path, '$_own/data/auth/entity/a.dart');
    });

    test('_shared must not import any area', () {
      expectForbidden(
        'lib/data/_shared/data_source/network/a.dart',
        '$_own/data/character/model/a.dart',
      );
    });
  });

  group('data imports from domain', () {
    const path =
        'lib/data/character/data_source/character_api_data_source.dart';
    const sharedServices = 'lib/data/_shared/service/a.dart';

    test('a data area may import its own contract', () {
      expectAllowed(path, domain('repository/character_repository.dart'));
      expectAllowed(
        'lib/data/character/character_repository_impl.dart',
        domain('repository/character_repository.dart'),
      );
    });

    test('a data area must not import the contract of another area', () {
      expect(
        checkImport(path, domain('repository/auth_repository.dart')),
        startsWith('data/character must not import domain/repository/'),
      );
      expectForbidden(path, domain('repository/sub/character_repository.dart'));
    });

    test('data must not import use cases', () {
      expectForbidden(path, domain('use_case/character/a_use_case.dart'));
      expectForbidden(path, domain('_shared/base/use_case/use_case.dart'));
      expectForbidden(
        sharedServices,
        domain('use_case/character/a_use_case.dart'),
      );
    });

    test('only data/_shared/service may import domain services', () {
      const port = '_shared/service/analytics/analytics_service.dart';
      expectForbidden(path, domain(port));
      expectForbidden(
        'lib/data/_shared/data_source/network/a.dart',
        domain(port),
      );
      expectAllowed(sharedServices, domain(port));
    });

    test('data/_shared/service must not import repository contracts', () {
      expectForbidden(sharedServices, domain('repository/a_repository.dart'));
    });

    test('data may import entities and wrappers', () {
      for (final from in [
        path,
        sharedServices,
        'lib/data/_shared/data_source/network/a.dart',
      ]) {
        expectAllowed(from, domain('entity/app_user.dart'));
        expectAllowed(from, domain('_shared/wrapper/result/failure.dart'));
        expectAllowed(
          from,
          domain('_shared/wrapper/pagination/paginated.dart'),
        );
      }
    });
  });

  group('presentation', () {
    const path = 'lib/presentation/character_list/widget/a.dart';

    test('may import shared, presentation/_shared, l10n and itself', () {
      expectAllowed(path, '$_own/shared/utils/a.dart');
      expectAllowed(path, '$_own/presentation/_shared/theme/a.dart');
      expectAllowed(path, '$_own/presentation/character_list/page/a.dart');
      expectAllowed(path, '$_own/l10n/gen/app_localizations.dart');
    });

    test('pages and widgets may import Flutter', () {
      expectAllowed(
        'lib/presentation/character_list/page/character_list_page.dart',
        'package:flutter/material.dart',
      );
    });

    test('Bloc files may import only flutter/foundation.dart', () {
      for (final file in [
        'bloc/character_list_bloc.dart',
        'bloc/character_list_event.dart',
        'bloc/character_list_state.dart',
      ]) {
        final blocPath = 'lib/presentation/character_list/$file';
        expectAllowed(blocPath, 'package:flutter/foundation.dart');
        expectAllowed(blocPath, 'package:flutter_bloc/flutter_bloc.dart');
        expectForbidden(blocPath, 'package:flutter/material.dart');
        expectForbidden(blocPath, 'package:flutter/widgets.dart');
        expectForbidden(blocPath, 'package:material_ui/material_ui.dart');
        expectForbidden(blocPath, 'package:cupertino_ui/cupertino_ui.dart');
      }
    });

    test('pages and widgets may import the design packages', () {
      for (final uri in [
        'package:material_ui/material_ui.dart',
        'package:cupertino_ui/cupertino_ui.dart',
      ]) {
        expectAllowed(
          'lib/presentation/character_list/page/character_list_page.dart',
          uri,
        );
      }
    });

    test('must not import data or app', () {
      expectForbidden(path, '$_own/data/character/model/a.dart');
      expectForbidden(path, '$_own/app/router/routes.dart');
    });

    test('features must not import each other', () {
      expectForbidden(path, '$_own/presentation/character_detail/page/a.dart');
    });

    test('_shared must not import any feature', () {
      expectForbidden(
        'lib/presentation/_shared/widget/a.dart',
        '$_own/presentation/character_list/page/a.dart',
      );
    });
  });

  group('presentation imports from domain', () {
    const bloc =
        'lib/presentation/character_list/bloc/character_list_bloc.dart';
    const page =
        'lib/presentation/character_list/page/character_list_page.dart';

    test('Bloc files may import use cases', () {
      for (final file in ['bloc', 'event', 'state']) {
        expectAllowed(
          'lib/presentation/character_list/bloc/character_list_$file.dart',
          domain('use_case/character/get_characters_page_use_case.dart'),
        );
      }
    });

    test('Bloc files may import use cases of any group', () {
      expectAllowed(bloc, domain('use_case/auth/sign_in_use_case.dart'));
    });

    test(
      'Bloc files must not import base classes, repositories or services',
      () {
        expectForbidden(bloc, domain('_shared/base/use_case/use_case.dart'));
        expectForbidden(bloc, domain('repository/character_repository.dart'));
        expectForbidden(
          bloc,
          domain('_shared/service/analytics/analytics_service.dart'),
        );
      },
    );

    test('a page must not import use cases, repositories or services', () {
      expectForbidden(
        page,
        domain('use_case/character/get_characters_page_use_case.dart'),
      );
      expectForbidden(page, domain('repository/character_repository.dart'));
      expectForbidden(
        page,
        domain('_shared/service/analytics/analytics_service.dart'),
      );
    });

    test('Bloc files and pages may import entities and wrappers', () {
      for (final from in [bloc, page]) {
        expectAllowed(from, domain('entity/character.dart'));
        expectAllowed(from, domain('_shared/wrapper/result/failure.dart'));
        expectAllowed(
          from,
          domain('_shared/wrapper/pagination/paginated.dart'),
        );
      }
    });
  });

  group('app imports from domain/_shared', () {
    test('app and main.dart import only the crash reporting port', () {
      for (final from in ['lib/app/bootstrap.dart', 'lib/main.dart']) {
        expectAllowed(
          from,
          domain(
            '_shared/service/crash_reporting/crash_reporting_service.dart',
          ),
        );
        expect(
          checkImport(
            from,
            domain('_shared/service/analytics/analytics_service.dart'),
          ),
          startsWith('app imports from domain/_shared/service only'),
          reason: from,
        );
      }
    });

    test('generated DI code may import every port', () {
      expectAllowed(
        'lib/app/di/injection.config.dart',
        domain('_shared/service/analytics/analytics_service.dart'),
      );
    });

    test('app must not import base classes', () {
      expect(
        checkImport(
          'lib/app/router/routes.dart',
          domain('_shared/base/use_case/use_case.dart'),
        ),
        startsWith('only use cases import domain/_shared/base'),
      );
    });

    test('app may import use cases, repositories, entities and wrappers', () {
      const from = 'lib/app/bootstrap.dart';
      for (final to in [
        'use_case/character/get_characters_page_use_case.dart',
        'repository/character_repository.dart',
        'entity/character.dart',
        '_shared/wrapper/result/result.dart',
      ]) {
        expectAllowed(from, domain(to));
      }
    });
  });

  group('service implementations', () {
    const ports = {
      'lib/domain/_shared/service/analytics/analytics_service.dart': '',
      'lib/domain/_shared/service/analytics/analytics_event.dart': '',
      'lib/domain/_shared/service/crash_reporting/crash_reporting_service.dart':
          '',
    };
    const analytics = 'lib/data/_shared/service/analytics';

    List<String> rules(Map<String, String> files) =>
        checkFiles({...ports, ...files})
            .map((v) => v.rule)
            .where((rule) => rule.contains('Files and types'))
            .toList();

    test('accepts <sdk>_<port>.dart implementing the port, and a module', () {
      expect(
        rules({
          '$analytics/firebase_analytics_service.dart':
              'class FirebaseAnalyticsService implements AnalyticsService {}\n',
          '$analytics/firebase_analytics_module.dart': '',
        }),
        isEmpty,
      );
    });

    test('rejects a file outside a folder of a service', () {
      const rule =
          'data/_shared/service holds one folder per service, named like '
          'its folder in domain/_shared/service';
      expect(
        rules({
          'lib/data/_shared/service/firebase_analytics_service.dart':
              'class FirebaseAnalyticsService implements AnalyticsService {}\n',
          'lib/data/_shared/service/tracking/firebase_analytics_service.dart':
              'class FirebaseAnalyticsService implements AnalyticsService {}\n',
          '$analytics/sub/firebase_analytics_service.dart': '',
        }),
        [startsWith(rule), startsWith(rule), startsWith(rule)],
      );
    });

    test('rejects a port of another service folder', () {
      expect(
        rules({
          '$analytics/firebase_crash_reporting_service.dart':
              'class FirebaseCrashReportingService '
              'implements CrashReportingService {}\n',
        }),
        [
          startsWith(
            'a file in data/_shared/service/analytics is <sdk>_<port>.dart',
          ),
        ],
      );
    });

    test('rejects a file named after no port', () {
      expect(
        rules({
          '$analytics/analytics_service_impl.dart':
              'class AnalyticsServiceImpl implements AnalyticsService {}\n',
        }),
        [
          startsWith(
            'a file in data/_shared/service/analytics is <sdk>_<port>.dart',
          ),
        ],
      );
    });

    test('rejects a port name without an SDK prefix', () {
      expect(
        rules({
          '$analytics/analytics_service.dart': 'class AnalyticsService {}\n',
        }),
        [
          startsWith(
            'a file in data/_shared/service/analytics is <sdk>_<port>.dart',
          ),
        ],
      );
    });

    test('rejects a class that does not implement its port', () {
      expect(
        rules({
          '$analytics/firebase_analytics_service.dart':
              'class FirebaseAnalyticsService {}\n',
        }),
        [
          startsWith(
            'the class in firebase_analytics_service.dart implements '
            'AnalyticsService',
          ),
        ],
      );
    });
  });

  group('evicted caches', () {
    const cachePath =
        'lib/data/character/data_source/character_hive_data_source.dart';
    const cache = 'class CharacterHiveDataSource implements ExpiringCache {}\n';

    List<String> rules(Map<String, String> files) =>
        checkFiles(files)
            .map((v) => v.rule)
            .where((rule) => rule.contains('is a cache'))
            .toList();

    String bootstrap(String caches) =>
        '''
Future<void> _evictExpiredCaches() async {
  final List<ExpiringCache> caches = [$caches];
  for (final cache in caches) {
    await cache.evictExpired();
  }
}
''';

    test('accepts a cache listed in _evictExpiredCaches', () {
      expect(
        rules({
          cachePath: cache,
          'lib/app/bootstrap.dart': bootstrap(
            'getIt<CharacterHiveDataSource>()',
          ),
        }),
        isEmpty,
      );
    });

    test('rejects a cache missing from the list, at its class line', () {
      final violations = checkFiles({
        cachePath: '// A cache.\n$cache',
        'lib/data/news/data_source/news_hive_data_source.dart':
            'class NewsHiveDataSource implements ExpiringCache {}\n',
        'lib/app/bootstrap.dart': bootstrap('getIt<CharacterHiveDataSource>()'),
      }).where((v) => v.rule.contains('is a cache'));

      expect(violations.map((v) => (v.path, v.line)), [
        ('lib/data/news/data_source/news_hive_data_source.dart', 1),
      ]);
      expect(
        violations.single.rule,
        startsWith(
          'NewsHiveDataSource is a cache: add getIt<NewsHiveDataSource>() '
          'to the list in _evictExpiredCaches',
        ),
      );
    });

    test('finds a cache declared with a class modifier', () {
      expect(
        rules({
          'lib/data/news/data_source/news_hive_data_source.dart':
              'final class NewsHiveDataSource implements ExpiringCache {}\n',
          'lib/app/bootstrap.dart': bootstrap(''),
        }),
        [startsWith('NewsHiveDataSource is a cache')],
      );
    });

    test('rejects a cache when bootstrap.dart is missing', () {
      expect(rules({cachePath: cache}), [
        startsWith('CharacterHiveDataSource is a cache'),
      ]);
    });

    test('does not count a getIt call outside the list', () {
      expect(
        rules({
          cachePath: cache,
          'lib/app/bootstrap.dart':
              'final source = getIt<CharacterHiveDataSource>();\n${bootstrap('')}',
        }),
        hasLength(1),
      );
    });

    test('ignores user data and other implements clauses', () {
      expect(
        rules({
          'lib/data/favorite/data_source/favorite_hive_data_source.dart':
              '/// User data, never an `ExpiringCache`.\n'
              'class FavoriteHiveDataSource {}\n',
          'lib/data/auth/data_source/auth_firebase_data_source.dart':
              'class AuthFirebaseDataSource implements TokenProvider {}\n',
          'lib/app/bootstrap.dart': bootstrap(''),
        }),
        isEmpty,
      );
    });
  });

  group('repository impl packages', () {
    const impl = 'lib/data/character/character_repository_impl.dart';
    const dataSource =
        'lib/data/character/data_source/character_hive_data_source.dart';

    test('a repository may import the listed packages', () {
      for (final uri in [
        'package:injectable/injectable.dart',
        'package:talker/talker.dart',
        'package:stream_transform/stream_transform.dart',
        'package:meta/meta.dart',
        'package:collection/collection.dart',
        'dart:async',
      ]) {
        expectAllowed(impl, uri);
      }
    });

    test('a repository must not import SDKs, clients or storage', () {
      for (final uri in [
        'package:firebase_auth/firebase_auth.dart',
        'package:dio/dio.dart',
        'package:hive_ce/hive.dart',
      ]) {
        expect(
          checkImport(impl, uri),
          startsWith('a repository must not import $uri'),
        );
      }
    });

    test('a data source may import them', () {
      expectAllowed(dataSource, 'package:hive_ce/hive.dart');
      expectAllowed(dataSource, 'package:dio/dio.dart');
      expectAllowed(dataSource, 'package:firebase_auth/firebase_auth.dart');
    });
  });

  group('data layout', () {
    test('rejects a file directly in lib/data', () {
      expect(checkLocation('lib/data/a.dart'), isNotNull);
    });

    test('accepts each valid kind of file', () {
      expectLocationAccepted([
        'lib/data/character/character_repository_impl.dart',
        'lib/data/character/data_source/character_api_data_source.dart',
        'lib/data/character/data_source/character_hive_data_source.dart',
        'lib/data/character/data_source/character_prefs_data_source.dart',
        'lib/data/character/data_source/character_fcm_data_source.dart',
        'lib/data/character/data_source/character_notif_data_source.dart',
        'lib/data/character/data_source/character_firebase_data_source.dart',
        'lib/data/character/data_source/character_api_exception.dart',
        'lib/data/character/data_source/character_hive_module.dart',
        'lib/data/character/model/character_dto.dart',
        'lib/data/character/mapper/character_mapper.dart',
        'lib/data/_shared/data_source/network/dio_factory.dart',
        'lib/data/_shared/base/data_source/expiring_cache.dart',
        'lib/data/_shared/data_source/hive/hive_init.dart',
        'lib/data/_shared/service/analytics/firebase_analytics_service.dart',
      ]);
    });

    test('generated files follow the name of their source', () {
      expectLocationAccepted([
        'lib/data/character/model/character_dto.g.dart',
        'lib/data/character/model/character_dto.freezed.dart',
        'lib/data/character/data_source/character_api_data_source.g.dart',
        'lib/data/character/data_source/character_hive_module.config.dart',
      ]);
      expectLocationRejected(['lib/data/character/model/character.g.dart']);
    });

    test('rejects another file in the root of an area', () {
      expectLocationRejected([
        'lib/data/character/helper.dart',
        'lib/data/character/character_dto.dart',
        'lib/data/character/other_repository_impl.dart',
      ]);
    });

    test('rejects an unknown or nested folder', () {
      expectLocationRejected([
        'lib/data/character/repository/character_repository_impl.dart',
        'lib/data/character/service/a.dart',
        'lib/data/character/model/sub/character_dto.dart',
        'lib/data/character/data_source/sub/character_api_data_source.dart',
      ]);
    });

    test('rejects an unknown data source type or another area', () {
      expectLocationRejected([
        'lib/data/character/data_source/character_sql_data_source.dart',
        'lib/data/character/data_source/character_api.dart',
        'lib/data/character/data_source/character_local_data_source.dart',
        'lib/data/character/data_source/auth_api_data_source.dart',
        'lib/data/character/data_source/auth_firebase_module.dart',
        'lib/data/character/data_source/character_module.dart',
        'lib/data/character/data_source/character_sql_module.dart',
      ]);
    });

    test('rejects a non-dto in model and a non-mapper in mapper', () {
      expectLocationRejected([
        'lib/data/character/model/character.dart',
        'lib/data/character/model/character_mapper.dart',
        'lib/data/character/mapper/character_dto.dart',
        'lib/data/character/mapper/character.dart',
      ]);
    });

    test('rejects files directly in data/_shared and unknown folders', () {
      expectLocationRejected([
        'lib/data/_shared/a.dart',
        'lib/data/_shared/other/a.dart',
      ]);
    });

    test('rejects the old data/_shared folders storage and network', () {
      expectLocationRejected([
        'lib/data/_shared/storage/expiring_cache.dart',
        'lib/data/_shared/storage/hive/hive_init.dart',
        'lib/data/_shared/network/dio_factory.dart',
      ]);
    });

    test('a file in data/_shared/data_source is not held to the area name', () {
      expectLocationAccepted([
        'lib/data/_shared/data_source/network/dio_factory.dart',
        'lib/data/_shared/data_source/hive/hive_module.dart',
        'lib/data/_shared/data_source/prefs/prefs_module.dart',
      ]);
    });
  });

  group('data areas', () {
    const impl = 'lib/data/character/character_repository_impl.dart';
    const contract = 'lib/domain/repository/character_repository.dart';

    test('reports an area without its repository implementation', () {
      final violations = checkFiles({
        'lib/data/character/model/character_dto.dart': '',
        contract: '',
      });

      expect(violations.map((v) => v.path), [
        'lib/data/character/model/character_dto.dart',
      ]);
      expect(
        violations.single.rule,
        startsWith(
          'data/character has no character_repository_impl.dart in its root',
        ),
      );
    });

    test('reports an implementation without its contract', () {
      final violations = checkFiles({impl: ''});

      expect(violations.map((v) => v.path), [impl]);
      expect(
        violations.single.rule,
        startsWith(
          'data/character has no contract domain/repository/'
          'character_repository.dart',
        ),
      );
    });

    test('accepts a complete area, and areas of several kinds', () {
      expect(
        checkFiles({
          impl:
              'class CharacterRepositoryImpl implements CharacterRepository {}',
          contract: 'abstract interface class CharacterRepository {}',
          'lib/data/character/model/character_dto.dart':
              'class CharacterDto {}',
          'lib/data/_shared/data_source/network/dio_factory.dart': '',
        }),
        isEmpty,
      );
    });
  });

  group('singular names', () {
    const contract = 'lib/domain/repository/character_repository.dart';

    List<String> rules(Map<String, String> files) => [
      for (final violation in checkFiles(files))
        if (violation.rule.contains('Singular names')) violation.path,
    ];

    test('reports a plural area name on its contract', () {
      expect(rules({'lib/domain/repository/characters_repository.dart': ''}), [
        'lib/domain/repository/characters_repository.dart',
      ]);
    });

    test('accepts settings as a plural area by convention', () {
      expect(
        rules({
          'lib/domain/repository/settings_repository.dart': '',
          'lib/presentation/settings/page/settings_page.dart': '',
        }),
        isEmpty,
      );
    });

    test('reports folders and files that start with the plural of an area', () {
      expect(
        rules({
          contract: '',
          'lib/app/di/characters_module.dart': '',
          'lib/presentation/characters_list/page/character_list_page.dart': '',
          'lib/app/characters/character_wiring.dart': '',
        }),
        unorderedEquals([
          'lib/app/di/characters_module.dart',
          'lib/presentation/characters_list/page/character_list_page.dart',
          'lib/app/characters/character_wiring.dart',
          // The folder `characters` is also a plural folder name.
          'lib/app/characters',
        ]),
      );
    });

    test('reports the plural of a multi-word area', () {
      expect(
        rules({
          'lib/domain/repository/user_profile_repository.dart': '',
          'lib/presentation/user_profiles/page/a_page.dart': '',
          'lib/app/di/user_profiles_module.dart': '',
          'lib/app/di/user_profile_module.dart': '',
        }),
        unorderedEquals([
          'lib/presentation/user_profiles/page/a_page.dart',
          'lib/app/di/user_profiles_module.dart',
          // The folder `user_profiles` is also a plural folder name.
          'lib/presentation/user_profiles',
        ]),
      );
    });

    test('accepts singular names and a plural that names a collection', () {
      expect(
        rules({
          contract: '',
          'lib/app/di/character_module.dart': '',
          'lib/presentation/character_list/page/character_list_page.dart': '',
          'lib/domain/use_case/character/get_characters_page_use_case.dart': '',
          'lib/domain/entity/user_characters.dart': '',
          'lib/presentation/character_detail/page/character_detail_page.dart':
              '',
        }),
        isEmpty,
      );
    });
  });

  group('plural folder names', () {
    List<String> folders(Iterable<String> paths) => [
      for (final violation in checkFolderNames(paths)) violation.path,
    ];

    test('rejects a folder under lib/ that ends in "s"', () {
      expect(folders(['lib/domain/usecases/character/a.dart']), [
        'lib/domain/usecases',
      ]);
    });

    test('rejects a folder under test/ that ends in "s"', () {
      expect(folders(['test/helpers/a.dart']), ['test/helpers']);
    });

    test('reports every plural folder of a path, once per folder', () {
      expect(
        folders([
          'lib/data/character/models/a.dart',
          'lib/data/character/models/b.dart',
          'lib/data/character/mappers/c.dart',
        ]),
        ['lib/data/character/mappers', 'lib/data/character/models'],
      );
    });

    test('accepts every name on the list', () {
      expect(
        folders([
          'lib/data/settings/a.dart',
          'lib/shared/utils/a.dart',
          'lib/data/_shared/data_source/prefs/a.dart',
          'lib/domain/_shared/service/analytics/a.dart',
          'test/data/settings/a.dart',
        ]),
        isEmpty,
      );
    });

    test('accepts singular folder names', () {
      expect(
        folders([
          'lib/domain/use_case/character/a.dart',
          'lib/presentation/_shared/component/favorite_toggle/a.dart',
          'test/helper/a.dart',
        ]),
        isEmpty,
      );
    });

    test('does not check the file name', () {
      expect(
        folders(['lib/app/router/routes.dart', 'test/mocks.dart']),
        isEmpty,
      );
    });

    test('rejects a name that only looks like one on the list', () {
      expect(folders(['lib/data/setting/status/a.dart']), [
        'lib/data/setting/status',
      ]);
      expect(folders(['lib/data/my_settings/a.dart']), [
        'lib/data/my_settings',
      ]);
    });

    test('checkFiles reports a plural folder in lib/', () {
      expect(
        checkFiles({'lib/domain/entities/a.dart': ''}).map((v) => v.rule),
        contains(startsWith('entities is plural')),
      );
    });
  });

  group('route paths', () {
    const routes = 'lib/app/router/routes.dart';

    List<String> rules(String content) => [
      for (final violation in checkFiles({routes: content}))
        if (violation.rule.startsWith('route path segment')) violation.rule,
    ];

    String routesWith(String route) =>
        '''
abstract final class _ScreenNames {
  static const signIn = 'sign_in';
  static const characterList = 'character_list';
  static const characterDetail = 'character_detail';
}

$route
''';

    test('accepts a path segment that is its screen name in kebab-case', () {
      expect(
        rules(
          routesWith(
            "@TypedGoRoute<SignInRoute>(path: '/sign-in', name: _ScreenNames.signIn)\n"
            "TypedGoRoute<CharacterListRoute>(\n  path: '/character-list',\n"
            '  name: _ScreenNames.characterList,\n)',
          ),
        ),
        isEmpty,
      );
    });

    test('reports a path segment that differs from its screen name', () {
      final violations = rules(
        routesWith(
          "TypedGoRoute<CharacterListRoute>(\n  path: '/characters',\n"
          '  name: _ScreenNames.characterList,\n)',
        ),
      );

      expect(violations, hasLength(1));
      expect(violations.single, contains('character-list'));
    });

    test('reports a one-line route and a nested segment', () {
      final violations = rules(
        routesWith(
          "@TypedGoRoute<SignInRoute>(path: '/login', name: _ScreenNames.signIn)\n"
          "TypedGoRoute<CharacterListRoute>(path: 'characters', name: _ScreenNames.characterList)",
        ),
      );

      expect(violations, hasLength(2));
      expect(violations[0], contains('sign-in'));
      expect(violations[1], contains('character-list'));
    });

    test('reports a route tree it cannot read', () {
      expect(
        checkFiles({
          routes: routesWith(
            "TypedGoRoute<CharacterListRoute>(name: _ScreenNames.characterList, path: '/x')",
          ),
        }).map((v) => v.rule),
        contains(startsWith('no route reads as')),
      );
    });

    test('skips parameter-only paths', () {
      expect(
        rules(
          routesWith(
            "TypedGoRoute<CharacterDetailRoute>(path: ':id', name: _ScreenNames.characterDetail)",
          ),
        ),
        isEmpty,
      );
    });
  });

  group('package ownership', () {
    const dataPath =
        'lib/data/character/data_source/character_api_data_source.dart';
    const presentationPath = 'lib/presentation/character_list/a.dart';
    const characterArea = {
      'lib/data/character/character_repository_impl.dart': '',
      'lib/domain/repository/character_repository.dart': '',
    };

    test('presentation must not import known data packages', () {
      for (final uri in [
        'package:dio/dio.dart',
        'package:hive_ce/hive.dart',
        'package:shared_preferences/shared_preferences.dart',
        'package:firebase_auth/firebase_auth.dart',
        'package:firebase_anything/a.dart',
      ]) {
        expectForbidden(presentationPath, uri);
      }
    });

    test('data must not import known presentation packages', () {
      expect(
        checkImport(dataPath, 'package:flutter_bloc/flutter_bloc.dart'),
        startsWith(
          'data must not import package:flutter_bloc/flutter_bloc.dart: '
          'flutter_bloc belongs to presentation',
        ),
      );
    });

    test('each layer may import its own and new packages', () {
      expectAllowed(dataPath, 'package:firebase_auth/firebase_auth.dart');
      expectAllowed(presentationPath, 'package:flutter_bloc/flutter_bloc.dart');
      expectAllowed(presentationPath, 'package:shimmer/shimmer.dart');
      expectAllowed(dataPath, 'package:supabase/supabase.dart');
    });

    test('a package imported by both layers is reported in both', () {
      final violations = checkFiles({
        ...characterArea,
        dataPath:
            "import 'package:meta/meta.dart';\n"
            "import 'package:supabase/supabase.dart';\n",
        presentationPath: "import 'package:supabase/supabase.dart';\n",
      });

      expect(violations.map((v) => '${v.path}:${v.line}'), [
        '$dataPath:2',
        '$presentationPath:1',
      ]);
      expect(
        violations.first.rule,
        startsWith(
          'package:supabase is imported by both data and presentation. '
          'Keep it in one layer, or add it to _sharedPackages',
        ),
      );
    });

    test('shared packages may be imported by both layers', () {
      final violations = checkFiles({
        ...characterArea,
        dataPath:
            "import 'package:freezed_annotation/a.dart';\n"
            "import 'package:injectable/injectable.dart';\n",
        presentationPath:
            "import 'package:freezed_annotation/a.dart';\n"
            "import 'package:injectable/injectable.dart';\n",
      });

      expect(violations, isEmpty);
    });

    test('imports outside data and presentation do not count', () {
      final violations = checkFiles({
        ...characterArea,
        'lib/app/app.dart': "import 'package:supabase/supabase.dart';\n",
        'lib/shared/a.dart': "import 'package:talker/talker.dart';\n",
        dataPath: "import 'package:talker/talker.dart';\n",
        presentationPath: "import 'package:supabase/supabase.dart';\n",
      });

      expect(violations, isEmpty);
    });
  });

  group('l10n', () {
    const path = 'lib/l10n/gen/app_localizations.dart';

    test('may import itself, Flutter and intl', () {
      expectAllowed(path, '$_own/l10n/gen/app_localizations_en.dart');
      expectAllowed(path, 'package:flutter/widgets.dart');
      expectAllowed(path, 'package:flutter_localizations/a.dart');
      expectAllowed(path, 'package:intl/intl.dart');
      expectAllowed(path, 'dart:async');
    });

    test('must not import anything else', () {
      for (final module in [
        'shared',
        'domain',
        'data',
        'presentation',
        'app',
      ]) {
        expectForbidden(path, '$_own/$module/a/b.dart');
      }
      expectForbidden(path, 'package:dio/dio.dart');
    });
  });

  group('relative imports', () {
    test('are checked like package imports', () {
      expectAllowed('lib/data/character/a.dart', 'model/b.dart');
      expectForbidden(
        'lib/data/character/a.dart',
        '../../presentation/a/b.dart',
      );
      expectForbidden('lib/data/character/a.dart', '../auth/b.dart');
    });

    test('must not leave lib', () {
      expectForbidden('lib/data/character/a.dart', '../../../tool/a.dart');
    });
  });

  group('location', () {
    test('accepts main.dart and known modules', () {
      expectLocationAccepted([
        'lib/main.dart',
        'lib/app/app.dart',
        'lib/shared/logging/a.dart',
        'lib/domain/entity/character.dart',
        'lib/data/character/character_repository_impl.dart',
        'lib/presentation/character_list/a.dart',
        'lib/l10n/gen/a.dart',
      ]);
    });

    test('rejects "shared" as an area or feature name', () {
      for (final layer in ['domain', 'data', 'presentation']) {
        expect(checkLocation('lib/$layer/shared/a.dart'), isNotNull);
      }
    });

    test('rejects use_case folders in presentation', () {
      expectLocationRejected([
        'lib/presentation/character_list/use_case/a.dart',
        'lib/presentation/_shared/use_case/a.dart',
      ]);
    });

    test('accepts the use_case folder in domain', () {
      expect(checkLocation('lib/domain/use_case/character/a.dart'), isNull);
    });

    test('accepts files with a layer suffix in their layer', () {
      expectLocationAccepted([
        'lib/data/character/model/character_dto.dart',
        'lib/data/character/character_repository_impl.dart',
        'lib/domain/use_case/character/get_characters_page_use_case.dart',
        'lib/presentation/character_list/bloc/character_list_bloc.dart',
        'lib/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_bloc.dart',
        'lib/data/character/model/character_dto.g.dart',
      ]);
    });

    test('rejects files with a layer suffix outside their layer', () {
      expect(
        checkLocation('lib/presentation/character_list/character_dto.dart'),
        '*_dto.dart files live in data',
      );
      expect(
        checkLocation('lib/domain/repository/a_repository_impl.dart'),
        '*_repository_impl.dart files live in data',
      );
      expect(
        checkLocation('lib/app/router/a_bloc.dart'),
        '*_bloc.dart files live in presentation',
      );
      for (final path in [
        'lib/domain/entity/a_use_case.dart',
        'lib/data/character/a_use_case.dart',
      ]) {
        expect(
          checkLocation(path),
          '*_use_case.dart files live in domain/use_case',
          reason: path,
        );
      }
    });

    test('rejects unknown top-level modules, including _shared', () {
      expect(checkLocation('lib/_shared/a.dart'), isNotNull);
      expect(checkLocation('lib/utils/a.dart'), isNotNull);
      expect(checkLocation('lib/helpers.dart'), isNotNull);
    });
  });

  group('checkFile', () {
    test('reports the line of a wrong import and export', () {
      final violations = checkFile('lib/domain/entity/a.dart', '''
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

export 'package:flutter_starter/data/character/b.dart';
''');

      expect(violations.map((v) => v.line), [2, 4]);
    });

    test('reports the service locator outside app', () {
      final violations = checkFile('lib/presentation/character_list/a.dart', '''
final bloc = getIt<CharacterListBloc>();
// getIt in a comment is fine
final helper = GetItHelper(container);
''');

      expect(violations.map((v) => v.line), [1, 3]);
      expect(
        violations.first.rule,
        'getIt is used only in app/; receive dependencies through the '
        'constructor',
      );
    });

    test('does not mistake similar names for the service locator', () {
      final violations = checkFile(
        'lib/domain/use_case/character/get_characters_page_use_case.dart',
        'class GetCharactersPageUseCase implements UseCase<Character, ()> {}\n'
            'final getCharacters = 1;\n',
      );

      expect(violations, isEmpty);
    });

    test('allows the service locator in app and main.dart', () {
      for (final path in ['lib/app/bootstrap.dart', 'lib/main.dart']) {
        expect(
          checkFile(path, 'final a = getIt<A>();\n'),
          isEmpty,
          reason: path,
        );
      }
    });

    test('ignores commented-out imports', () {
      final violations = checkFile(
        'lib/domain/entity/a.dart',
        "// import 'package:flutter/material.dart';\n",
      );

      expect(violations, isEmpty);
    });
  });

  group('types', () {
    const path = 'lib/domain/entity/character.dart';
    const failurePath = 'lib/domain/_shared/wrapper/result/failure.dart';

    test('a file with the one type named after it passes', () {
      expect(checkFile(path, 'class Character {}\n'), isEmpty);
      expect(
        checkFile(path, 'abstract interface class Character {}\n'),
        isEmpty,
      );
    });

    test('a file with only functions passes', () {
      expect(
        checkFile('lib/shared/utils/helpers.dart', 'int add(int a) => a;\n'),
        isEmpty,
      );
    });

    test('a file with only extensions passes', () {
      expect(
        checkFile(
          'lib/shared/utils/string_extensions.dart',
          'extension StringX on String {}\n',
        ),
        isEmpty,
      );
    });

    test('rejects a second unrelated public class', () {
      final violations = checkFile(
        path,
        'class Character {}\nclass Other {}\n',
      );

      expect(violations.map((v) => v.line), [2]);
      expect(
        violations.single.rule,
        startsWith('Other is a second public type in a file of Character'),
      );
    });

    test('allows enums next to the main type', () {
      expect(
        checkFile(path, 'class Character {}\nenum CharacterKind { a }\n'),
        isEmpty,
      );
    });

    test('allows sealed variants, directly and through another variant', () {
      expect(
        checkFile(failurePath, '''
sealed class Failure {}
final class NetworkFailure extends Failure {}
final class Closed implements Failure {}
'''),
        isEmpty,
      );
      expect(
        checkFile(failurePath, '''
final class BadCredentials extends AuthFailure {}
sealed class AuthFailure extends Failure {}
sealed class Failure {}
'''),
        isEmpty,
      );
    });

    test('ignores private classes', () {
      expect(
        checkFile(path, 'class Character {}\nclass _Helper {}\n'),
        isEmpty,
      );
    });

    test('exempts routes.dart', () {
      expect(
        checkFile('lib/app/router/routes.dart', 'class A {}\nclass B {}\n'),
        isEmpty,
      );
    });

    test('ignores generated files', () {
      for (final generated in [
        'lib/data/character/model/character_dto.g.dart',
        'lib/data/character/model/character_dto.freezed.dart',
        'lib/l10n/gen/app_localizations.dart',
      ]) {
        expect(
          checkFile(generated, 'class A {}\nclass B {}\n'),
          isEmpty,
          reason: generated,
        );
      }
    });

    test('rejects a file whose types do not include its own name', () {
      final violations = checkFile(path, 'class Other {}\n');

      expect(violations.map((v) => v.line), [1]);
      expect(
        violations.single.rule,
        startsWith('a file with public types declares the one named after it'),
      );
    });
  });

  group('unique types', () {
    test('reports the same class name in two files, in both', () {
      final violations = checkFiles({
        'lib/domain/entity/character.dart': 'class Character {}\n',
        'lib/presentation/character_list/widget/character.dart':
            'class Character {}\n',
      });

      expect(violations.map((v) => v.path), [
        'lib/domain/entity/character.dart',
        'lib/presentation/character_list/widget/character.dart',
      ]);
      expect(
        violations.first.rule,
        startsWith('Character is declared in 2 files'),
      );
    });

    test('reports the same extension name in two files', () {
      final violations = checkFiles({
        'lib/shared/utils/a.dart': 'extension StringX on String {}\n',
        'lib/shared/utils/b.dart': 'extension StringX on int {}\n',
      });

      expect(violations.map((v) => v.path), [
        'lib/shared/utils/a.dart',
        'lib/shared/utils/b.dart',
      ]);
    });

    test('accepts distinct names', () {
      expect(
        checkFiles({
          'lib/domain/entity/character.dart': 'class Character {}\n',
          'lib/domain/entity/other.dart': 'class Other {}\n',
        }),
        isEmpty,
      );
    });

    test('ignores generated files and routes.dart', () {
      expect(
        checkFiles({
          'lib/domain/entity/character.dart': 'class Character {}\n',
          'lib/l10n/gen/a.dart': 'class Character {}\n',
          'lib/app/router/routes.dart': 'class Character {}\n',
        }),
        isEmpty,
      );
    });
  });

  group('use case base', () {
    const path = 'lib/domain/use_case/character/get_character_use_case.dart';

    void expectRejected(String path, String content) {
      final violations = checkFile(path, content);
      expect(violations, hasLength(1), reason: content);
      expect(
        violations.single.rule,
        startsWith('a use case implements UseCase or StreamUseCase'),
      );
    }

    test('a base class named only in a comment does not count', () {
      expectRejected(path, '''
// class GetCharacterUseCase implements UseCase<Character, ({int id})> {}
class GetCharacterUseCase {}
''');
    });

    test('accepts UseCase with a record parameter', () {
      expect(
        checkFile(
          path,
          'class GetCharacterUseCase implements UseCase<Character, ({int id})> {}\n',
        ),
        isEmpty,
      );
    });

    test('accepts StreamUseCase with ()', () {
      expect(
        checkFile(
          'lib/domain/use_case/character/watch_characters_use_case.dart',
          'class WatchCharactersUseCase implements StreamUseCase<Character, ()> {}\n',
        ),
        isEmpty,
      );
    });

    test('accepts a declaration over several lines', () {
      expect(
        checkFile(path, '''
class GetCharacterUseCase
    implements
        UseCase<
          List<Character>,
          ({int id, String name})
        > {}
'''),
        isEmpty,
      );
    });

    test('rejects a parameter type that is not a record', () {
      expectRejected(
        path,
        'class GetCharacterUseCase implements UseCase<Character, int> {}\n',
      );
    });

    test('rejects a use case without a base class', () {
      expectRejected(path, 'class GetCharacterUseCase {}\n');
    });

    test('does not check the base classes', () {
      expect(
        checkFile(
          'lib/domain/_shared/base/use_case/use_case.dart',
          'abstract interface class UseCase<T, P> {}\n',
        ),
        isEmpty,
      );
    });
  });

  group('repository contract', () {
    const path = 'lib/domain/repository/character_repository.dart';

    test('accepts Future<Result<X>> and Stream<X>', () {
      expect(
        checkFile(path, '''
abstract interface class CharacterRepository {
  Future<Result<Character>> getCharacter(int id);
  Future<Result<List<Character>>> getCharacters();
  Stream<Character> watch();
}
'''),
        isEmpty,
      );
    });

    test('rejects getters and record return types', () {
      final violations = checkFile(path, '''
abstract interface class CharacterRepository {
  int get count;
  (int, int) bounds();
  Stream<Character> watch();
}
''');

      expect(violations.map((v) => v.line), [2, 3]);
    });

    test('rejects other return types', () {
      final violations = checkFile(path, '''
abstract interface class CharacterRepository {
  Future<Result<Character>> getCharacter(int id);
  Future<Character> getOther(int id);
  Future<void> clear();
}
''');

      expect(violations.map((v) => v.line), [3, 4]);
      expect(
        violations.first.rule,
        startsWith(
          'a repository contract method returns Future<Result<T>> or '
          'Stream<T>, not Future<Character>',
        ),
      );
    });

    test('ignores comment lines', () {
      expect(
        checkFile(path, '''
abstract interface class CharacterRepository {
  // Future<Character> old(int id);
  /// Future<Character> documented(int id);
  Stream<Character> watch();
}
'''),
        isEmpty,
      );
    });
  });

  group('ports', () {
    test('accept an abstract interface class in every port folder', () {
      for (final (path, name) in [
        (
          'lib/domain/repository/character_repository.dart',
          'CharacterRepository',
        ),
        (
          'lib/domain/_shared/service/analytics/analytics_service.dart',
          'AnalyticsService',
        ),
        ('lib/domain/_shared/base/use_case/use_case.dart', 'UseCase'),
      ]) {
        expect(
          checkFile(path, 'abstract interface class $name {}\n'),
          isEmpty,
          reason: path,
        );
      }
    });

    test('reject an abstract class in every port folder', () {
      for (final (path, name) in [
        (
          'lib/domain/repository/character_repository.dart',
          'CharacterRepository',
        ),
        (
          'lib/domain/_shared/service/analytics/analytics_service.dart',
          'AnalyticsService',
        ),
        ('lib/domain/_shared/base/use_case/use_case.dart', 'UseCase'),
        (
          'lib/data/_shared/base/data_source/expiring_cache.dart',
          'ExpiringCache',
        ),
      ]) {
        final violations = checkFile(path, 'abstract class $name {}\n');

        expect(violations.map((v) => v.rule), [
          '$name is a contract: declare it as an abstract interface class '
              '(doc/spec/architecture.md, Principles)',
        ], reason: path);
      }
    });

    test('ignore an abstract class outside the port folders', () {
      expect(
        checkFile(
          'lib/data/_shared/data_source/hive/hive_module.dart',
          '@module\nabstract class HiveModule {}\n',
        ),
        isEmpty,
      );
    });
  });

  group('state holders', () {
    const blocPath =
        'lib/presentation/character_list/bloc/character_list_bloc.dart';

    test('rejects *_cubit.dart files in every module', () {
      for (final path in [
        'lib/presentation/character_list/bloc/character_list_cubit.dart',
        'lib/data/character/character_list_cubit.dart',
        'lib/app/router/a_cubit.dart',
      ]) {
        expect(
          checkLocation(path),
          '*_cubit.dart files are not used: state holders are Blocs '
          '(doc/spec/architecture.md, State management)',
          reason: path,
        );
      }
    });

    test('rejects a Cubit class, also in app', () {
      for (final path in [blocPath, 'lib/app/a.dart']) {
        final violations = checkFile(path, '''
class _A extends Cubit<int> {}
class _B extends   Cubit <String> {}
// class C extends Cubit<int> {}
''');

        expect(violations.map((v) => v.line), [1, 2], reason: path);
        expect(
          violations.first.rule,
          'Cubit is not used: state holders are Blocs '
          '(doc/spec/architecture.md, State management)',
        );
      }
    });

    test('does not mistake similar names for a Cubit', () {
      final violations = checkFile(blocPath, '''
class _A extends Bloc<E, S> {}
class _B extends MyCubit<int> {}
final cubitLike = Cubit;
''');

      expect(violations, isEmpty);
    });

    test('accepts handlers with a transformer, on one or several lines', () {
      final violations = checkFile(blocPath, '''
class CharacterListBloc extends Bloc<E, S> {
  CharacterListBloc() : super(S()) {
    on<Started>((event, emit) => emit(S()), transformer: restartable());
    on<Searched>(
      _onSearched,
      transformer: (events, mapper) =>
          events.debounce(duration).switchMap(mapper),
    );
    on<Map<String, List<int>>>(_onMap, transformer: sequential());
  }
}
''');

      expect(violations, isEmpty);
    });

    test('rejects handlers without a transformer, also in app', () {
      for (final path in [blocPath, 'lib/app/a.dart']) {
        final violations = checkFile(path, '''
on<Started>((event, emit) => emit(S()));
on<Loaded>(
  (event, emit) async => emit(await load(transformer: 1)),
);
on<Other>(_onOther);
// on<Commented>(_onCommented);
''');

        expect(violations.map((v) => v.line), [1, 2, 5], reason: path);
        expect(
          violations.first.rule,
          'every on<E> handler passes a transformer: '
          '(doc/spec/architecture.md, State management)',
        );
      }
    });

    test('counts a transformer only as an argument of on<E>', () {
      final violations = checkFile(blocPath, '''
on<A>(_onA);
final transformer = sequential();
on<B>(_onB, mytransformer: sequential());
''');

      expect(violations.map((v) => v.line), [1, 3]);
    });

    test('rejects manual subscriptions in Bloc files only', () {
      final violations = checkFile(blocPath, '''
late final StreamSubscription<int> _subscription;
void start() => stream.listen((value) {});
// stream.listen(print);
''');

      expect(violations.map((v) => v.line), [1, 2]);
      expect(
        violations.first.rule,
        'Blocs follow streams with emit.forEach or emit.onEach, not '
        'StreamSubscription (doc/spec/architecture.md, State management)',
      );
      expect(
        checkFile(
          'lib/app/observability/a.dart',
          'final s = bloc.stream.listen(print);\n',
        ),
        isEmpty,
      );
      expect(
        checkFile(
          'lib/presentation/character_list/bloc/character_list_state.dart',
          'final StreamSubscription<int>? subscription = null;\n',
        ),
        isEmpty,
      );
    });

    test('the design packages belong to presentation', () {
      for (final uri in [
        'package:material_ui/material_ui.dart',
        'package:cupertino_ui/cupertino_ui.dart',
      ]) {
        expect(checkImport('lib/data/character/a.dart', uri), isNotNull);
        expect(checkImport('lib/domain/character/a.dart', uri), isNotNull);
      }
    });

    test('bloc_concurrency belongs to presentation', () {
      expect(
        checkImport(
          'lib/data/character/a.dart',
          'package:bloc_concurrency/bloc_concurrency.dart',
        ),
        isNotNull,
      );
      expect(
        checkImport(blocPath, 'package:bloc_concurrency/bloc_concurrency.dart'),
        isNull,
      );
    });
  });

  group('page tests', () {
    const page = 'lib/presentation/a/page/a_page.dart';
    const pageTest = 'test/presentation/a/page/a_page_test.dart';
    const calling =
        'void main() {\n  testAccessibility((tester, theme) {});\n}\n';

    List<String> rules(List<String> libPaths, Map<String, String> pageTests) =>
        [
          for (final violation in checkPageTests(libPaths, pageTests))
            '${violation.path}:${violation.line}: ${violation.rule}',
        ];

    test('reports a page without a page test', () {
      expect(rules([page], {}), [
        '$page:1: $pageTest is missing: every page test calls '
            'testAccessibility (doc/spec/architecture.md, Testing)',
      ]);
    });

    test('reports a page test that does not call testAccessibility', () {
      expect(rules([page], {pageTest: 'void main() {}\n'}), [
        '$page:1: $pageTest does not call testAccessibility '
            '(doc/spec/architecture.md, Testing)',
      ]);
    });

    test('does not count a commented call', () {
      expect(
        rules(
          [page],
          {pageTest: '// testAccessibility((tester, theme) {});\n'},
        ),
        hasLength(1),
      );
    });

    test('accepts a page test that calls testAccessibility', () {
      expect(rules([page], {pageTest: calling}), isEmpty);
    });

    test('checks the page of a shared component too', () {
      expect(
        rules(['lib/presentation/_shared/component/b/page/b_page.dart'], {}),
        hasLength(1),
      );
    });

    test('checks a page outside a page folder too', () {
      expect(rules(['lib/presentation/a/widget/a_page.dart'], {}), [
        'lib/presentation/a/widget/a_page.dart:1: '
            'test/presentation/a/widget/a_page_test.dart is missing: every '
            'page test calls testAccessibility (doc/spec/architecture.md, '
            'Testing)',
      ]);
    });

    test('ignores files that are not pages', () {
      expect(
        rules([
          'lib/presentation/a/widget/a_tile.dart',
          'lib/presentation/a/bloc/a_bloc.dart',
          'lib/app/router/a_page.dart',
        ], {}),
        isEmpty,
      );
    });
  });

  group('run', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('check_imports'));
    tearDown(() => root.deleteSync(recursive: true));

    void writeFile(String path, String content) {
      File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('returns 0 for a project without violations', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      writeFile('lib/app/app.dart', "import '$_own/data/character/a.dart';\n");
      writeFile(
        'lib/data/character/character_repository_impl.dart',
        "import '$_own/domain/repository/character_repository.dart';\n"
            'class CharacterRepositoryImpl implements CharacterRepository {}\n',
      );
      writeFile(
        'lib/domain/repository/character_repository.dart',
        'abstract interface class CharacterRepository {}\n',
      );
      final out = StringBuffer();

      expect(run(root, out), 0);
      expect(out.toString(), contains('No import violations.'));
    });

    test('never opens a never-read file', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      // Not valid UTF-8: reading it as a string would throw.
      File('${root.path}/lib/app/config/firebase/firebase_options_dev.dart')
        ..createSync(recursive: true)
        ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
      final out = StringBuffer();

      expect(run(root, out), 0);
      expect(out.toString(), contains('No import violations.'));
    });

    test('returns 1 and reports a deliberately wrong import', () {
      writeFile(
        'lib/presentation/character_list/page/character_list_page.dart',
        "import '$_own/data/character/b.dart';\n",
      );
      final out = StringBuffer();

      expect(run(root, out), 1);
      expect(
        out.toString(),
        contains(
          'lib/presentation/character_list/page/character_list_page.dart:1: '
          'presentation must not import data',
        ),
      );
    });

    test('reports a data area without its repository', () {
      writeFile(
        'lib/data/character/model/character_dto.dart',
        'class CharacterDto {}\n',
      );
      final out = StringBuffer();

      expect(run(root, out), 1);
      expect(
        out.toString(),
        contains('data/character has no character_repository'),
      );
    });

    test('reports a plural folder under test/', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      writeFile('test/helpers/a_test.dart', '');
      final out = StringBuffer();

      expect(run(root, out), 1);
      expect(out.toString(), contains('test/helpers:1: helpers is plural'));
    });

    test('accepts the plural folders on the list under test/', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      writeFile('test/data/settings/a_test.dart', '');
      final out = StringBuffer();

      expect(run(root, out), 0);
    });

    test('reads the page tests under test/', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      writeFile('lib/presentation/a/page/a_page.dart', 'class APage {}\n');
      writeFile(
        'test/presentation/a/page/a_page_test.dart',
        'void main() {\n  testAccessibility((tester, theme) {});\n}\n',
      );
      final out = StringBuffer();

      expect(run(root, out), 0);
    });

    test('reports a page whose test is missing', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      writeFile('lib/presentation/a/page/a_page.dart', 'class APage {}\n');
      final out = StringBuffer();

      expect(run(root, out), 1);
      expect(
        out.toString(),
        contains('test/presentation/a/page/a_page_test.dart is missing'),
      );
    });

    test('fails when lib does not exist', () {
      expect(
        () => run(root, StringBuffer()),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
