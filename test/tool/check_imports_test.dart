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

  group('app', () {
    test('may import everything', () {
      for (final target in [
        'data/items/a.dart',
        'domain/items/a.dart',
        'presentation/items_list/a.dart',
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
    const path = 'lib/domain/items/entities/item.dart';

    test('may import shared, domain/_shared and its own area', () {
      expectAllowed(path, '$_own/shared/utils/a.dart');
      expectAllowed(path, '$_own/domain/_shared/result.dart');
      expectAllowed(path, '$_own/domain/items/repositories/a.dart');
    });

    test('may import pure Dart packages from the allowed list', () {
      expectAllowed(path, 'package:freezed_annotation/freezed_annotation.dart');
      expectAllowed(path, 'package:meta/meta.dart');
      expectAllowed(path, 'package:collection/collection.dart');
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

    test('may import entities of another area', () {
      expectAllowed(path, '$_own/domain/auth/entities/app_user.dart');
    });

    test('must not import non-entities of another area', () {
      expectForbidden(path, '$_own/domain/auth/repositories/a.dart');
      expectForbidden(path, '$_own/domain/auth/usecases/a.dart');
    });

    test('use cases may import repositories of another area', () {
      expectAllowed(
        'lib/domain/auth/usecases/a.dart',
        '$_own/domain/items/repositories/b.dart',
      );
    });

    test('use cases must not import use cases of another area', () {
      expectForbidden(
        'lib/domain/auth/usecases/a.dart',
        '$_own/domain/items/usecases/b.dart',
      );
    });

    test('repositories must not import repositories of another area', () {
      expectForbidden(
        'lib/domain/auth/repositories/a.dart',
        '$_own/domain/items/repositories/b.dart',
      );
    });

    test('_shared must not import any area, including entities', () {
      expectForbidden(
        'lib/domain/_shared/result.dart',
        '$_own/domain/items/entities/item.dart',
      );
    });
  });

  group('data', () {
    const path = 'lib/data/items/repositories/a.dart';

    test('may import shared, domain, data/_shared and its own area', () {
      expectAllowed(path, '$_own/shared/utils/a.dart');
      expectAllowed(path, '$_own/domain/items/repositories/a.dart');
      expectAllowed(path, '$_own/domain/auth/entities/a.dart');
      expectAllowed(path, '$_own/data/_shared/network/a.dart');
      expectAllowed(path, '$_own/data/items/models/a.dart');
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
      expectForbidden(path, '$_own/data/auth/models/a.dart');
      expectForbidden(path, '$_own/data/auth/entities/a.dart');
    });

    test('_shared must not import any area', () {
      expectForbidden(
        'lib/data/_shared/network/a.dart',
        '$_own/data/items/models/a.dart',
      );
    });
  });

  group('presentation', () {
    const path = 'lib/presentation/items_list/bloc/a.dart';

    test(
      'may import shared, domain, presentation/_shared, l10n and itself',
      () {
        expectAllowed(path, '$_own/shared/utils/a.dart');
        expectAllowed(path, '$_own/domain/items/repositories/a.dart');
        expectAllowed(path, '$_own/domain/auth/repositories/a.dart');
        expectAllowed(path, '$_own/presentation/_shared/theme/a.dart');
        expectAllowed(path, '$_own/presentation/items_list/pages/a.dart');
        expectAllowed(path, '$_own/l10n/gen/app_localizations.dart');
      },
    );

    test('pages and widgets may import Flutter', () {
      expectAllowed(
        'lib/presentation/items_list/pages/items_list_page.dart',
        'package:flutter/material.dart',
      );
    });

    test('BLoC files may import only flutter/foundation.dart', () {
      for (final file in [
        'bloc/items_list_bloc.dart',
        'bloc/items_list_event.dart',
        'bloc/items_list_state.dart',
        'cubit/items_list_cubit.dart',
      ]) {
        final blocPath = 'lib/presentation/items_list/$file';
        expectAllowed(blocPath, 'package:flutter/foundation.dart');
        expectAllowed(blocPath, 'package:flutter_bloc/flutter_bloc.dart');
        expectForbidden(blocPath, 'package:flutter/material.dart');
        expectForbidden(blocPath, 'package:flutter/widgets.dart');
      }
    });

    test('must not import data or app', () {
      expectForbidden(path, '$_own/data/items/models/a.dart');
      expectForbidden(path, '$_own/app/router/routes.dart');
    });

    test('features must not import each other', () {
      expectForbidden(path, '$_own/presentation/item_details/pages/a.dart');
    });

    test('_shared must not import any feature', () {
      expectForbidden(
        'lib/presentation/_shared/widgets/a.dart',
        '$_own/presentation/items_list/pages/a.dart',
      );
    });
  });

  group('package ownership', () {
    const dataPath = 'lib/data/items/a.dart';
    const presentationPath = 'lib/presentation/items_list/a.dart';

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
      expectAllowed('lib/data/items/a.dart', 'models/b.dart');
      expectForbidden('lib/data/items/a.dart', '../../presentation/a/b.dart');
      expectForbidden('lib/data/items/a.dart', '../auth/b.dart');
    });

    test('must not leave lib', () {
      expectForbidden('lib/data/items/a.dart', '../../../tool/a.dart');
    });
  });

  group('location', () {
    test('accepts main.dart and known modules', () {
      for (final path in [
        'lib/main.dart',
        'lib/app/app.dart',
        'lib/shared/logging/a.dart',
        'lib/domain/_shared/result.dart',
        'lib/data/items/a.dart',
        'lib/presentation/items_list/a.dart',
        'lib/l10n/gen/a.dart',
      ]) {
        expect(checkLocation(path), isNull, reason: path);
      }
    });

    test('rejects "shared" as an area or feature name', () {
      for (final layer in ['domain', 'data', 'presentation']) {
        expect(checkLocation('lib/$layer/shared/a.dart'), isNotNull);
      }
    });

    test('rejects usecases folders in presentation', () {
      for (final path in [
        'lib/presentation/items_list/usecases/a.dart',
        'lib/presentation/_shared/usecases/a.dart',
      ]) {
        expect(checkLocation(path), isNotNull, reason: path);
      }
    });

    test('accepts usecases folders in domain', () {
      expect(checkLocation('lib/domain/items/usecases/a.dart'), isNull);
    });

    test('accepts files with a layer suffix in their layer', () {
      for (final path in [
        'lib/data/items/models/character_dto.dart',
        'lib/data/items/repositories/items_repository_impl.dart',
        'lib/domain/items/usecases/get_items_page_use_case.dart',
        'lib/presentation/items_list/bloc/items_list_bloc.dart',
        'lib/presentation/_shared/bloc/favorite/favorite_toggle_cubit.dart',
        'lib/data/items/models/character_dto.g.dart',
      ]) {
        expect(checkLocation(path), isNull, reason: path);
      }
    });

    test('rejects files with a layer suffix outside their layer', () {
      expect(
        checkLocation('lib/presentation/items_list/item_dto.dart'),
        '*_dto.dart files live in data',
      );
      expect(
        checkLocation('lib/domain/items/repositories/a_repository_impl.dart'),
        '*_repository_impl.dart files live in data',
      );
      expect(
        checkLocation('lib/data/items/items_list_cubit.dart'),
        '*_cubit.dart files live in presentation',
      );
      expect(
        checkLocation('lib/app/router/a_bloc.dart'),
        '*_bloc.dart files live in presentation',
      );
      for (final path in [
        'lib/domain/items/a_use_case.dart',
        'lib/data/items/a_use_case.dart',
      ]) {
        expect(
          checkLocation(path),
          '*_use_case.dart files live in domain/<area>/usecases',
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
      final violations = checkFile('lib/domain/items/a.dart', '''
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

export 'package:flutter_starter/data/items/b.dart';
''');

      expect(violations.map((v) => v.line), [2, 4]);
    });

    test('reports the service locator outside app', () {
      final violations = checkFile('lib/presentation/items_list/a.dart', '''
final bloc = getIt<ItemsListBloc>();
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
        'lib/domain/items/usecases/get_items_page_use_case.dart',
        'class GetItemsPageUseCase {}\nfinal getItems = 1;\n',
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
        'lib/domain/items/a.dart',
        "// import 'package:flutter/material.dart';\n",
      );

      expect(violations, isEmpty);
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
      writeFile('lib/app/app.dart', "import '$_own/data/items/a.dart';\n");
      final out = StringBuffer();

      expect(run(root, out), 0);
      expect(out.toString(), contains('No import violations.'));
    });

    test('never opens a never-read file', () {
      writeFile('lib/main.dart', "import '$_own/app/app.dart';\n");
      // Not valid UTF-8: reading it as a string would throw.
      File('${root.path}/lib/app/firebase/firebase_options_dev.dart')
        ..createSync(recursive: true)
        ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
      final out = StringBuffer();

      expect(run(root, out), 0);
      expect(out.toString(), contains('No import violations.'));
    });

    test('returns 1 and reports a deliberately wrong import', () {
      writeFile(
        'lib/presentation/items_list/a.dart',
        "import '$_own/data/items/b.dart';\n",
      );
      final out = StringBuffer();

      expect(run(root, out), 1);
      expect(
        out.toString(),
        contains(
          'lib/presentation/items_list/a.dart:1: presentation must not import data',
        ),
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
