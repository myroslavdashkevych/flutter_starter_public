// Enforces the architecture rules from doc/spec/architecture.md, Import rules:
// - which modules and areas may import each other (_allowedModules);
// - which external packages each module may import: allow lists for shared,
//   domain and l10n (_allowedPackages); package ownership between data and
//   presentation (_sharedPackages, _knownOwners);
// - Flutter and dart: libraries where they do not belong;
// - the service locator only in app/;
// - from doc/spec/architecture.md, Time: DateTime.now and
//   DateTime.timestamp only in shared/utils/clock.dart;
// - where files live (reserved names, use_case folders, name suffixes), the
//   folders of domain (by kind, use cases in groups: _serviceUseCaseGroups)
//   and the layout of a data area, with data sources named by a type from
//   _dataSourceTypes;
// - imports inside domain by kind (_domainKinds); what data and presentation
//   may import from domain (only Bloc files reach use cases); the external
//   packages of a repository implementation;
// - each data area has its repository and the matching contract;
// - use cases implement UseCase or StreamUseCase with a record parameter, and
//   repository contracts return Result or Stream;
// - one public type per file, and unique public type names in lib/;
// - singular names (_pluralNames): no folder in lib/ or test/ with a name that
//   ends in "s", singular area names, no folder or file named with the plural
//   of an area, and route paths named after their screens;
// - from doc/spec/architecture.md, State management: no Cubit, a
//   transformer on every Bloc event handler, no manual stream subscriptions in
//   Blocs;
// - and from doc/spec/architecture.md, Testing: every page has a page test
//   that calls testAccessibility.
// Every violation names the rule; add new rules here with a unit test.
//
// Usage: fvm dart run tool/check_imports.dart
import 'dart:io';

import 'review_diff.dart' show isNeverRead;

const _ownPackage = 'package:flutter_starter/';
const _layers = {'domain', 'data', 'presentation'};
const _unrestrictedModules = {'app', 'main.dart'};

const _allowedModules = {
  'shared': {'shared'},
  'domain': {'shared', 'domain'},
  'data': {'shared', 'domain', 'data'},
  'presentation': {'shared', 'domain', 'presentation', 'l10n'},
  'l10n': {'l10n'},
};

/// External packages allowed per module. data and presentation have no such
/// list: package ownership below decides for them.
const _allowedPackages = {
  'shared': {'injectable', 'talker', 'meta', 'collection'},
  'domain': {'freezed_annotation', 'meta', 'collection', 'stream_transform'},
  'l10n': {'flutter', 'flutter_localizations', 'intl'},
};

/// Single libraries allowed in a module whose package as a whole is not.
/// `domain` needs the `injectable` annotations but must not import `get_it`.
const _allowedLibraries = {
  'domain': {'package:injectable/injectable.dart'},
};

/// `dart:` libraries a module must not import: domain is pure Dart.
const _forbiddenDartLibraries = {
  'domain': {'dart:ui', 'dart:io', 'dart:ffi', 'dart:isolate', 'dart:html'},
};

/// Flutter libraries allowed where Flutter UI is not: data has no widgets, and
/// Bloc files never see a BuildContext.
const _dataFlutterLibraries = {'foundation.dart', 'services.dart'};
const _blocFlutterLibraries = {'foundation.dart'};
const _blocFileSuffixes = ['_bloc.dart', '_state.dart', '_event.dart'];

/// The design libraries moved out of the Flutter SDK: widgets, like
/// `package:flutter/material.dart` before them.
const _designPackages = {'material_ui', 'cupertino_ui'};

/// Package ownership (doc/spec/architecture.md, External packages). Every external package
/// belongs to either data or presentation, and the other layer must not import
/// it. A package imported by both layers is a violation unless it is listed in
/// [_sharedPackages]. New packages need no change here: the layer that imports
/// one owns it.
const _owningLayers = {'data', 'presentation'};

/// Packages that both data and presentation may import.
const _sharedPackages = {
  'flutter', // data: only _dataFlutterLibraries
  'freezed_annotation',
  'injectable',
  'stream_transform',
  'meta',
  'collection',
};

/// Owners known in advance, so that the first import of such a package in the
/// wrong layer is caught too. A trailing `*` matches any suffix.
const _knownOwners = {
  'data': {
    'dio',
    'http',
    'retrofit',
    'hive_ce',
    'hive_ce_flutter',
    'shared_preferences',
    'sqflite',
    'drift',
    'firebase_*',
  },
  'presentation': {
    'flutter_bloc',
    'bloc',
    'bloc_concurrency',
    ..._designPackages,
  },
};

const _ownershipDocs = 'doc/spec/architecture.md, External packages';

/// The domain is split by kind (doc/spec/architecture.md, Inside domain):
/// what each kind of folder may import from domain. A use case imports no
/// other use case, only the base classes in `_shared/base/use_case/`.
const _domainDocs = 'doc/spec/architecture.md, Inside domain';

/// A kind is a top folder of domain, or `_shared/<role>` (see [_domainKind]).
const _domainKinds = {
  'entity': {'entity'},
  'repository': {'entity', '_shared/wrapper'},
  'use_case': {
    'entity',
    'repository',
    'use_case',
    '_shared/base',
    '_shared/service',
    '_shared/wrapper',
  },
  '_shared/base': {'_shared/base', '_shared/wrapper'},
  '_shared/service': {'_shared/service'},
  '_shared/wrapper': {'_shared/wrapper'},
};

/// The roles in `domain/_shared`; each groups its files by subject
/// (`_shared/<role>/<subject>/<file>`).
const _domainSharedRolesBySubject = {'base', 'service', 'wrapper'};

/// The only port of `domain/_shared/service` that `app` imports: it reports
/// errors directly (doc/spec/architecture.md, Data flow).
const _appServicePorts = {'crash_reporting_service.dart'};

/// Use cases live in a group folder of `use_case/` (doc/spec/architecture.md,
/// Inside domain): a business area, which has a contract in
/// `domain/repository/`, or one of these groups for use cases that reach
/// only services.
const _serviceUseCaseGroups = {'observability'};

/// What data and presentation may import from domain
/// (doc/spec/architecture.md, Inside data; Inside presentation).
const _dataDocs = 'doc/spec/architecture.md, Inside data';
const _presentationDocs = 'doc/spec/architecture.md, Inside presentation';

/// The layout of a data area: one repository in the root, data sources named
/// by a type from a closed list (doc/spec/architecture.md, Inside a data
/// area). A new type is added here and in that section.
const _dataAreaDocs = 'doc/spec/architecture.md, Inside a data area';
const _dataSourceTypes = {'api', 'hive', 'prefs', 'fcm', 'notif', 'firebase'};
const _dataAreaFolders = {'data_source', 'model', 'mapper'};
const _dataSharedFolders = {'base', 'data_source', 'service'};
const _repositoryImplSuffix = '_repository_impl.dart';

/// A repository reaches SDKs, clients and storage only through its data
/// sources, so it imports no other external package.
const _repositoryImplPackages = {
  'injectable',
  'talker',
  'stream_transform',
  'meta',
  'collection',
};

/// Use cases (doc/spec/architecture.md, Use cases).
const _useCaseDocs = 'doc/spec/architecture.md, Use cases';
final _useCaseBase = RegExp(r'\bimplements\s+(?:UseCase|StreamUseCase)\s*<');

/// Repository contracts return `Result` or `Stream`.
/// A member declared at the class indent, with its return type: methods,
/// getters and record return types. The formatter keeps a return type and
/// its member name on one line.
final _contractMember = RegExp(
  r'^  ([A-Za-z(][\w<>?, ()]*?)\s+(?:get\s+)?\w+\s*(?:\(|;|=>)',
);
final _contractReturn = RegExp(r'^(?:Future<Result<.+>>|Stream<.+>)$');

/// Ports and base classes of the domain and the base classes of the data
/// layer are contracts only (doc/spec/architecture.md, Principles): the
/// folders that hold them declare no `abstract class` without `interface`.
const _portFolders = [
  ['domain', 'repository'],
  ['domain', '_shared', 'service'],
  ['domain', '_shared', 'base'],
  ['data', '_shared', 'base'],
];
final _plainAbstractClass = RegExp(r'^abstract\s+class\s+(\w+)');

/// Every cache is evicted after startup (doc/spec/architecture.md, Local
/// storage): each class that implements `ExpiringCache` is in the list of
/// `_evictExpiredCaches` in `app/bootstrap.dart`.
const _bootstrapPath = 'lib/app/bootstrap.dart';
final _expiringCacheClass = RegExp(
  r'^(?:(?:abstract|base|final|sealed|interface)\s+)*class\s+(\w+)'
  r'[^{]*\bimplements\b[^{]*\bExpiringCache\b',
  multiLine: true,
);
final _evictedCacheList = RegExp(
  r'List<ExpiringCache>\s+caches\s*=\s*\[([^\]]*)\]',
);
final _evictedCache = RegExp(r'getIt<(\w+)>\(\)');

/// One public type per file (doc/spec/architecture.md, Principles).
const _typesDocs = 'doc/spec/architecture.md, Principles';
const _typesExempt = {'lib/app/router/routes.dart'};
final _typeDeclaration = RegExp(
  r'^(?:(?:abstract|sealed|final|base|interface)\s+)*'
  r'(class|enum|mixin|typedef|extension)\s+([A-Za-z_]\w*)',
  multiLine: true,
);
const _generatedSuffixes = ['.g.dart', '.freezed.dart', '.config.dart'];

/// Every folder and file name is singular (doc/spec/code-style.md, Singular
/// names). The names that end in "s" and are allowed: plural by convention
/// (`settings`, `utils`, `prefs`) and an uncountable noun (`analytics`). A name
/// of a collection (`UserFavorites`) may be plural when the plural does not
/// start the name; it needs no entry, because only a name that starts with the
/// plural of an area is flagged. An area is named by its contract
/// `domain/repository/<area>_repository.dart`; `settings` is the one area that
/// stays plural.
const _namingDocs = 'doc/spec/code-style.md, Singular names';
const _pluralNames = {'settings', 'utils', 'prefs', 'analytics'};
const _repositoriesDir = 'lib/domain/repository/';
const _contractSuffix = '_repository.dart';

/// A static route path segment is its screen name in kebab-case: the routes
/// name their screens through `_ScreenNames` in `app/router/routes.dart`.
const _routesPath = 'lib/app/router/routes.dart';
final _screenNamesClass = RegExp(r'class\s+_ScreenNames\s*\{([^}]*)\}');
final _screenName = RegExp(r"static\s+const\s+(\w+)\s*=\s*'([^']*)'");
final _namedRoute = RegExp(r"path:\s*'([^']*)',\s*name:\s*_ScreenNames\.(\w+)");

/// The service locator is used only in `app/`; everything else receives
/// dependencies through constructors. `injectable.dart` re-exports
/// `GetItHelper`, so imports alone cannot enforce this.
final _serviceLocator = RegExp(r'\b(?:getIt|GetIt|GetItHelper)\b');

const _clockPath = 'lib/shared/utils/clock.dart';
final _systemTime = RegExp(r'\bDateTime\s*\.\s*(?:now|timestamp)\b');

/// State holders are Blocs (doc/spec/architecture.md, State management).
const _stateDocs = 'doc/spec/architecture.md, State management';
final _cubitClass = RegExp(r'\bextends\s+Cubit\s*<');
final _eventHandler = RegExp(r'\bon<');
final _manualSubscription = RegExp(r'\.listen\(|\bStreamSubscription\b');

/// Every page has a page test that checks the accessibility requirements
/// (doc/spec/architecture.md, Testing).
const _testingDocs = 'doc/spec/architecture.md, Testing';
final _pagePath = RegExp(r'^lib/(presentation/(?:.+/)?\w+_page)\.dart$');
const _accessibilityCall = 'testAccessibility(';

/// The layer where files with these name suffixes live.
const _suffixLayers = {
  '_dto.dart': 'data',
  '_repository_impl.dart': 'data',
  '_use_case.dart': 'domain',
  '_bloc.dart': 'presentation',
};

final _directive = RegExp(
  '^[ \\t]*(?:import|export)\\s+[\'"]([^\'"]+)[\'"]',
  multiLine: true,
);

class Violation {
  const Violation(this.path, this.line, this.rule);

  final String path;
  final int line;
  final String rule;

  @override
  String toString() => '$path:$line: $rule';
}

/// Returns the broken rule for importing [uri] from the file at [path], or
/// null when the import is allowed. [path] is relative to the project root.
String? checkImport(String path, String uri) {
  final from = _libSegments(path)!;
  final module = from.first;
  if (_unrestrictedModules.contains(module)) {
    // Generated DI code registers every class, so it imports every port.
    return _isGenerated(path) ? null : _checkAppImport(uri);
  }

  if (uri.startsWith('dart:')) {
    return (_forbiddenDartLibraries[module]?.contains(uri) ?? false)
        ? '$module must not import $uri'
        : null;
  }
  if (_isExternalPackage(uri)) {
    return _checkFlutterLibrary(path, module, uri) ??
        _checkPackage(module, uri) ??
        _checkRepositoryPackage(path, module, uri);
  }

  final to = uri.startsWith(_ownPackage)
      ? uri.substring(_ownPackage.length).split('/')
      : _libSegments(Uri.parse(path).resolve(uri).path);
  if (to == null) return '$uri is outside lib/';
  return _checkInternal(path, from, to);
}

/// Returns the broken rule for the location of the file at [path] itself.
String? checkLocation(String path) {
  final segments = _libSegments(path)!;
  final module = segments.first;
  if (!_isKnownModule(path)) return 'unknown top-level module "$module"';
  if (_layers.contains(module) && segments[1] == 'shared') {
    return '"shared" is a reserved name and cannot be used in $module';
  }
  if (module == 'presentation' &&
      segments.sublist(1, segments.length - 1).contains('use_case')) {
    return 'use cases live in domain/use_case, not in presentation';
  }
  if (path.endsWith('_cubit.dart')) {
    return '*_cubit.dart files are not used: state holders are Blocs '
        '($_stateDocs)';
  }
  for (final MapEntry(key: suffix, value: layer) in _suffixLayers.entries) {
    if (!path.endsWith(suffix)) continue;
    if (layer == 'domain') {
      final inUseCases =
          module == 'domain' &&
          (segments[1] == 'use_case' ||
              (segments.length > 3 &&
                  segments[1] == '_shared' &&
                  segments[2] == 'base' &&
                  segments[3] == 'use_case'));
      if (!inUseCases) return '*$suffix files live in domain/use_case';
      continue;
    }
    if (module != layer) return '*$suffix files live in $layer';
  }
  if (module == 'domain') return _checkDomainLayout(segments);
  if (module == 'data') return _checkDataLayout(segments);
  return null;
}

/// Checks one file with the given [content].
List<Violation> checkFile(String path, String content) {
  final violations = <Violation>[];
  final locationRule = checkLocation(path);
  if (locationRule != null) violations.add(Violation(path, 1, locationRule));
  if (!_isKnownModule(path)) return violations;

  for (final (:uri, :line) in _directives(content)) {
    final rule = checkImport(path, uri);
    if (rule != null) violations.add(Violation(path, line, rule));
  }

  final lines = content.split('\n');
  violations
    ..addAll(_checkStateHolders(path, lines))
    ..addAll(_checkSystemTime(path, lines));
  if (!_isGenerated(path)) {
    violations
      ..addAll(_checkTypes(path, content))
      ..addAll(_checkUseCase(path, content))
      ..addAll(_checkContract(path, lines))
      ..addAll(_checkPorts(path, lines));
  }
  if (_unrestrictedModules.contains(_libSegments(path)!.first)) {
    return violations;
  }
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('//')) continue;
    final match = _serviceLocator.firstMatch(lines[i]);
    if (match == null) continue;
    violations.add(
      Violation(
        path,
        i + 1,
        '${match[0]} is used only in app/; receive dependencies through the '
        'constructor',
      ),
    );
  }
  return violations;
}

/// The current time only through `Clock` (doc/spec/architecture.md, Time).
/// Line comments are skipped.
List<Violation> _checkSystemTime(String path, List<String> lines) => [
  if (path != _clockPath)
    for (var i = 0; i < lines.length; i++)
      if (!lines[i].trimLeft().startsWith('//') &&
          _systemTime.hasMatch(lines[i]))
        Violation(
          path,
          i + 1,
          'the current time is read only through Clock '
          '(doc/spec/architecture.md, Time)',
        ),
];

/// Checks [files] (path to content) as one project: every file on its own,
/// then package ownership across data and presentation.
List<Violation> checkFiles(Map<String, String> files) {
  final violations = [
    for (final MapEntry(key: path, value: content) in files.entries)
      ...checkFile(path, content),
  ];

  final importsByPackage = <String, List<({String path, int line})>>{};
  final layersByPackage = <String, Set<String>>{};
  for (final MapEntry(key: path, value: content) in files.entries) {
    final layer = _libSegments(path)?.first;
    if (!_owningLayers.contains(layer)) continue;
    for (final (:uri, :line) in _directives(content)) {
      if (!_isExternalPackage(uri)) continue;
      final package = _packageName(uri);
      if (_sharedPackages.contains(package) || _knownOwner(package) != null) {
        continue;
      }
      (importsByPackage[package] ??= []).add((path: path, line: line));
      (layersByPackage[package] ??= {}).add(layer!);
    }
  }
  for (final MapEntry(key: package, value: imports)
      in importsByPackage.entries) {
    if (layersByPackage[package]!.length < 2) continue;
    for (final (:path, :line) in imports) {
      violations.add(
        Violation(
          path,
          line,
          'package:$package is imported by both data and presentation. '
          'Keep it in one layer, or add it to _sharedPackages in '
          'tool/check_imports.dart ($_ownershipDocs)',
        ),
      );
    }
  }

  violations
    ..addAll(_checkDataAreas(files.keys))
    ..addAll(_checkUseCaseGroups(files.keys))
    ..addAll(_checkServiceImplementations(files))
    ..addAll(_checkEvictedCaches(files))
    ..addAll(_checkUniqueTypes(files))
    ..addAll(checkFolderNames(files.keys))
    ..addAll(_checkSingularNames(files.keys))
    ..addAll(_checkRoutePaths(files[_routesPath]));

  return violations..sort(
    (a, b) =>
        a.path == b.path ? a.line.compareTo(b.line) : a.path.compareTo(b.path),
  );
}

/// Returns a violation for each page in [libPaths] whose page test in
/// [pageTests] (path to content) is missing or does not call
/// `testAccessibility` outside a comment.
List<Violation> checkPageTests(
  Iterable<String> libPaths,
  Map<String, String> pageTests,
) => [
  for (final path in libPaths)
    if (_pagePath.firstMatch(path) case final match?)
      if (_pageTestRule('test/${match[1]}_test.dart', pageTests)
          case final rule?)
        Violation(path, 1, rule),
];

String? _pageTestRule(String testPath, Map<String, String> pageTests) {
  final content = pageTests[testPath];
  if (content == null) {
    return '$testPath is missing: every page test calls testAccessibility '
        '($_testingDocs)';
  }
  final calls = content
      .split('\n')
      .any(
        (line) =>
            !line.trimLeft().startsWith('//') &&
            line.contains(_accessibilityCall),
      );
  return calls
      ? null
      : '$testPath does not call testAccessibility ($_testingDocs)';
}

/// Checks every Dart file under `lib/` in [root], except never-read files
/// (`isNeverRead` in tool/review_diff.dart), which are never read, the folder
/// names under `test/` and the page tests.
List<Violation> checkProject(Directory root) {
  final prefixLength = root.path.length + 1;
  final testRoot = Directory('${root.path}/test');
  final libFiles = {
    for (final file in Directory('${root.path}/lib').listSync(recursive: true))
      if (file is File &&
          file.path.endsWith('.dart') &&
          !isNeverRead(file.path.substring(prefixLength)))
        file.path.substring(prefixLength): file.readAsStringSync(),
  };
  final testFiles = testRoot.existsSync()
      ? [
          for (final file in testRoot.listSync(recursive: true))
            if (file is File) file,
        ]
      : <File>[];
  return [
    ...checkFiles(libFiles),
    ...checkFolderNames([
      for (final file in testFiles) file.path.substring(prefixLength),
    ]),
    ...checkPageTests(libFiles.keys, {
      for (final file in testFiles)
        if (file.path.endsWith('_page_test.dart') &&
            !isNeverRead(file.path.substring(prefixLength)))
          file.path.substring(prefixLength): file.readAsStringSync(),
    }),
  ];
}

/// Writes the report for [root] to [out] and returns the exit code.
int run(Directory root, StringSink out) {
  final violations = checkProject(root);
  if (violations.isEmpty) {
    out.writeln('No import violations.');
    return 0;
  }
  violations.forEach(out.writeln);
  out.writeln('${violations.length} import violation(s).');
  return 1;
}

void main() {
  exitCode = run(Directory.current, stdout);
}

bool _isKnownModule(String path) {
  final module = _libSegments(path)!.first;
  return _unrestrictedModules.contains(module) ||
      _allowedModules.containsKey(module);
}

List<String>? _libSegments(String path) {
  final segments = path.split('/');
  return segments.first == 'lib' ? segments.sublist(1) : null;
}

Iterable<({String uri, int line})> _directives(String content) => _directive
    .allMatches(content)
    .map(
      (match) => (
        uri: match.group(1)!,
        line: '\n'.allMatches(content.substring(0, match.start)).length + 1,
      ),
    );

bool _isExternalPackage(String uri) =>
    uri.startsWith('package:') && !uri.startsWith(_ownPackage);

String _packageName(String uri) =>
    uri.substring('package:'.length).split('/').first;

String? _knownOwner(String package) {
  for (final MapEntry(key: layer, value: patterns) in _knownOwners.entries) {
    for (final pattern in patterns) {
      final matches = pattern.endsWith('*')
          ? package.startsWith(pattern.substring(0, pattern.length - 1))
          : package == pattern;
      if (matches) return layer;
    }
  }
  return null;
}

String? _checkFlutterLibrary(String path, String module, String uri) {
  final isDesignPackage = _designPackages.any(
    (package) => uri.startsWith('package:$package/'),
  );
  if (isDesignPackage &&
      module == 'presentation' &&
      _blocFileSuffixes.any(path.endsWith)) {
    return 'Bloc files must not import $uri: they never use BuildContext or '
        'widgets';
  }
  if (!uri.startsWith('package:flutter/')) return null;
  final library = uri.substring('package:flutter/'.length);
  if (module == 'data' && !_dataFlutterLibraries.contains(library)) {
    return 'data must not import $uri: from Flutter, data may use only '
        '${_dataFlutterLibraries.join(' and ')}';
  }
  final isBlocFile = _blocFileSuffixes.any(path.endsWith);
  if (module == 'presentation' &&
      isBlocFile &&
      !_blocFlutterLibraries.contains(library)) {
    return 'Bloc files must not import $uri: they never use BuildContext or '
        'widgets';
  }
  return null;
}

String? _checkPackage(String module, String uri) {
  final package = _packageName(uri);
  final owner = _knownOwner(package);
  if (_owningLayers.contains(module) && owner != null && owner != module) {
    return '$module must not import $uri: $package belongs to $owner '
        '(_knownOwners in tool/check_imports.dart, $_ownershipDocs)';
  }

  final allowed = _allowedPackages[module];
  if (allowed == null) return null;
  if (_allowedLibraries[module]?.contains(uri) ?? false) return null;
  return allowed.contains(package) ? null : '$module must not import $uri';
}

String? _checkInternal(String path, List<String> from, List<String> to) {
  final module = from.first;
  final target = to.first;
  if (!_allowedModules[module]!.contains(target)) {
    return '$module must not import $target';
  }
  if (module == 'domain') {
    return target == 'domain' ? _checkInsideDomain(from, to) : null;
  }
  if (target == 'domain') return _checkDomainImport(path, from, to);
  if (module != target || !_layers.contains(module)) return null;

  final fromArea = from[1];
  final toArea = to[1];
  if (toArea == '_shared' || toArea == fromArea) return null;
  return '$module/$fromArea must not import $module/$toArea';
}

/// The kind of a domain path: its top folder, or `_shared/<role>`.
String _domainKind(List<String> segments) {
  if (segments.length < 2) return '';
  if (segments[1] != '_shared') return segments[1];
  return segments.length > 3 ? '_shared/${segments[2]}' : '_shared';
}

/// Imports between the kinds of domain folders.
String? _checkInsideDomain(List<String> from, List<String> to) {
  final fromKind = _domainKind(from);
  final toKind = _domainKind(to);
  if (fromKind == 'use_case' && toKind == 'use_case') {
    return 'a use case must not import another use case ($_useCaseDocs)';
  }
  final allowed = _domainKinds[fromKind] ?? const <String>{};
  if (!allowed.contains(toKind)) {
    return 'domain/$fromKind must not import domain/$toKind ($_domainDocs)';
  }
  return null;
}

/// What app imports from domain/_shared: only the crash reporting port, to
/// report errors, and no base class.
String? _checkAppImport(String uri) {
  if (!uri.startsWith(_ownPackage)) return null;
  final to = uri.substring(_ownPackage.length).split('/');
  if (to.first != 'domain') return null;
  return switch (_domainKind(to)) {
    '_shared/service' when !_appServicePorts.contains(to.last) =>
      'app imports from domain/_shared/service only '
          '${_appServicePorts.join(', ')}; analytics goes through a use case '
          '($_domainDocs)',
    '_shared/base' =>
      'only use cases import domain/_shared/base ($_domainDocs)',
    _ => null,
  };
}

/// What data and presentation may import from domain.
String? _checkDomainImport(String path, List<String> from, List<String> to) {
  final module = from.first;
  final toKind = _domainKind(to);
  final toPath = to.skip(1).join('/');
  if (toKind == 'entity' || toKind == '_shared/wrapper') return null;

  if (module == 'data') {
    final area = from[1];
    final isSharedServices =
        area == '_shared' && from.length > 2 && from[2] == 'service';
    if (toKind == '_shared/service' && isSharedServices) return null;
    final ownContract = '${area}_repository.dart';
    if (toKind == 'repository' && to.length == 3 && to[2] == ownContract) {
      return null;
    }
    return 'data/$area must not import domain/$toPath: a data area imports '
        'from domain only its own contract, entities and _shared/wrapper '
        '($_dataDocs)';
  }

  final isBlocFile = _blocFileSuffixes.any(path.endsWith);
  if (isBlocFile && toKind == 'use_case') return null;
  return isBlocFile
      ? 'Bloc files import from domain only use cases, entities and '
            '_shared/wrapper, not domain/$toPath ($_presentationDocs)'
      : 'presentation imports from domain only entities and _shared/wrapper; '
            'only Bloc files import use cases, not domain/$toPath '
            '($_presentationDocs)';
}

/// A repository implementation imports only the listed external packages.
String? _checkRepositoryPackage(String path, String module, String uri) {
  if (module != 'data' || !path.endsWith(_repositoryImplSuffix)) return null;
  final package = _packageName(uri);
  return _repositoryImplPackages.contains(package)
      ? null
      : 'a repository must not import $uri: it reaches SDKs, clients and '
            'storage only through its data sources ($_dataAreaDocs)';
}

String? _checkDomainLayout(List<String> segments) {
  final kind = _domainKind(segments);
  if (!_domainKinds.containsKey(kind) || segments.length < 3) {
    return 'domain has only the folders entity, repository, use_case and '
        '_shared (base, service, wrapper); "${segments.sublist(1, segments.length - 1).join('/')}" '
        'is not one of them ($_domainDocs)';
  }
  final role = kind.startsWith('_shared/') ? segments[2] : null;
  final expectedLength = switch (kind) {
    'use_case' => 4,
    _ when _domainSharedRolesBySubject.contains(role) => 5,
    _ => 3,
  };
  if (segments.length == expectedLength) return null;
  return switch (kind) {
    'use_case' =>
      'a use case lives in a group folder of domain/use_case, one level deep '
          '($_domainDocs)',
    _ when _domainSharedRolesBySubject.contains(role) =>
      'domain/$kind holds one folder per subject, one level deep '
          '($_domainDocs)',
    _ => 'domain/$kind has no subfolders ($_domainDocs)',
  };
}

/// Each use case group is a business area with a contract, or a group in
/// [_serviceUseCaseGroups].
List<Violation> _checkUseCaseGroups(Iterable<String> paths) {
  final pathSet = paths.toSet();
  return [
    for (final path in pathSet)
      if (_libSegments(path) case ['domain', 'use_case', final group, _]
          when !_serviceUseCaseGroups.contains(group) &&
              !pathSet.contains(
                'lib/domain/repository/${group}_repository.dart',
              ))
        Violation(
          path,
          1,
          'domain/use_case/$group is not a use case group: a group is a '
          'business area with a contract in domain/repository, or one of '
          '${_serviceUseCaseGroups.join(', ')} ($_domainDocs)',
        ),
  ];
}

List<Violation> _checkEvictedCaches(Map<String, String> files) {
  final list = _evictedCacheList.firstMatch(files[_bootstrapPath] ?? '');
  final evicted = {
    for (final match in _evictedCache.allMatches(list?[1] ?? '')) match[1],
  };
  final violations = <Violation>[];
  for (final MapEntry(key: path, value: content) in files.entries) {
    if (_libSegments(path)?.first != 'data' || _isGenerated(path)) continue;
    for (final match in _expiringCacheClass.allMatches(content)) {
      final name = match[1]!;
      if (evicted.contains(name)) continue;
      violations.add(
        Violation(
          path,
          '\n'.allMatches(content.substring(0, match.start)).length + 1,
          '$name is a cache: add getIt<$name>() to the list in '
          '_evictExpiredCaches in app/bootstrap.dart '
          '(doc/spec/architecture.md, Local storage)',
        ),
      );
    }
  }
  return violations;
}

/// `data/_shared/service` mirrors `domain/_shared/service`: one folder per
/// service, named like its port folder. A file in it is a DI module of one SDK
/// (`<sdk>_module.dart`) or the implementation of a port of that folder, named
/// after the SDK it wraps: `<sdk>_<port>.dart` with a class that implements
/// the port (doc/spec/code-style.md, Files and types).
List<Violation> _checkServiceImplementations(Map<String, String> files) {
  const portsDir = 'lib/domain/_shared/service/';
  final portsBySubject = <String, List<String>>{};
  for (final path in files.keys) {
    if (!path.startsWith(portsDir) || _isGenerated(path)) continue;
    final parts = path.substring(portsDir.length).split('/');
    if (parts.length == 2) (portsBySubject[parts[0]] ??= []).add(parts[1]);
  }
  final violations = <Violation>[];
  for (final MapEntry(key: path, value: content) in files.entries) {
    final segments = _libSegments(path);
    if (segments == null ||
        segments.length < 4 ||
        segments[0] != 'data' ||
        segments[1] != '_shared' ||
        segments[2] != 'service' ||
        _isGenerated(path)) {
      continue;
    }
    final ports = segments.length == 5 ? portsBySubject[segments[3]] : null;
    if (ports == null) {
      violations.add(
        Violation(
          path,
          1,
          'data/_shared/service holds one folder per service, named like '
          'its folder in domain/_shared/service '
          '(doc/spec/code-style.md, Files and types)',
        ),
      );
      continue;
    }
    final file = segments[4];
    if (file.endsWith('_module.dart')) continue;
    final port = ports.where((port) => file.endsWith('_$port')).firstOrNull;
    final portType = port == null ? null : _pascalCase(_sourceName(port));
    final implementsPort =
        portType != null &&
        RegExp('\\bimplements\\b[^{]*\\b$portType\\b').hasMatch(content);
    if (implementsPort) continue;
    violations.add(
      Violation(
        path,
        1,
        port == null
            ? 'a file in data/_shared/service/${segments[3]} is '
                  '<sdk>_<port>.dart for a port of '
                  'domain/_shared/service/${segments[3]}, or a DI module '
                  '<sdk>_module.dart '
                  '(doc/spec/code-style.md, Files and types)'
            : 'the class in $file implements $portType '
                  '(doc/spec/code-style.md, Files and types)',
      ),
    );
  }
  return violations;
}

String? _checkDataLayout(List<String> segments) {
  if (segments.length < 3) {
    return 'files in data live in an area folder or in data/_shared '
        '($_dataAreaDocs)';
  }
  final area = segments[1];
  if (area == '_shared') {
    return segments.length > 3 && _dataSharedFolders.contains(segments[2])
        ? null
        : 'data/_shared has only ${_dataSharedFolders.join(', ')} '
              '($_dataAreaDocs)';
  }
  final name = _sourceName(segments.last);
  if (segments.length == 3) {
    return name == '$area$_repositoryImplSuffix'
        ? null
        : 'the root of data/$area holds only $area$_repositoryImplSuffix '
              '($_dataAreaDocs)';
  }
  final folder = segments[2];
  if (segments.length > 4 || !_dataAreaFolders.contains(folder)) {
    return 'data/$area has only the folders ${_dataAreaFolders.join(', ')}, '
        'without subfolders ($_dataAreaDocs)';
  }
  final valid = switch (folder) {
    'data_source' => RegExp(
      '^${area}_(${_dataSourceTypes.join('|')})_'
      r'(data_source|exception|module)\.dart$',
    ).hasMatch(name),
    'model' => name.endsWith('_dto.dart'),
    _ => name.endsWith('_mapper.dart'),
  };
  if (valid) return null;
  return switch (folder) {
    'data_source' =>
      'data/$area/data_source holds only ${area}_<type>_data_source.dart, '
          '${area}_<type>_exception.dart and ${area}_<type>_module.dart, with a type '
          'in ${_dataSourceTypes.join(', ')} ($_dataAreaDocs)',
    'model' => 'data/$area/model holds only *_dto.dart ($_dataAreaDocs)',
    _ => 'data/$area/mapper holds only *_mapper.dart ($_dataAreaDocs)',
  };
}

/// Every data area has its repository and the matching contract.
List<Violation> _checkDataAreas(Iterable<String> paths) {
  final pathSet = paths.toSet();
  final firstFileOfArea = <String, String>{};
  for (final path in pathSet) {
    final segments = _libSegments(path);
    if (segments == null || segments.first != 'data' || segments.length < 3) {
      continue;
    }
    if (segments[1] == '_shared') continue;
    final current = firstFileOfArea[segments[1]];
    if (current == null || path.compareTo(current) < 0) {
      firstFileOfArea[segments[1]] = path;
    }
  }
  return [
    for (final MapEntry(key: area, value: firstFile) in firstFileOfArea.entries)
      if (!pathSet.contains('lib/data/$area/$area$_repositoryImplSuffix'))
        Violation(
          firstFile,
          1,
          'data/$area has no $area$_repositoryImplSuffix in its root: each '
          'data area has one repository ($_dataAreaDocs)',
        )
      else if (!pathSet.contains(
        'lib/domain/repository/${area}_repository.dart',
      ))
        Violation(
          'lib/data/$area/$area$_repositoryImplSuffix',
          1,
          'data/$area has no contract domain/repository/'
              '${area}_repository.dart ($_dataAreaDocs)',
        ),
  ];
}

/// Every folder under lib/ and test/ has a singular name: a folder name that
/// ends in "s" must be in [_pluralNames]. Reports each such folder once.
List<Violation> checkFolderNames(Iterable<String> paths) {
  final folders = <String>{};
  for (final path in paths) {
    final segments = path.split('/');
    for (var i = 0; i < segments.length - 1; i++) {
      final name = segments[i];
      if (name.endsWith('s') && !_pluralNames.contains(name)) {
        folders.add(segments.sublist(0, i + 1).join('/'));
      }
    }
  }
  return [
    for (final folder in folders.toList()..sort())
      Violation(
        folder,
        1,
        '${folder.split('/').last} is plural: every folder name is singular; '
        'only ${_pluralNames.join(', ')} may end in "s" ($_namingDocs)',
      ),
  ];
}

/// An area name is singular unless it is in [_pluralNames], and no folder
/// or file in lib/ starts with the plural of an area: a name formed from an
/// area uses it in the singular. A plural later in a name (`user_favorites`,
/// `watch_favorites_use_case`) names a collection and passes.
List<Violation> _checkSingularNames(Iterable<String> paths) {
  final areas = {
    for (final path in paths)
      if (path.startsWith(_repositoriesDir) &&
          path.endsWith(_contractSuffix) &&
          !path.substring(_repositoriesDir.length).contains('/'))
        path.substring(
          _repositoriesDir.length,
          path.length - _contractSuffix.length,
        ),
  };
  final areaOfPlural = {
    for (final area in areas)
      if (!_pluralNames.contains(area)) '${area}s': area,
  };
  final violations = [
    for (final area in areas)
      if (area.endsWith('s') && !_pluralNames.contains(area))
        Violation(
          '$_repositoriesDir$area$_contractSuffix',
          1,
          'area $area is plural: an area name is singular unless it is '
              'listed in _pluralNames ($_namingDocs)',
        ),
  ];
  for (final path in paths) {
    final segments = _libSegments(path);
    if (segments == null || _isGenerated(path)) continue;
    for (final segment in segments) {
      final name = segment.endsWith('.dart')
          ? segment.substring(0, segment.length - '.dart'.length)
          : segment;
      final area = areaOfPlural.entries
          .where(
            (entry) => name == entry.key || name.startsWith('${entry.key}_'),
          )
          .firstOrNull
          ?.value;
      if (area == null) continue;
      violations.add(
        Violation(
          path,
          1,
          '$segment starts with the plural of area $area: a name formed '
          'from an area uses it in the singular ($_namingDocs)',
        ),
      );
      break;
    }
  }
  return violations;
}

/// Each route in `app/router/routes.dart` whose path ends in a static segment
/// uses its screen name in kebab-case there (`/sign-in` for `sign_in`).
/// Parameter segments (`:id`) are skipped.
List<Violation> _checkRoutePaths(String? content) {
  if (content == null) return const [];
  final screenNames = {
    for (final match in _screenName.allMatches(
      _screenNamesClass.firstMatch(content)?[1] ?? '',
    ))
      match[1]!: match[2]!,
  };
  final violations = <Violation>[];
  for (final match in _namedRoute.allMatches(content)) {
    final segment = match[1]!.split('/').last;
    if (segment.isEmpty || segment.startsWith(':')) continue;
    final screen = screenNames[match[2]] ?? match[2]!;
    final expected = screen.replaceAll('_', '-');
    if (segment == expected) continue;
    violations.add(
      Violation(
        _routesPath,
        '\n'.allMatches(content.substring(0, match.start)).length + 1,
        'route path segment $segment is not its screen name $screen in '
        'kebab-case ($expected) ($_namingDocs)',
      ),
    );
  }
  // A route tree the pattern no longer reads would pass silently.
  if (content.contains('TypedGoRoute<') && !_namedRoute.hasMatch(content)) {
    violations.add(
      const Violation(
        _routesPath,
        1,
        "no route reads as path: '...', name: _ScreenNames.x, so route "
        'paths cannot be checked against their screen names ($_namingDocs)',
      ),
    );
  }
  return violations;
}

/// A file with public types declares the one named after it; its other
/// public types are its sealed variants (directly or through one another) or
/// enums. Extensions are exempt from the name rule.
List<Violation> _checkTypes(String path, String content) {
  if (_typesExempt.contains(path)) return const [];
  final declarations = _publicDeclarations(content);
  final types = [
    for (final declaration in declarations)
      if (declaration.kind != 'extension') declaration,
  ];
  if (types.isEmpty) return const [];

  final expected = _pascalCase(_sourceName(path.split('/').last));
  final main = types.where((type) => type.name == expected).firstOrNull;
  if (main == null) {
    return [
      Violation(
        path,
        types.first.line,
        'a file with public types declares the one named after it, '
        '$expected ($_typesDocs)',
      ),
    ];
  }
  final allowed = {expected};
  final pending = [
    for (final type in types)
      if (type.name != expected && type.kind != 'enum') type,
  ];
  var changed = true;
  while (changed) {
    changed = false;
    for (final type in [...pending]) {
      final supertype = RegExp(r'\b(?:extends|implements)\s+([^{;]*)')
          .firstMatch(type.header)
          ?.group(1);
      final names = RegExp(r'\b[A-Z]\w*').allMatches(supertype ?? '');
      if (names.any((name) => allowed.contains(name[0]))) {
        allowed.add(type.name);
        pending.remove(type);
        changed = true;
      }
    }
  }
  return [
    for (final type in pending)
      Violation(
        path,
        type.line,
        '${type.name} is a second public type in a file of $expected: only its '
        'sealed variants and enums may join it ($_typesDocs)',
      ),
  ];
}

/// Every public type and extension name is unique in lib/.
List<Violation> _checkUniqueTypes(Map<String, String> files) {
  final byName = <String, List<({String path, int line})>>{};
  for (final MapEntry(key: path, value: content) in files.entries) {
    if (_isGenerated(path) || _typesExempt.contains(path)) continue;
    for (final declaration in _publicDeclarations(content)) {
      (byName[declaration.name] ??= []).add((
        path: path,
        line: declaration.line,
      ));
    }
  }
  return [
    for (final MapEntry(key: name, value: places) in byName.entries)
      if (places.length > 1)
        for (final place in places)
          Violation(
            place.path,
            place.line,
            '$name is declared in ${places.length} files: every public type '
            'and extension name is unique in lib/ ($_typesDocs)',
          ),
  ];
}

/// A use case implements one base class with a record parameter.
List<Violation> _checkUseCase(String path, String content) {
  final segments = _libSegments(path)!;
  final isUseCase =
      segments.first == 'domain' &&
      segments.length == 4 &&
      segments[1] == 'use_case';
  if (!isUseCase) return const [];
  final code = [
    for (final line in content.split('\n'))
      line.trimLeft().startsWith('//') ? '' : line,
  ].join('\n');
  final match = _useCaseBase.firstMatch(code);
  final parameter = match == null ? null : _lastTypeArgument(code, match.end);
  if (parameter != null && parameter.startsWith('(')) return const [];
  return [
    Violation(
      path,
      1,
      'a use case implements UseCase or StreamUseCase with a record (or ()) '
      'as its parameter type ($_useCaseDocs)',
    ),
  ];
}

/// A port or base class in its folder of `domain` or `data/_shared/base` is an
/// `abstract interface class`.
List<Violation> _checkPorts(String path, List<String> lines) {
  final segments = _libSegments(path)!;
  final inPortFolder = _portFolders.any(
    (folder) =>
        segments.length > folder.length &&
        [for (var i = 0; i < folder.length; i++) segments[i] == folder[i]]
            .every((same) => same),
  );
  if (!inPortFolder) return const [];
  return [
    for (var i = 0; i < lines.length; i++)
      if (_plainAbstractClass.firstMatch(lines[i]) case final match?)
        Violation(
          path,
          i + 1,
          '${match[1]} is a contract: declare it as an abstract interface class '
          '(doc/spec/architecture.md, Principles)',
        ),
  ];
}

/// Every method of a repository contract returns Result or Stream.
List<Violation> _checkContract(String path, List<String> lines) {
  final segments = _libSegments(path)!;
  if (segments.first != 'domain' || segments[1] != 'repository') {
    return const [];
  }
  final violations = <Violation>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('//')) continue;
    final returnType = _contractMember.firstMatch(lines[i])?.group(1)?.trim();
    if (returnType == null || _contractReturn.hasMatch(returnType)) continue;
    violations.add(
      Violation(
        path,
        i + 1,
        'a repository contract method returns Future<Result<T>> or Stream<T>, '
        'not $returnType (doc/spec/architecture.md, Result and failure)',
      ),
    );
  }
  return violations;
}

/// The last top-level type argument of the list whose `<` ends at [start].
String? _lastTypeArgument(String code, int start) {
  var depth = 1;
  var argumentStart = start;
  for (var i = start; i < code.length; i++) {
    final char = code[i];
    if ('<({'.contains(char)) depth++;
    if ('>)}'.contains(char)) depth--;
    if (depth == 1 && char == ',') argumentStart = i + 1;
    if (depth == 0) return code.substring(argumentStart, i).trim();
  }
  return null;
}

List<({String kind, String name, String header, int line})> _publicDeclarations(
  String content,
) {
  final code = [
    for (final line in content.split('\n'))
      line.trimLeft().startsWith('//') ? '' : line,
  ].join('\n');
  return [
    for (final match in _typeDeclaration.allMatches(code))
      if (!match[2]!.startsWith('_') && match[2] != 'on')
        (
          kind: match[1]!,
          name: match[2]!,
          header: code.substring(match.start, _headerEnd(code, match.end)),
          line: '\n'.allMatches(code.substring(0, match.start)).length + 1,
        ),
  ];
}

int _headerEnd(String code, int start) {
  final brace = code.indexOf('{', start);
  final semicolon = code.indexOf(';', start);
  final ends = [brace, semicolon].where((index) => index >= 0);
  return ends.isEmpty ? code.length : ends.reduce((a, b) => a < b ? a : b);
}

/// Generated by build_runner, gen-l10n or flutterfire (`lib/app/config/firebase/`).
bool _isGenerated(String path) =>
    _generatedSuffixes.any(path.endsWith) ||
    path.startsWith('lib/l10n/gen/') ||
    path.startsWith('lib/app/config/firebase/');

/// The file name of the source that a generated file belongs to.
String _sourceName(String fileName) {
  for (final suffix in _generatedSuffixes) {
    if (fileName.endsWith(suffix)) {
      return '${fileName.substring(0, fileName.length - suffix.length)}.dart';
    }
  }
  return fileName;
}

String _pascalCase(String fileName) => fileName
    .substring(0, fileName.length - '.dart'.length)
    .split('_')
    .map(
      (part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
    )
    .join();

/// No Cubit, a `transformer:` on every `on<E>(...)` call, and in Bloc files no
/// manual subscription. Line comments are skipped.
List<Violation> _checkStateHolders(String path, List<String> lines) {
  final code = [
    for (final line in lines) line.trimLeft().startsWith('//') ? '' : line,
  ].join('\n');
  int lineAt(int offset) =>
      '\n'.allMatches(code.substring(0, offset)).length + 1;

  final violations = <Violation>[
    for (final match in _cubitClass.allMatches(code))
      Violation(
        path,
        lineAt(match.start),
        'Cubit is not used: state holders are Blocs ($_stateDocs)',
      ),
  ];
  for (final match in _eventHandler.allMatches(code)) {
    if (_passesTransformer(code, match.end)) continue;
    violations.add(
      Violation(
        path,
        lineAt(match.start),
        'every on<E> handler passes a transformer: ($_stateDocs)',
      ),
    );
  }
  if (path.endsWith('_bloc.dart')) {
    for (final match in _manualSubscription.allMatches(code)) {
      violations.add(
        Violation(
          path,
          lineAt(match.start),
          'Blocs follow streams with emit.forEach or emit.onEach, not '
          '${match[0]} ($_stateDocs)',
        ),
      );
    }
  }
  return violations;
}

/// Whether the `on<...>(...)` call whose type arguments start at [start] has a
/// `transformer:` argument of its own, not one nested in another call.
bool _passesTransformer(String code, int start) {
  var depth = 1;
  var i = start;
  for (; i < code.length && depth > 0; i++) {
    if (code[i] == '<') depth++;
    if (code[i] == '>') depth--;
  }
  while (i < code.length && code[i].trim().isEmpty) {
    i++;
  }
  if (i >= code.length || code[i] != '(') return false;
  depth = 0;
  for (; i < code.length; i++) {
    final char = code[i];
    if ('([{'.contains(char)) depth++;
    if (')]}'.contains(char) && --depth == 0) return false;
    if (depth == 1 &&
        code.startsWith('transformer:', i) &&
        !RegExp(r'\w').hasMatch(code[i - 1])) {
      return true;
    }
  }
  return false;
}
