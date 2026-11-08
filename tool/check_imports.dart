// Enforces the architecture rules from docs/spec/architecture.md, Import rules:
// - which modules and areas may import each other (_allowedModules);
// - which external packages each module may import: allow lists for shared,
//   domain and l10n (_allowedPackages); package ownership between data and
//   presentation (_sharedPackages, _knownOwners);
// - Flutter and dart: libraries where they do not belong;
// - the service locator only in app/;
// - where files live (reserved names, usecases folders, name suffixes).
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
  'domain': {'freezed_annotation', 'meta', 'collection'},
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
/// BLoC files never see a BuildContext.
const _dataFlutterLibraries = {'foundation.dart', 'services.dart'};
const _blocFlutterLibraries = {'foundation.dart'};
const _blocFileSuffixes = [
  '_bloc.dart',
  '_cubit.dart',
  '_state.dart',
  '_event.dart',
];

/// Package ownership (docs/spec/architecture.md, External packages). Every external package
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
  'presentation': {'flutter_bloc', 'bloc'},
};

const _ownershipDocs = 'docs/spec/architecture.md, External packages';

/// The service locator is used only in `app/`; everything else receives
/// dependencies through constructors. `injectable.dart` re-exports
/// `GetItHelper`, so imports alone cannot enforce this.
final _serviceLocator = RegExp(r'\b(?:getIt|GetIt|GetItHelper)\b');

/// The layer where files with these name suffixes live.
const _suffixLayers = {
  '_dto.dart': 'data',
  '_repository_impl.dart': 'data',
  '_use_case.dart': 'domain',
  '_bloc.dart': 'presentation',
  '_cubit.dart': 'presentation',
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
  if (_unrestrictedModules.contains(module)) return null;

  if (uri.startsWith('dart:')) {
    return (_forbiddenDartLibraries[module]?.contains(uri) ?? false)
        ? '$module must not import $uri'
        : null;
  }
  if (_isExternalPackage(uri)) {
    return _checkFlutterLibrary(path, module, uri) ??
        _checkPackage(module, uri);
  }

  final to = uri.startsWith(_ownPackage)
      ? uri.substring(_ownPackage.length).split('/')
      : _libSegments(Uri.parse(path).resolve(uri).path);
  if (to == null) return '$uri is outside lib/';
  return _checkInternal(from, to);
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
      segments.sublist(1, segments.length - 1).contains('usecases')) {
    return 'use cases live in domain/<area>/usecases, not in presentation';
  }
  for (final MapEntry(key: suffix, value: layer) in _suffixLayers.entries) {
    if (!path.endsWith(suffix)) continue;
    if (layer == 'domain') {
      final inUseCases =
          module == 'domain' &&
          segments.length > 3 &&
          segments[2] == 'usecases';
      return inUseCases
          ? null
          : '*$suffix files live in domain/<area>/usecases';
    }
    return module == layer ? null : '*$suffix files live in $layer';
  }
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

  if (_unrestrictedModules.contains(_libSegments(path)!.first)) {
    return violations;
  }
  final lines = content.split('\n');
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

  return violations..sort(
    (a, b) =>
        a.path == b.path ? a.line.compareTo(b.line) : a.path.compareTo(b.path),
  );
}

/// Checks every Dart file under `lib/` in [root], except never-read files
/// (`isNeverRead` in tool/review_diff.dart), which are never read.
List<Violation> checkProject(Directory root) {
  final prefixLength = root.path.length + 1;
  return checkFiles({
    for (final file in Directory('${root.path}/lib').listSync(recursive: true))
      if (file is File &&
          file.path.endsWith('.dart') &&
          !isNeverRead(file.path.substring(prefixLength)))
        file.path.substring(prefixLength): file.readAsStringSync(),
  });
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
    return 'BLoC files must not import $uri: they never use BuildContext or '
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

String? _checkInternal(List<String> from, List<String> to) {
  final module = from.first;
  final target = to.first;
  if (!_allowedModules[module]!.contains(target)) {
    return '$module must not import $target';
  }
  if (module != target || !_layers.contains(module)) return null;

  final fromArea = from[1];
  final toArea = to[1];
  if (toArea == '_shared' || toArea == fromArea) return null;
  if (module == 'domain' && fromArea != '_shared' && to.length > 2) {
    if (to[2] == 'entities') return null;
    final isUseCase = from.length > 2 && from[2] == 'usecases';
    if (isUseCase && to[2] == 'repositories') return null;
  }
  return '$module/$fromArea must not import $module/$toArea';
}
