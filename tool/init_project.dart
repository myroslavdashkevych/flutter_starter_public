// Turns a fresh copy of the starter into a new project (docs/new-project.md).
//
// Usage: fvm dart run tool/init_project.dart --name "My App" --package my_app \
//   --org com.example --firebase-prefix my-app-demo [--dry-run]
import 'dart:io';

const _starterPackage = 'flutter_starter';
const _starterOrg = 'com.yourcompany';
const _starterAppId = '$_starterOrg.flutterstarter';
const _starterName = 'Flutter Starter';
const _starterFirebasePrefix = 'your-firebase-project';

const _mainActivityFile = 'MainActivity.kt';
const _kotlinRoot = 'android/app/src/main/kotlin';

/// This script and its test keep the starter's identifiers on purpose.
const _renameExcluded = {
  'tool/init_project.dart',
  'test/tool/init_project_test.dart',
};

/// Firebase config directory: never opened, see CLAUDE.md.
const _firebaseOptionsDir = 'lib/app/firebase/';

const _usage = '''
Usage: fvm dart run tool/init_project.dart --name "My App" --package my_app --org com.example --firebase-prefix my-app-demo [--dry-run]

  --name             App name on the device.
  --package          Dart package name, snake_case.
  --org              Organization, reverse domain.
  --firebase-prefix  Firebase project IDs become <prefix>-dev and <prefix>.
  --dry-run          Print all changes without writing anything.''';

/// Dart, Java and hard Kotlin keywords: none of them works as a package name
/// or as a segment of an Android namespace.
const _reservedWords = {
  'abstract', 'as', 'assert', 'async', 'await', 'boolean', 'break', 'byte', //
  'case', 'catch', 'char', 'class', 'const', 'continue', 'default', 'do',
  'double', 'dynamic', 'else', 'enum', 'export', 'extends', 'external', 'false',
  'final', 'finally', 'float', 'for', 'fun', 'function', 'goto', 'if',
  'implements', 'import', 'in', 'instanceof', 'int', 'interface', 'is', 'long',
  'native', 'new', 'null', 'object', 'package', 'private', 'protected',
  'public', 'rethrow', 'return', 'short', 'static', 'strictfp', 'super',
  'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 'true',
  'try', 'typealias', 'typeof', 'val', 'var', 'void', 'volatile', 'when',
  'while', 'with', 'yield',
};

final _packagePattern = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
final _orgPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$');
final _firebasePrefixPattern = RegExp(r'^[a-z][a-z0-9-]*[a-z0-9]$');

/// The name goes into Gradle, pbxproj, ARB and manifest values.
final _forbiddenNameChars = RegExp(r'["\\$&<>\n\r]');

class ProjectIds {
  const ProjectIds({
    required this.name,
    required this.package,
    required this.org,
    required this.firebasePrefix,
  });

  final String name;
  final String package;
  final String org;
  final String firebasePrefix;

  /// iOS bundle IDs do not allow underscores, so the same ID without them is
  /// used on both platforms.
  String get applicationId => '$org.${package.replaceAll('_', '')}';
  String get firebaseDev => '$firebasePrefix-dev';
  String get firebaseProd => firebasePrefix;
}

class CliOptions {
  const CliOptions(this.ids, {required this.dryRun});

  final ProjectIds ids;
  final bool dryRun;
}

class UsageException implements Exception {
  const UsageException(this.message);

  final String message;
}

/// Parses `--key value` and `--key=value` arguments.
CliOptions parseArgs(List<String> args) {
  const keys = {'name', 'package', 'org', 'firebase-prefix'};
  final values = <String, String>{};
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--dry-run') {
      dryRun = true;
      continue;
    }
    if (!arg.startsWith('--')) {
      throw UsageException('Unexpected argument: $arg');
    }
    final separator = arg.indexOf('=');
    final key = arg.substring(2, separator == -1 ? null : separator);
    if (!keys.contains(key)) throw UsageException('Unknown option: --$key');
    if (separator != -1) {
      values[key] = arg.substring(separator + 1);
    } else if (++i < args.length) {
      values[key] = args[i];
    } else {
      throw UsageException('Missing value for --$key');
    }
  }

  final missing = keys.where((key) => !values.containsKey(key));
  if (missing.isNotEmpty) {
    throw UsageException(
      'Missing options: ${missing.map((key) => '--$key').join(', ')}',
    );
  }

  final ids = ProjectIds(
    name: values['name']!.trim(),
    package: values['package']!,
    org: values['org']!,
    firebasePrefix: values['firebase-prefix']!,
  );
  final errors = validateIds(ids);
  if (errors.isNotEmpty) throw UsageException(errors.join('\n'));
  return CliOptions(ids, dryRun: dryRun);
}

/// Returns every problem with [ids]; empty when they are valid.
List<String> validateIds(ProjectIds ids) {
  final prefix = ids.firebasePrefix;
  return [
    if (ids.name.isEmpty) '--name must not be empty.',
    if (_forbiddenNameChars.hasMatch(ids.name))
      r'--name must not contain " \ $ & < > or line breaks.',
    if (!_packagePattern.hasMatch(ids.package))
      '--package must be snake_case: lowercase letters, digits, single '
          'underscores, starting with a letter.',
    if (_reservedWords.contains(ids.package))
      '--package must not be a reserved word: ${ids.package}.',
    if (ids.package == _starterPackage)
      '--package must differ from the starter package.',
    if (!_orgPattern.hasMatch(ids.org))
      '--org must be a reverse domain such as com.example: at least two '
          'dot-separated segments of lowercase letters and digits, each '
          'starting with a letter.',
    for (final segment in ids.org.split('.'))
      if (_reservedWords.contains(segment))
        '--org must not contain a reserved word: $segment.',
    if (ids.applicationId == _starterAppId)
      'The application ID must differ from the starter application ID.',
    if (prefix.length < 6 || prefix.length > 26)
      '--firebase-prefix must have 6-26 characters: Firebase project IDs have '
          '6-30 and the dev ID adds "-dev".',
    if (!_firebasePrefixPattern.hasMatch(prefix))
      '--firebase-prefix must use lowercase letters, digits and hyphens, start '
          'with a letter and not end with a hyphen.',
    if (prefix == _starterFirebasePrefix)
      '--firebase-prefix must differ from the starter prefix: the new app '
          "would use the starter's Firebase projects.",
  ];
}

/// Replaces all [replacements] in one pass, longest key first, so that a new
/// value is never replaced again.
String _replaceAll(String content, Map<String, String> replacements) {
  final keys = replacements.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  return content.replaceAllMapped(
    RegExp(keys.map(RegExp.escape).join('|')),
    (match) => replacements[match[0]]!,
  );
}

String renamePubspec(String content, ProjectIds ids) => content
    .replaceFirst(
      RegExp(r'^name: .*$', multiLine: true),
      'name: ${ids.package}',
    )
    .replaceFirst(
      RegExp(r'^description: .*$', multiLine: true),
      'description: "${ids.name} mobile app."',
    );

String renameDartImports(String content, ProjectIds ids) =>
    content.replaceAll('package:$_starterPackage', 'package:${ids.package}');

/// For `build.gradle.kts` and `project.pbxproj`. Flavor suffixes and the
/// `.RunnerTests` suffix stay, because only the shared prefix is replaced.
String renameAppIdAndName(String content, ProjectIds ids) => _replaceAll(
  content,
  {_starterAppId: ids.applicationId, _starterName: ids.name},
);

String renameAppId(String content, ProjectIds ids) =>
    _replaceAll(content, {_starterAppId: ids.applicationId});

String renameInfoPlist(String content, ProjectIds ids) => content.replaceAll(
  '<string>$_starterPackage</string>',
  '<string>${ids.package}</string>',
);

String renameAppTitle(String content, ProjectIds ids) => content.replaceAll(
  '"appTitle": "$_starterName"',
  '"appTitle": "${ids.name}"',
);

/// For `.firebaserc` and `config/*.json`. The dev ID stays correct because it
/// is the prefix plus `-dev`.
String renameFirebaseIds(String content, ProjectIds ids) =>
    _replaceAll(content, {_starterFirebasePrefix: ids.firebasePrefix});

String renameSetupDoc(String content, ProjectIds ids) => _replaceAll(content, {
  _starterAppId: ids.applicationId,
  _starterOrg: ids.org,
  _starterPackage: ids.package,
  _starterName: ids.name,
  _starterFirebasePrefix: ids.firebasePrefix,
});

class FileChange {
  const FileChange(this.path, this.before, this.after, {this.movedTo});

  final String path;
  final String before;
  final String after;
  final String? movedTo;
}

/// Computes every change without writing. [read] gets a path relative to the
/// project root and returns null for a missing file. [trackedDartFiles] are
/// the Dart files under version control.
///
/// Throws [StateError] when an expected file is missing or has nothing to
/// rename: the template has changed and this script must follow it.
List<FileChange> planChanges({
  required ProjectIds ids,
  required String? Function(String path) read,
  required Iterable<String> trackedDartFiles,
}) {
  const ownMainActivity =
      '$_kotlinRoot/com/yourcompany/flutterstarter/$_mainActivityFile';

  String require(String path) =>
      read(path) ?? (throw StateError('Expected file is missing: $path'));

  final rules = <String, String Function(String, ProjectIds)>{
    'pubspec.yaml': renamePubspec,
    'android/app/build.gradle.kts': renameAppIdAndName,
    'ios/Runner.xcodeproj/project.pbxproj': renameAppIdAndName,
    'ios/Runner/Info.plist': renameInfoPlist,
    'lib/l10n/arb/app_en.arb': renameAppTitle,
    'lib/l10n/arb/app_uk.arb': renameAppTitle,
    '.firebaserc': renameFirebaseIds,
    'config/dev.json': renameFirebaseIds,
    'config/prod.json': renameFirebaseIds,
    'docs/setup.md': renameSetupDoc,
  };

  final changes = <FileChange>[];
  rules.forEach((path, rename) {
    final before = require(path);
    final after = rename(before, ids);
    if (after == before) {
      throw StateError('Nothing to rename in $path');
    }
    changes.add(FileChange(path, before, after));
  });

  final mainActivity = require(ownMainActivity);
  changes.add(
    FileChange(
      ownMainActivity,
      mainActivity,
      renameAppId(mainActivity, ids),
      movedTo:
          '$_kotlinRoot/${ids.applicationId.replaceAll('.', '/')}/'
          '$_mainActivityFile',
    ),
  );

  for (final path in trackedDartFiles) {
    if (_renameExcluded.contains(path) ||
        path.startsWith(_firebaseOptionsDir)) {
      continue;
    }
    final before = require(path);
    final after = renameDartImports(before, ids);
    if (after != before) changes.add(FileChange(path, before, after));
  }
  return changes;
}

/// Lists changed lines; the renames never add or remove a line.
String describeChange(FileChange change) {
  final buffer = StringBuffer(change.path);
  if (change.movedTo != null) buffer.write(' -> ${change.movedTo}');
  buffer.writeln();
  final before = change.before.split('\n');
  final after = change.after.split('\n');
  for (var i = 0; i < before.length; i++) {
    if (before[i] == after[i]) continue;
    buffer
      ..writeln('  ${i + 1}: - ${before[i].trim()}')
      ..writeln('  ${i + 1}: + ${after[i].trim()}');
  }
  return buffer.toString();
}

String firebaseWarning() => '''
WARNING: the starter ships without Firebase configs. Generate them (step 2 below),
otherwise the app does not build or start:
  - android/app/src/{dev,prod}/google-services.json
  - ios/flavors/{dev,prod}/GoogleService-Info.plist
  - lib/app/firebase/firebase_options_{dev,prod}.dart (placeholders until then)
  - firebase.json (flutter section; iOS builds read it to upload Crashlytics symbols)''';

String _flutterfireCommand({
  required String project,
  required String flavor,
  required String appId,
  required String buildConfig,
}) =>
    '''
flutterfire configure \\
  --yes \\
  --project=$project \\
  --platforms=android,ios \\
  --out=lib/app/firebase/firebase_options_$flavor.dart \\
  --android-package-name=$appId \\
  --android-out=android/app/src/$flavor/google-services.json \\
  --ios-bundle-id=$appId \\
  --ios-build-config=$buildConfig \\
  --ios-out=ios/flavors/$flavor/GoogleService-Info.plist''';

/// One `flutterfire configure` run per iOS build configuration.
List<String> flutterfireCommands(ProjectIds ids) => [
  for (final mode in const ['Debug', 'Profile', 'Release'])
    _flutterfireCommand(
      project: ids.firebaseDev,
      flavor: 'dev',
      appId: '${ids.applicationId}.dev',
      buildConfig: '$mode-dev',
    ),
  for (final mode in const ['Debug', 'Profile', 'Release'])
    _flutterfireCommand(
      project: ids.firebaseProd,
      flavor: 'prod',
      appId: ids.applicationId,
      buildConfig: '$mode-prod',
    ),
];

String checklist(ProjectIds ids) =>
    '''
Next steps

1. Create two Firebase projects with these IDs (docs/setup.md section 5.1):
   dev:  ${ids.firebaseDev}
   prod: ${ids.firebaseProd}

2. Generate the Firebase configs. Check the flags against `flutterfire configure --help`:

${flutterfireCommands(ids).join('\n\n')}

3. Regenerate the code and check the project:

fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
fvm dart format lib test tool
fvm flutter analyze
fvm dart run tool/check_imports.dart
fvm flutter test
fvm flutter run --flavor dev --dart-define-from-file=config/dev.json

4. Replace what this script leaves alone (docs/new-project.md section 4):
   - launcher icons: assets/icons, then `fvm dart run flutter_launcher_icons`;
   - splash logo and colors, then `fvm dart run flutter_native_splash:create`;
   - hosting pages: hosting/*.html, including the app name and the privacy policy;
   - contact email: on the hosting pages and in both store consoles;
   - README.md and CLAUDE.md: the project name and description.

5. Remove the demo blocks and the optional blocks you do not need
   (docs/new-project.md section 5).

6. Before submitting to the stores, follow docs/store-release.md.''';

List<String> _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed. Run this script from the root of a git '
      'repository.',
    );
  }
  return (result.stdout as String)
      .split('\n')
      .where((line) => line.isNotEmpty)
      .toList();
}

void _apply(List<FileChange> changes) {
  for (final change in changes) {
    final file = File(change.path)..writeAsStringSync(change.after);
    final movedTo = change.movedTo;
    if (movedTo == null) continue;
    File(movedTo).parent.createSync(recursive: true);
    file.renameSync(movedTo);
    _deleteEmptyParents(file.parent, stopAt: _kotlinRoot);
  }
}

void _deleteEmptyParents(Directory directory, {required String stopAt}) {
  var current = directory;
  while (current.path != stopAt && current.listSync().isEmpty) {
    current.deleteSync();
    current = current.parent;
  }
}

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }

  try {
    final options = parseArgs(args);
    final ids = options.ids;

    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      throw StateError('Run this script from the project root.');
    }
    if (!pubspec.readAsStringSync().contains('name: $_starterPackage\n')) {
      throw StateError(
        'This project is already initialized: its pubspec.yaml name is not '
        '$_starterPackage.',
      );
    }
    if (_git(['status', '--porcelain']).isNotEmpty) {
      throw StateError(
        'The git working tree is not clean. Commit or stash your changes first.',
      );
    }

    final changes = planChanges(
      ids: ids,
      read: (path) {
        final file = File(path);
        return file.existsSync() ? file.readAsStringSync() : null;
      },
      trackedDartFiles: _git(['ls-files', '*.dart']),
    );

    if (options.dryRun) {
      stdout
        ..writeln('Dry run: nothing is written.\n')
        ..writeAll(changes.map(describeChange), '\n')
        ..writeln();
    } else {
      _apply(changes);
    }

    stdout
      ..writeln(
        '${options.dryRun ? 'Would update' : 'Updated'} ${changes.length} '
        'files. Application ID: ${ids.applicationId} (dev: '
        '${ids.applicationId}.dev).',
      )
      ..writeln()
      ..writeln(firebaseWarning())
      ..writeln()
      ..writeln(checklist(ids));
  } on UsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln()
      ..writeln(_usage);
    exitCode = 64;
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}
