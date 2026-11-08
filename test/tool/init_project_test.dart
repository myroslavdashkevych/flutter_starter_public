import 'package:flutter_test/flutter_test.dart';

import '../../tool/init_project.dart';

const _ids = ProjectIds(
  name: 'My App',
  package: 'my_app',
  org: 'com.example',
  firebasePrefix: 'my-app-demo',
);

const _pubspec = '''
name: flutter_starter
description: "Flutter starter template for new mobile apps."
publish_to: "none"
dependencies:
  flutter_starter_helper: ^1.0.0
''';

const _gradle = '''
android {
    namespace = "com.yourcompany.flutterstarter"
    defaultConfig {
        applicationId = "com.yourcompany.flutterstarter"
    }
    productFlavors {
        create("dev") {
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Flutter Starter Dev"
        }
        create("prod") {
            manifestPlaceholders["appName"] = "Flutter Starter"
        }
    }
}
''';

const _pbxproj = '''
		ABC /* Debug-dev */ = {
			buildSettings = {
				APP_DISPLAY_NAME = "Flutter Starter Dev";
				PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.flutterstarter.dev;
			};
			name = "Debug-dev";
		};
		DEF /* Release-prod */ = {
			buildSettings = {
				APP_DISPLAY_NAME = "Flutter Starter";
				PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.flutterstarter;
			};
			name = "Release-prod";
		};
		GHI /* Debug-dev */ = {
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.flutterstarter.dev.RunnerTests;
			};
			name = "Debug-dev";
		};
		JKL /* Release-prod */ = {
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.flutterstarter.RunnerTests;
			};
			name = "Release-prod";
		};
''';

const _manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="\${appName}" android:name="\${applicationName}">
        <activity android:name=".MainActivity" android:exported="true"/>
    </application>
</manifest>
''';

const _mainActivityPath =
    'android/app/src/main/kotlin/com/yourcompany/flutterstarter/'
    'MainActivity.kt';

Map<String, String> _template() => {
  'pubspec.yaml': _pubspec,
  'android/app/build.gradle.kts': _gradle,
  'ios/Runner.xcodeproj/project.pbxproj': _pbxproj,
  'ios/Runner/Info.plist': '<string>flutter_starter</string>',
  'lib/l10n/arb/app_en.arb': '{"appTitle": "Flutter Starter"}',
  'lib/l10n/arb/app_uk.arb': '{"appTitle": "Flutter Starter"}',
  '.firebaserc': '"dev": "your-firebase-project-dev"',
  'config/dev.json': 'https://your-firebase-project.web.app/privacy',
  'config/prod.json': 'https://your-firebase-project.web.app/privacy',
  'docs/guides/setup.md': '`flutter_starter` `your-firebase-project`',
  _mainActivityPath: 'package com.yourcompany.flutterstarter\n',
  'lib/main.dart': "import 'package:flutter_starter/app/bootstrap.dart';\n",
  'lib/plain.dart': 'class Plain {}\n',
  'lib/app/firebase/firebase_options_dev.dart': 'never read',
  'tool/init_project.dart': "const a = 'package:flutter_starter/';\n",
  'test/tool/init_project_test.dart': "const a = 'package:flutter_starter';\n",
};

List<FileChange> _plan(Map<String, String> files) {
  final readPaths = <String>[];
  final changes = planChanges(
    ids: _ids,
    read: (path) {
      readPaths.add(path);
      return files[path];
    },
    trackedDartFiles: files.keys.where((path) => path.endsWith('.dart')),
  );
  expect(readPaths, isNot(contains(startsWith('lib/app/firebase/'))));
  return changes;
}

void main() {
  group('ProjectIds', () {
    test('derive the application ID without underscores', () {
      expect(_ids.applicationId, 'com.example.myapp');
    });

    test('derive Firebase project IDs from the prefix', () {
      expect(_ids.firebaseDev, 'my-app-demo-dev');
      expect(_ids.firebaseProd, 'my-app-demo');
    });
  });

  group('renamePubspec', () {
    test('changes only name and description', () {
      expect(renamePubspec(_pubspec, _ids), '''
name: my_app
description: "My App mobile app."
publish_to: "none"
dependencies:
  flutter_starter_helper: ^1.0.0
''');
    });
  });

  group('renameDartImports', () {
    test('changes imports and the prefix without a trailing slash', () {
      expect(
        renameDartImports("import 'package:flutter_starter/a.dart';", _ids),
        "import 'package:my_app/a.dart';",
      );
      expect(
        renameDartImports("const own = 'package:flutter_starter';", _ids),
        "const own = 'package:my_app';",
      );
    });

    test('leaves other packages alone', () {
      const source = "import 'package:flutter/material.dart';";
      expect(renameDartImports(source, _ids), source);
    });
  });

  group('renameAppIdAndName', () {
    test('updates the Gradle IDs and flavor names', () {
      final result = renameAppIdAndName(_gradle, _ids);

      expect(result, contains('namespace = "com.example.myapp"'));
      expect(result, contains('applicationId = "com.example.myapp"'));
      expect(result, contains('applicationIdSuffix = ".dev"'));
      expect(result, contains('["appName"] = "My App Dev"'));
      expect(result, contains('["appName"] = "My App"'));
      expect(result, isNot(contains('flutterstarter')));
    });

    test('updates pbxproj and keeps the flavor and test suffixes', () {
      final result = renameAppIdAndName(_pbxproj, _ids);

      expect(
        result,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp.dev;'),
      );
      expect(
        result,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp;'),
      );
      expect(
        result,
        contains(
          'PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp.dev.RunnerTests;',
        ),
      );
      expect(
        result,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp.RunnerTests;'),
      );
      expect(result, contains('APP_DISPLAY_NAME = "My App Dev";'));
      expect(result, contains('APP_DISPLAY_NAME = "My App";'));
      expect(result, isNot(contains('flutterstarter')));
      expect(result, isNot(contains('Flutter Starter')));
    });

    test('leaves AndroidManifest without identifiers unchanged', () {
      expect(renameAppIdAndName(_manifest, _ids), _manifest);
    });
  });

  group('renameFirebaseIds', () {
    test('updates dev and prod IDs in .firebaserc', () {
      const firebaserc = '''
{
  "projects": {
    "dev": "your-firebase-project-dev",
    "prod": "your-firebase-project"
  }
}
''';
      expect(renameFirebaseIds(firebaserc, _ids), '''
{
  "projects": {
    "dev": "my-app-demo-dev",
    "prod": "my-app-demo"
  }
}
''');
    });

    test('points the hosting URL at the new prod project', () {
      expect(
        renameFirebaseIds(
          '"PRIVACY_POLICY_URL": "https://your-firebase-project.web.app/privacy",',
          _ids,
        ),
        '"PRIVACY_POLICY_URL": "https://my-app-demo.web.app/privacy",',
      );
    });
  });

  group('renameSetupDoc', () {
    test('updates all identifiers', () {
      const doc =
          '`flutter_starter` `com.yourcompany.flutterstarter.dev` '
          '`Flutter Starter Dev` `your-firebase-project-dev` '
          '`com.yourcompany`';
      expect(
        renameSetupDoc(doc, _ids),
        '`my_app` `com.example.myapp.dev` `My App Dev` `my-app-demo-dev` '
        '`com.example`',
      );
    });

    test('never replaces a new value again', () {
      const ids = ProjectIds(
        name: 'My App',
        package: 'my_app',
        org: 'com.yourcompany.team',
        firebasePrefix: 'my-app-demo',
      );
      expect(
        renameSetupDoc('com.yourcompany.flutterstarter', ids),
        'com.yourcompany.team.myapp',
      );
    });
  });

  group('renameInfoPlist and renameAppTitle', () {
    test('update the bundle name', () {
      expect(
        renameInfoPlist('<string>flutter_starter</string>', _ids),
        '<string>my_app</string>',
      );
    });

    test('update the app title only', () {
      expect(
        renameAppTitle(
          '"appTitle": "Flutter Starter",\n"other": "Flutter Starter"',
          _ids,
        ),
        '"appTitle": "My App",\n"other": "Flutter Starter"',
      );
    });
  });

  group('planChanges', () {
    test('covers all expected files', () {
      final paths = _plan(_template()).map((change) => change.path);

      expect(
        paths,
        containsAll(<String>[
          'pubspec.yaml',
          'android/app/build.gradle.kts',
          'ios/Runner.xcodeproj/project.pbxproj',
          'ios/Runner/Info.plist',
          'lib/l10n/arb/app_en.arb',
          'lib/l10n/arb/app_uk.arb',
          '.firebaserc',
          'config/dev.json',
          'config/prod.json',
          'docs/guides/setup.md',
          _mainActivityPath,
          'lib/main.dart',
        ]),
      );
    });

    test('moves MainActivity to the new package path', () {
      final change = _plan(_template())
          .singleWhere((change) => change.path == _mainActivityPath);

      expect(
        change.movedTo,
        'android/app/src/main/kotlin/com/example/myapp/MainActivity.kt',
      );
      expect(change.after, 'package com.example.myapp\n');
    });

    test('skips unchanged files, this script and Firebase options', () {
      final paths = _plan(_template()).map((change) => change.path);

      expect(paths, isNot(contains('lib/plain.dart')));
      expect(paths, isNot(contains('tool/init_project.dart')));
      expect(paths, isNot(contains('test/tool/init_project_test.dart')));
      expect(
        paths,
        isNot(contains('lib/app/firebase/firebase_options_dev.dart')),
      );
    });

    test('fails when an expected file is missing', () {
      final files = _template()..remove('.firebaserc');

      expect(() => _plan(files), throwsStateError);
    });

    test('fails when an expected file has nothing to rename', () {
      final files = _template()..['ios/Runner/Info.plist'] = '<plist/>';

      expect(() => _plan(files), throwsStateError);
    });
  });

  group('describeChange', () {
    test('lists changed lines and the move', () {
      const change = FileChange(
        'a.txt',
        'same\nold',
        'same\nnew',
        movedTo: 'b.txt',
      );

      expect(
        describeChange(change),
        'a.txt -> b.txt\n  2: - old\n  2: + new\n',
      );
    });
  });

  group('flutterfireCommands', () {
    test('cover all six iOS build configurations with the new IDs', () {
      final commands = flutterfireCommands(_ids);

      expect(commands, hasLength(6));
      for (final config in ['Debug-dev', 'Profile-dev', 'Release-dev']) {
        final command = commands.singleWhere(
          (command) => command.contains('--ios-build-config=$config'),
        );
        expect(command, contains('--project=my-app-demo-dev '));
        expect(command, contains('--ios-bundle-id=com.example.myapp.dev '));
        expect(command, contains('firebase_options_dev.dart'));
      }
      for (final config in ['Debug-prod', 'Profile-prod', 'Release-prod']) {
        final command = commands.singleWhere(
          (command) => command.contains('--ios-build-config=$config'),
        );
        expect(command, contains('--project=my-app-demo '));
        expect(command, contains('--ios-bundle-id=com.example.myapp '));
        expect(command, contains('firebase_options_prod.dart'));
      }
    });
  });

  group('parseArgs', () {
    const valid = [
      '--name',
      'My App',
      '--package',
      'my_app',
      '--org',
      'com.example',
      '--firebase-prefix',
      'my-app-demo',
    ];

    test('reads separate and inline values', () {
      final options = parseArgs(valid);
      final inline = parseArgs([
        '--name=My App',
        '--package=my_app',
        '--org=com.example',
        '--firebase-prefix=my-app-demo',
      ]);

      expect(options.ids.name, 'My App');
      expect(options.dryRun, isFalse);
      expect(inline.ids.applicationId, options.ids.applicationId);
    });

    test('reads --dry-run', () {
      expect(parseArgs([...valid, '--dry-run']).dryRun, isTrue);
    });

    test('rejects unknown options, positionals and missing values', () {
      expect(
        () => parseArgs([...valid, '--unknown', 'x']),
        throwsA(isA<UsageException>()),
      );
      expect(
        () => parseArgs([...valid, 'extra']),
        throwsA(isA<UsageException>()),
      );
      expect(() => parseArgs(['--name']), throwsA(isA<UsageException>()));
    });

    test('rejects missing options', () {
      expect(
        () => parseArgs(['--name', 'My App']),
        throwsA(isA<UsageException>()),
      );
    });

    test('rejects invalid values', () {
      expect(
        () => parseArgs([
          '--name=My App',
          '--package=MyApp',
          '--org=com.example',
          '--firebase-prefix=my-app-demo',
        ]),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('validateIds', () {
    List<String> errors({
      String name = 'My App',
      String package = 'my_app',
      String org = 'com.example',
      String firebasePrefix = 'my-app-demo',
    }) => validateIds(
      ProjectIds(
        name: name,
        package: package,
        org: org,
        firebasePrefix: firebasePrefix,
      ),
    );

    test('accepts valid values', () {
      expect(errors(), isEmpty);
      expect(errors(name: 'Мій застосунок'), isEmpty);
      expect(errors(package: 'app2_go'), isEmpty);
      expect(errors(org: 'io.my1.team'), isEmpty);
    });

    test('rejects an empty name and unsafe characters', () {
      for (final name in [
        '',
        'My "App"',
        r'My\App',
        r'My$App',
        'A & B',
        'A<B',
      ]) {
        expect(errors(name: name), isNotEmpty, reason: name);
      }
    });

    test('rejects a package that is not snake_case', () {
      for (final package in [
        'MyApp',
        'my-app',
        '1app',
        '_app',
        'app_',
        'my__app',
        '',
      ]) {
        expect(errors(package: package), isNotEmpty, reason: package);
      }
    });

    test('rejects reserved words in the package and org', () {
      expect(errors(package: 'class'), isNotEmpty);
      expect(errors(org: 'com.new'), isNotEmpty);
    });

    test('rejects an org that is not a reverse domain', () {
      for (final org in [
        'example',
        'Com.Example',
        'com.',
        '.com',
        'com..example',
        'com.1example',
        'com.my-team',
        'com.my_team',
      ]) {
        expect(errors(org: org), isNotEmpty, reason: org);
      }
    });

    test('rejects a Firebase prefix outside 6-26 characters', () {
      expect(errors(firebasePrefix: 'myapp'), isNotEmpty);
      expect(errors(firebasePrefix: 'a' * 6), isEmpty);
      expect(errors(firebasePrefix: 'a' * 26), isEmpty);
      expect(errors(firebasePrefix: 'a' * 27), isNotEmpty);
    });

    test('rejects invalid Firebase prefix characters', () {
      for (final prefix in [
        'My-App-Demo',
        '1my-app',
        'my-app-',
        'my_app_demo',
      ]) {
        expect(errors(firebasePrefix: prefix), isNotEmpty, reason: prefix);
      }
    });

    test('rejects the identifiers of the starter', () {
      expect(errors(package: 'flutter_starter'), isNotEmpty);
      expect(errors(firebasePrefix: 'your-firebase-project'), isNotEmpty);
      expect(
        errors(package: 'flutterstarter', org: 'com.yourcompany'),
        isNotEmpty,
      );
    });
  });
}
