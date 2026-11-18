// Checks the spec conventions from doc/workflow.md (Requirements, Screens,
// Links). Every violation starts with the name of its rule:
// - format: a requirement is `- **<PREFIX>-<n>** <sentence>`, n is 1 or more
//   without leading zeros;
// - prefix: one prefix per behavior file, no prefix in two files, SCR is
//   reserved for screens;
// - scenario: every requirement has a nested `WHEN … THEN …` item;
// - screen: a screen is `### SCR-<n> <title>` with a `Design:` line;
// - duplicate: no ID is defined twice;
// - retired: each behavior file ends with one `Retired:` line (`none`, or IDs
//   of its prefix, SCR, or a prefix that no behavior file uses any more), and a
//   retired ID is not defined;
// - gap: per prefix and for SCR, defined plus retired IDs are exactly 1..max,
//   so a removed requirement cannot free its number;
// - removed (only with --base): every ID defined in the base revision is
//   still defined or retired, and every ID retired there is still retired,
//   so removing the highest ID cannot free its number either; a prefix that
//   no behavior file uses any more is skipped;
// - reference: every ID mention names a defined ID; a retired ID appears only
//   on a Retired line;
// - test name: a test name that starts with an ID has the form
//   `<ID>: <behavior>` or `<ID>, <ID>: <behavior>`;
// - coverage: every requirement (not SCR) starts a test or group name in
//   test/ (alone or in an ID list), or is on the Manual line of its file;
// - manual: at most one `Manual: <IDs>` line per behavior file, right before
//   the Retired line, with defined IDs of its prefix, each listed once and
//   without a test named by it;
// - decision: every `.md` in doc/decision/ is `_template.md` or
//   `ADR-<nnn>-<slug>.md` directly in it; its first line is
//   `# <ID>: <text>` with the ID of its file name; no ID is in two files;
// - link: relative Markdown links point to an existing file and heading;
// - toolchain (a warning: it never changes the exit code): the Flutter and
//   Dart rows of the Verified toolchain table in doc/spec/tech-stack.md name
//   the versions of the Flutter SDK this check runs on. `.fvmrc` tracks
//   `stable`, so a new release must show up without failing every run.
//
// Prefixes are read from doc/spec/behavior, so nothing here names an area.
// Limitation: once no behavior file uses a prefix, mentions of it are not
// recognized (doc/guide/new-project.md, Replace the spec).
// Add new rules here with a unit test.
//
// Usage: fvm dart run tool/check_spec.dart [--base <rev>]
// With --base, the behavior files of <rev> are read through git (only
// doc/spec/behavior/*.md). Exit codes: 0 clean, 1 violations, 2 usage or
// git error. Warnings are printed as `warning: ...`, or as GitHub annotations
// when GITHUB_ACTIONS is `true`.
import 'dart:convert';
import 'dart:io';

import 'review_diff.dart' show isNeverRead;

const _behaviorDir = 'doc/spec/behavior/';
const _screenPrefix = 'SCR';
const _decisionDir = 'doc/decision/';
const _decisionTemplate = 'doc/decision/_template.md';
const _techStackPath = 'doc/spec/tech-stack.md';
const _toolchainHeading = 'Verified toolchain';

/// These files contain made-up IDs on purpose.
const _ownFiles = {'tool/check_spec.dart', 'test/tool/check_spec_test.dart'};
const _dartDirs = ['lib/', 'test/', 'tool/'];
const _generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.config.dart',
  '.mocks.dart',
];
const _generatedDirs = ['lib/l10n/gen/'];

final _requirement = RegExp(r'^- \*\*([A-Z]+)-(\d+)\*\* \S');

/// A list item whose bold text starts like an ID (`**FAV2**`, `**fav-2**`,
/// `**FAV-2**` without a sentence). Other bold items, such as dialogs, pass.
final _idLikeItem = RegExp(r'^- \*\*[A-Za-z]+-?\d');
final _screen = RegExp(r'^### SCR-(\d+) \S');
final _screenHeading = RegExp(r'^#+ +SCR-');
final _heading = RegExp(r'^#{1,6} +(.*?)(?: +#+)? *$');
final _anyHeading = RegExp(r'^#{1,6} ');
final _retiredLine = RegExp(r'^Retired:');
final _retiredValue = RegExp(r'^Retired: (\S.*)$');
final _manualLine = RegExp(r'^Manual:');
final _manualValue = RegExp(r'^Manual: (\S.*)$');
final _idToken = RegExp(r'^([A-Z]+)-([1-9]\d*)$');
final _scenarioItem = RegExp(r'^  - (.*)$');
final _continuation = RegExp(r'^    \S');
final _designLine = RegExp(r'^(?:- )?Design: \S');
final _when = RegExp(r'\bWHEN\b');
final _then = RegExp(r'\bTHEN\b');
final _fence = RegExp(r'^ *(?:```|~~~)');
final _inlineCode = RegExp(r'`[^`]*`');

/// `ADR-001-<slug>.md` in `doc/decision/`; the number has three digits and is
/// not 000. Group 1 is the ID.
final _projectDecision = RegExp(
  r'^doc/decision/(ADR-(?!000)\d{3})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$',
);
final _link = RegExp(r'\[[^\]]*\]\(([^)\s]+)(?: +"[^"]*")?\)');

/// Also splits CRLF files, as a Windows checkout may have them.
final _newline = RegExp(r'\r?\n');
final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');
final _headingLink = RegExp(r'\[([^\]]*)\]\([^)]*\)');
final _slugDrop = RegExp(r'[^\p{L}\p{N}\p{M}\- _]', unicode: true);
final _headingNumber = RegExp(r'^\d+\. +');
final _hashes = RegExp(r'^#+');

/// A row of the Verified toolchain table that the toolchain rule compares.
final _toolchainRow = RegExp(r'^\| *(Flutter|Dart) *\| *([^|]*?) *\|');

/// The Flutter and Dart versions of a Flutter SDK.
typedef SdkVersions = ({String flutter, String dart});

class Violation {
  const Violation(this.path, this.line, this.rule);

  final String path;
  final int line;
  final String rule;

  @override
  String toString() => '$path:$line: $rule';
}

/// Whether the project scan reads the file at [path] (relative to the root).
/// Never-read files (`isNeverRead` in tool/review_diff.dart) are never read.
bool isChecked(String path) {
  if (isNeverRead(path)) return false;
  if (path == 'README.md' || path == 'CLAUDE.md') return true;
  if (path.startsWith('doc/')) {
    return path.endsWith('.md') && !path.startsWith('doc/change/');
  }
  if (!path.endsWith('.dart') || !_dartDirs.any(path.startsWith)) return false;
  if (_ownFiles.contains(path)) return false;
  return !_generatedSuffixes.any(path.endsWith) &&
      !_generatedDirs.any(path.startsWith);
}

/// A git command failed, or the base revision is not usable.
class GitException implements Exception {
  const GitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Checks [files] (path to content) as one project. [exists] and [read]
/// resolve link targets that are not in [files]; by default only [files] and
/// their folders exist. With [baseFiles] (the files of a base revision named
/// [baseName]), the removed rule also runs.
List<Violation> checkFiles(
  Map<String, String> files, {
  bool Function(String path)? exists,
  String? Function(String path)? read,
  Map<String, String>? baseFiles,
  String baseName = 'the base',
}) {
  exists ??= (path) =>
      path.isEmpty ||
      files.containsKey(path) ||
      files.keys.any((key) => key.startsWith('$path/'));
  read ??= (path) => files[path];

  final violations = <Violation>[];
  final behaviors = _parseBehaviors(files, violations);
  final spec = _checkIds(behaviors, violations);
  final tested = _testedIds(files, spec);
  _checkManual(behaviors, spec, tested, violations);
  _checkCoverage(behaviors, tested, violations);
  _checkDecisions(files, violations);
  if (baseFiles != null) {
    // Only the IDs of the base matter; its own violations are not reported.
    final base = _parseBehaviors(baseFiles, []);
    _checkRemoved(base, behaviors, spec, baseName, violations);
  }

  for (final MapEntry(key: path, value: content) in files.entries) {
    _checkReferences(path, content, spec, violations);
    if (path.endsWith('.md')) {
      _checkLinks(path, content, exists, read, violations);
    }
  }

  return violations..sort(
    (a, b) =>
        a.path == b.path ? a.line.compareTo(b.line) : a.path.compareTo(b.path),
  );
}

/// Checks the docs, README.md, CLAUDE.md and Dart code in [root]; with
/// [revision], also against the behavior files of that git revision. Throws
/// [GitException] when the revision cannot be read.
List<Violation> checkProject(Directory root, {String? revision}) {
  final baseFiles = revision == null ? null : readBaseBehaviors(root, revision);
  final base = root.path;
  final files = <String, String>{};
  for (final path in ['README.md', 'CLAUDE.md']) {
    final file = File('$base/$path');
    if (file.existsSync()) files[path] = file.readAsStringSync();
  }
  for (final dir in ['doc', 'lib', 'test', 'tool']) {
    final directory = Directory('$base/$dir');
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.substring(base.length + 1);
      if (isChecked(path)) files[path] = entity.readAsStringSync();
    }
  }
  return checkFiles(
    files,
    baseFiles: baseFiles,
    baseName: revision ?? 'the base',
    exists: (path) =>
        FileSystemEntity.typeSync('$base/$path') !=
        FileSystemEntityType.notFound,
    read: (path) {
      if (isNeverRead(path)) return null;
      final file = File('$base/$path');
      return file.existsSync() ? file.readAsStringSync() : null;
    },
  );
}

/// Reads `doc/spec/behavior/*.md` as they are in the git revision [base] of
/// the repository at [root]. Throws [GitException].
Map<String, String> readBaseBehaviors(Directory root, String base) {
  if (base.isEmpty || base.startsWith('-')) {
    throw GitException('not a revision: "$base"');
  }
  String git(List<String> args) {
    final ProcessResult result;
    try {
      result = Process.runSync(
        'git',
        args,
        workingDirectory: root.path,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    } on ProcessException catch (error) {
      throw GitException('could not run git: ${error.message}');
    }
    if (result.exitCode != 0) {
      throw GitException(
        'git ${args.first}: ${(result.stderr as String).trim()}',
      );
    }
    return result.stdout as String;
  }

  final sha = git([
    'rev-parse',
    '--verify',
    '--end-of-options',
    '$base^{commit}',
  ]).trim();
  final paths = git(['ls-tree', '-z', '--name-only', sha, '--', _behaviorDir])
      .split('\x00')
      .where(_isBehaviorFile);
  return {
    for (final path in paths) path: git(['show', '$sha:$path']),
  };
}

/// The toolchain rule: compares the Flutter and Dart rows of the Verified
/// toolchain section in [techStack] (the content of doc/spec/tech-stack.md)
/// with [sdk], the SDK this check runs on, or null when it is unknown. The
/// result holds warnings, not violations.
List<Violation> checkToolchain(String techStack, SdkVersions? sdk) {
  final lines = techStack.split(_newline);
  final start = lines.indexWhere(_isToolchainHeading);
  if (start == -1) {
    return [
      const Violation(
        _techStackPath,
        1,
        'toolchain: no "$_toolchainHeading" section',
      ),
    ];
  }
  if (sdk == null) {
    return [
      Violation(
        _techStackPath,
        start + 1,
        'toolchain: the Flutter version of this run is unknown '
        '(no bin/cache/flutter.version.json next to its Dart SDK)',
      ),
    ];
  }

  // The section ends at the next heading of the same or a higher level, as in
  // doc/agent-reading.md.
  final level = _headingLevel(lines[start]);
  final rows = <String, ({int line, String version})>{};
  for (var i = start + 1; i < lines.length; i++) {
    if (_anyHeading.hasMatch(lines[i]) && _headingLevel(lines[i]) <= level) {
      break;
    }
    if (_toolchainRow.firstMatch(lines[i]) case final match?) {
      rows.putIfAbsent(match[1]!, () => (line: i + 1, version: match[2]!));
    }
  }
  final warnings = <Violation>[];
  for (final (tool, used) in [('Flutter', sdk.flutter), ('Dart', sdk.dart)]) {
    final row = rows[tool];
    if (row == null) {
      warnings.add(
        Violation(_techStackPath, start + 1, 'toolchain: no $tool row'),
      );
    } else if (row.version != used) {
      warnings.add(
        Violation(
          _techStackPath,
          row.line,
          'toolchain: the table lists $tool ${row.version}, this run uses '
          '$used: run the Verification on it and update the table',
        ),
      );
    }
  }
  return warnings;
}

/// The versions of the Flutter SDK whose Dart runs this check:
/// `<flutter>/bin/cache/dart-sdk/bin/dart` reads
/// `<flutter>/bin/cache/flutter.version.json`. [dartExecutable] defaults to
/// the running Dart. Returns null when the file is missing or malformed.
SdkVersions? readSdkVersions({String? dartExecutable}) {
  final dartBin = File(dartExecutable ?? Platform.resolvedExecutable).parent;
  final file = File('${dartBin.parent.parent.path}/flutter.version.json');
  try {
    final Object? json = jsonDecode(file.readAsStringSync());
    if (json case {
      'frameworkVersion': final String flutter,
      'dartSdkVersion': final String dart,
    }) {
      return (flutter: flutter, dart: dart);
    }
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
  return null;
}

/// Writes the report for [root] to [out] and returns the exit code.
/// [readSdk] gives the SDK versions for the toolchain rule; with
/// [githubActions], warnings are written as GitHub annotations.
int run(
  Directory root,
  StringSink out, {
  String? base,
  SdkVersions? Function() readSdk = readSdkVersions,
  bool githubActions = false,
}) {
  final List<Violation> violations;
  try {
    violations = checkProject(root, revision: base);
  } on GitException catch (error) {
    out.writeln('error: $error');
    return 2;
  }
  for (final warning in _toolchainWarnings(root, readSdk)) {
    out.writeln(
      githubActions
          ? '::warning file=${warning.path},line=${warning.line}::'
                '${_escapeAnnotation(warning.rule)}'
          : 'warning: $warning',
    );
  }
  if (violations.isEmpty) {
    out.writeln('No spec violations.');
    return 0;
  }
  violations.forEach(out.writeln);
  out.writeln('${violations.length} spec violation(s).');
  return 1;
}

void main(List<String> args) {
  if (args case [] || ['--base', _]) {
    exitCode = run(
      Directory.current,
      stdout,
      base: args.elementAtOrNull(1),
      githubActions: Platform.environment['GITHUB_ACTIONS'] == 'true',
    );
  } else {
    stderr.writeln('usage: dart run tool/check_spec.dart [--base <rev>]');
    exitCode = 2;
  }
}

List<Violation> _toolchainWarnings(
  Directory root,
  SdkVersions? Function() readSdk,
) {
  final file = File('${root.path}/$_techStackPath');
  // A project without the file has no table to compare.
  if (!file.existsSync()) return const [];
  return checkToolchain(file.readAsStringSync(), readSdk());
}

/// The number of `#` of a heading [line].
int _headingLevel(String line) =>
    line.length - line.replaceFirst(_hashes, '').length;

/// Escapes a GitHub workflow command message, so it stays one annotation.
String _escapeAnnotation(String message) => message
    .replaceAll('%', '%25')
    .replaceAll('\r', '%0D')
    .replaceAll('\n', '%0A');

bool _isToolchainHeading(String line) {
  final match = _heading.firstMatch(line);
  return match != null &&
      match[1]!.replaceFirst(_headingNumber, '') == _toolchainHeading;
}

class _Id {
  _Id(this.prefix, this.digits, this.path, this.line);

  final String prefix;
  final String digits;
  final String path;
  final int line;

  String get id => '$prefix-$digits';
  int get number => int.parse(digits);
  String get location => '$path:$line';
}

class _Behavior {
  _Behavior(this.path);

  final String path;
  final requirements = <_Id>[];
  final screens = <_Id>[];
  final retired = <_Id>[];

  /// IDs on the `Manual:` lines.
  final manual = <_Id>[];

  /// 1-based line of the last `Retired:` line, if any.
  int? retiredLine;

  /// Lines already reported as malformed definitions; the reference rule
  /// skips them so that one mistake gives one violation.
  final malformed = <int>{};
}

class _Spec {
  _Spec(this.defined, this.retired, this.prefixes, this.malformed);

  final Map<String, _Id> defined;
  final Set<String> retired;
  final Set<String> prefixes;

  /// `path:line` of malformed definitions.
  final Set<String> malformed;
}

List<_Behavior> _parseBehaviors(
  Map<String, String> files,
  List<Violation> out,
) => [
  for (final path in files.keys.toList()..sort())
    if (_isBehaviorFile(path)) _parseBehavior(path, files[path]!, out),
];

/// The removed rule: compares the behavior files of a base revision with the
/// current ones.
void _checkRemoved(
  List<_Behavior> base,
  List<_Behavior> behaviors,
  _Spec spec,
  String baseName,
  List<Violation> out,
) {
  Violation at(_Id id, String path, String rule) {
    final owner = id.prefix == _screenPrefix
        ? behaviors.where((behavior) => behavior.path == path).firstOrNull ??
              behaviors.firstOrNull
        : behaviors
              .where(
                (behavior) =>
                    behavior.requirements.firstOrNull?.prefix == id.prefix,
              )
              .firstOrNull;
    if (owner == null) return Violation(path, id.line, rule);
    return Violation(owner.path, owner.retiredLine ?? 1, rule);
  }

  final reported = <String>{};
  for (final behavior in base) {
    for (final id in [...behavior.requirements, ...behavior.screens]) {
      if (!_idToken.hasMatch(id.id) || !spec.prefixes.contains(id.prefix)) {
        continue;
      }
      if (spec.defined.containsKey(id.id) || spec.retired.contains(id.id)) {
        continue;
      }
      if (!reported.add(id.id)) continue;
      out.add(
        at(
          id,
          behavior.path,
          'removed: ${id.id} is defined in $baseName but neither defined nor '
          'retired; add it to the Retired line of its file',
        ),
      );
    }
    for (final id in behavior.retired) {
      if (!spec.prefixes.contains(id.prefix) || spec.retired.contains(id.id)) {
        continue;
      }
      if (!reported.add(id.id)) continue;
      out.add(
        at(
          id,
          behavior.path,
          'removed: ${id.id} is retired in $baseName; a retired ID stays on '
          'the Retired line and is never reused',
        ),
      );
    }
  }
}

bool _isBehaviorFile(String path) =>
    path.startsWith(_behaviorDir) &&
    path.endsWith('.md') &&
    !path.substring(_behaviorDir.length).contains('/');

_Behavior _parseBehavior(String path, String content, List<Violation> out) {
  final behavior = _Behavior(path);
  final lines = content.split(_newline);
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_fence.hasMatch(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    final requirement = _requirement.firstMatch(line);
    if (requirement != null) {
      final id = _Id(requirement[1]!, requirement[2]!, path, i + 1);
      _checkNumber(id, out);
      behavior.requirements.add(id);
      if (!_hasScenario(lines, i)) {
        out.add(
          Violation(
            path,
            i + 1,
            'scenario: ${id.id} needs a nested "WHEN … THEN …" item',
          ),
        );
      }
    } else if (_idLikeItem.hasMatch(line)) {
      behavior.malformed.add(i + 1);
      out.add(
        Violation(
          path,
          i + 1,
          'format: a requirement is "- **<PREFIX>-<n>** <sentence>"',
        ),
      );
    } else if (_screen.firstMatch(line) case final screen?) {
      final id = _Id(_screenPrefix, screen[1]!, path, i + 1);
      _checkNumber(id, out);
      behavior.screens.add(id);
      if (!_hasDesign(lines, i)) {
        out.add(
          Violation(path, i + 1, 'screen: ${id.id} needs a Design: line'),
        );
      }
    } else if (_screenHeading.hasMatch(line)) {
      behavior.malformed.add(i + 1);
      out.add(
        Violation(path, i + 1, 'screen: a screen is "### SCR-<n> <title>"'),
      );
    }
  }
  _parseRetired(behavior, lines, out);
  _parseManual(behavior, lines, out);
  return behavior;
}

void _checkNumber(_Id id, List<Violation> out) {
  if (_idToken.hasMatch(id.id)) return;
  out.add(
    Violation(
      id.path,
      id.line,
      'format: ${id.id}: the number is 1 or more, without leading zeros',
    ),
  );
}

bool _hasScenario(List<String> lines, int index) {
  final items = <String>[];
  for (var i = index + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    if (!line.startsWith(' ')) break;
    final item = _scenarioItem.firstMatch(line);
    if (item != null) {
      items.add(item[1]!);
    } else if (_continuation.hasMatch(line) && items.isNotEmpty) {
      items.last = '${items.last} ${line.trim()}';
    }
  }
  return items.any((text) {
    final when = _when.firstMatch(text);
    final then = _then.firstMatch(text);
    return when != null && then != null && when.start < then.start;
  });
}

bool _hasDesign(List<String> lines, int index) {
  for (var i = index + 1; i < lines.length; i++) {
    if (_anyHeading.hasMatch(lines[i])) return false;
    if (_designLine.hasMatch(lines[i].trim())) return true;
  }
  return false;
}

void _parseRetired(
  _Behavior behavior,
  List<String> lines,
  List<Violation> out,
) {
  final path = behavior.path;
  final retiredLines = [
    for (var i = 0; i < lines.length; i++)
      if (_retiredLine.hasMatch(lines[i])) i,
  ];
  final last = lines.lastIndexWhere((line) => line.trim().isNotEmpty);
  if (retiredLines.isEmpty) {
    out.add(
      Violation(
        path,
        last + 1,
        'retired: the file ends with "Retired: none" or "Retired: <IDs>"',
      ),
    );
    return;
  }
  for (final index in retiredLines.take(retiredLines.length - 1)) {
    out.add(Violation(path, index + 1, 'retired: one Retired line per file'));
  }
  final index = retiredLines.last;
  behavior.retiredLine = index + 1;
  if (index != last) {
    out.add(
      Violation(path, index + 1, 'retired: the Retired line is the last line'),
    );
  }

  final value = _retiredValue.firstMatch(lines[index])?[1]?.trim();
  if (value == null) {
    out.add(
      Violation(
        path,
        index + 1,
        'retired: "Retired: none" or "Retired: <IDs>"',
      ),
    );
    return;
  }
  if (value == 'none') return;
  for (final token in value.split(',').map((token) => token.trim())) {
    final match = _idToken.firstMatch(token);
    if (match == null) {
      out.add(Violation(path, index + 1, 'retired: "$token" is not an ID'));
      continue;
    }
    behavior.retired.add(_Id(match[1]!, match[2]!, path, index + 1));
  }
}

/// The parts of the manual rule that need only this file: count, position
/// and value of the `Manual:` lines. Runs after [_parseRetired].
void _parseManual(_Behavior behavior, List<String> lines, List<Violation> out) {
  final path = behavior.path;
  final manualLines = [
    for (var i = 0; i < lines.length; i++)
      if (_manualLine.hasMatch(lines[i])) i,
  ];
  for (final index in manualLines.skip(1)) {
    out.add(Violation(path, index + 1, 'manual: one Manual line per file'));
  }
  for (final index in manualLines) {
    final retiredLine = behavior.retiredLine;
    final next = lines.indexWhere((line) => line.trim().isNotEmpty, index + 1);
    if (retiredLine != null && next + 1 != retiredLine) {
      out.add(
        Violation(
          path,
          index + 1,
          'manual: the Manual line comes right before the Retired line',
        ),
      );
    }

    final value = _manualValue.firstMatch(lines[index])?[1]?.trim();
    if (value == null || value == 'none') {
      out.add(
        Violation(
          path,
          index + 1,
          'manual: "Manual: <IDs>"; omit the line when there are none',
        ),
      );
      continue;
    }
    for (final token in value.split(',').map((token) => token.trim())) {
      final match = _idToken.firstMatch(token);
      if (match == null) {
        out.add(Violation(path, index + 1, 'manual: "$token" is not an ID'));
        continue;
      }
      behavior.manual.add(_Id(match[1]!, match[2]!, path, index + 1));
    }
  }
}

/// The parts of the manual rule that need the whole spec and the tests.
void _checkManual(
  List<_Behavior> behaviors,
  _Spec spec,
  Map<String, String> tested,
  List<Violation> out,
) {
  for (final behavior in behaviors) {
    final prefix = behavior.requirements.firstOrNull?.prefix;
    final seen = <String>{};
    for (final id in behavior.manual) {
      final String problem;
      if (id.prefix != prefix) {
        problem = 'does not belong to this file';
      } else if (!seen.add(id.id)) {
        problem = 'is listed twice';
      } else if (spec.retired.contains(id.id)) {
        problem = 'is retired';
      } else if (!spec.defined.containsKey(id.id)) {
        problem = 'is not defined';
      } else if (tested[id.id] case final test?) {
        problem = 'has a test at $test; remove it from the Manual line';
      } else {
        continue;
      }
      out.add(Violation(id.path, id.line, 'manual: ${id.id} $problem'));
    }
  }
}

/// Rule coverage.
void _checkCoverage(
  List<_Behavior> behaviors,
  Map<String, String> tested,
  List<Violation> out,
) {
  final manual = {
    for (final behavior in behaviors)
      for (final id in behavior.manual) id.id,
  };
  for (final behavior in behaviors) {
    for (final id in behavior.requirements) {
      if (id.prefix == _screenPrefix || !_idToken.hasMatch(id.id)) continue;
      if (tested.containsKey(id.id) || manual.contains(id.id)) continue;
      out.add(
        Violation(
          id.path,
          id.line,
          'coverage: ${id.id} has no test named by it; add one '
          "('${id.id}: …') or put it on the Manual line",
        ),
      );
    }
  }
}

/// Rule decision: the layout of `doc/decision/`.
void _checkDecisions(Map<String, String> files, List<Violation> out) {
  final seen = <String, String>{};
  for (final path in files.keys.toList()..sort()) {
    if (!path.startsWith(_decisionDir) || !path.endsWith('.md')) continue;
    if (path == _decisionTemplate) continue;
    final id = _projectDecision.firstMatch(path)?[1];
    if (id == null) {
      out.add(
        Violation(
          path,
          1,
          'decision: unexpected file; expected `_template.md` or '
          '`ADR-<nnn>-<slug>.md` in doc/decision/, with <nnn> of '
          'three digits (not 000) and a lowercase kebab-case <slug>',
        ),
      );
      continue;
    }
    final heading = files[path]!.split(_newline).first;
    if (!heading.startsWith('# $id: ') ||
        heading.substring(id.length + 4).trim().isEmpty) {
      out.add(
        Violation(
          path,
          1,
          'decision: the first line must be `# $id: <decision in a few '
          'words>`',
        ),
      );
    }
    final first = seen.putIfAbsent(id, () => path);
    if (first != path) {
      out.add(Violation(path, 1, 'decision: $id is already used by $first'));
    }
  }
}

/// The IDs that start a string literal in a test file, alone or in an ID
/// list, each with the `path:line` of its first test.
Map<String, String> _testedIds(Map<String, String> files, _Spec spec) {
  final patterns = _IdPatterns(spec);
  final tested = <String, String>{};
  for (final path in files.keys.toList()..sort()) {
    if (!_isTestFile(path)) continue;
    final lines = files[path]!.split(_newline);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final match in patterns.testName.allMatches(line)) {
        final list = patterns.idList.matchAsPrefix(line, match.start + 1);
        if (list == null) continue;
        for (final id in patterns.mention.allMatches(list[0]!)) {
          tested.putIfAbsent(id[0]!, () => '$path:${i + 1}');
        }
      }
    }
  }
  return tested;
}

bool _isTestFile(String path) =>
    path.startsWith('test/') && path.endsWith('.dart');

/// Patterns for the IDs of the prefixes in the spec.
class _IdPatterns {
  _IdPatterns(_Spec spec) {
    final alternatives = spec.prefixes.join('|');
    mention = RegExp('\\b(?:$alternatives)-\\d+\\b');
    testName = RegExp('[\'"]((?:$alternatives)-\\d+)\\b');
    idList = RegExp('(?:$alternatives)-\\d+(?:, (?:$alternatives)-\\d+)*: ');
  }

  /// An ID anywhere in a line.
  late final RegExp mention;

  /// A string literal that starts with an ID.
  late final RegExp testName;

  /// The ID list at the start of a test name, with its `: `.
  late final RegExp idList;
}

/// Rules that need all behavior files: prefix, duplicate, retired, gap.
_Spec _checkIds(List<_Behavior> behaviors, List<Violation> out) {
  final owners = <String, String>{};
  final defined = <String, _Id>{};
  final retired = <String, _Id>{};
  // A Retired line may also hold IDs of a prefix that no file defines any
  // more: the old prefix of a renamed area.
  final currentPrefixes = {
    for (final behavior in behaviors)
      ?behavior.requirements.firstOrNull?.prefix,
  };

  for (final behavior in behaviors) {
    final prefix = behavior.requirements.firstOrNull?.prefix;
    for (final id in behavior.requirements) {
      if (id.prefix == _screenPrefix) {
        out.add(
          Violation(id.path, id.line, 'prefix: SCR is reserved for screens'),
        );
      } else if (id.prefix != prefix) {
        out.add(
          Violation(
            id.path,
            id.line,
            'prefix: this file uses $prefix; ${id.id} belongs in another file',
          ),
        );
      }
    }
    if (prefix != null && prefix != _screenPrefix) {
      final owner = owners[prefix];
      if (owner == null) {
        owners[prefix] = behavior.path;
      } else {
        final first = behavior.requirements.first;
        out.add(
          Violation(
            first.path,
            first.line,
            'prefix: $prefix is already used by $owner',
          ),
        );
      }
    }

    for (final id in [...behavior.requirements, ...behavior.screens]) {
      final previous = defined[id.id];
      if (previous == null) {
        defined[id.id] = id;
      } else {
        out.add(
          Violation(
            id.path,
            id.line,
            'duplicate: ${id.id} is already defined at ${previous.location}',
          ),
        );
      }
    }

    for (final id in behavior.retired) {
      if (id.prefix != prefix &&
          id.prefix != _screenPrefix &&
          currentPrefixes.contains(id.prefix)) {
        out.add(
          Violation(
            id.path,
            id.line,
            'retired: ${id.id} does not belong to this file',
          ),
        );
      }
      retired.putIfAbsent(id.id, () => id);
    }
  }

  for (final id in retired.values) {
    final definition = defined[id.id];
    if (definition == null) continue;
    out.add(
      Violation(
        id.path,
        id.line,
        'retired: ${id.id} is retired but defined at ${definition.location}',
      ),
    );
  }

  final byPrefix = <String, Map<int, _Id>>{};
  for (final id in [...defined.values, ...retired.values]) {
    if (!_idToken.hasMatch(id.id)) continue;
    (byPrefix[id.prefix] ??= {}).putIfAbsent(id.number, () => id);
  }
  for (final MapEntry(key: prefix, value: ids) in byPrefix.entries) {
    final numbers = ids.keys.toList()..sort();
    for (var n = 1; n < numbers.last; n++) {
      if (ids.containsKey(n)) continue;
      final next = ids[numbers.firstWhere((number) => number > n)]!;
      out.add(
        Violation(
          next.path,
          next.line,
          'gap: $prefix-$n is neither defined nor retired; a removed ID goes '
          'to the Retired line of its file',
        ),
      );
    }
  }

  return _Spec(
    defined,
    retired.keys.toSet(),
    {...owners.keys, for (final id in retired.values) id.prefix, _screenPrefix},
    {
      for (final behavior in behaviors)
        for (final line in behavior.malformed) '${behavior.path}:$line',
    },
  );
}

/// Rules reference and test name. The `test name` rule checks the same
/// literals that [_testedIds] reads.
void _checkReferences(
  String path,
  String content,
  _Spec spec,
  List<Violation> out,
) {
  final _IdPatterns(:mention, :testName, :idList) = _IdPatterns(spec);
  final isBehavior = _isBehaviorFile(path);
  final isTest = _isTestFile(path);

  final lines = content.split(_newline);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (spec.malformed.contains('$path:${i + 1}')) continue;
    // The manual rule reports the IDs of a Manual line.
    if (isBehavior && _manualLine.hasMatch(line)) continue;
    final onRetiredLine = isBehavior && _retiredLine.hasMatch(line);
    for (final match in mention.allMatches(line)) {
      final id = match[0]!;
      if (spec.defined.containsKey(id)) continue;
      if (spec.retired.contains(id)) {
        if (onRetiredLine) continue;
        out.add(Violation(path, i + 1, 'reference: $id is retired'));
      } else {
        out.add(
          Violation(
            path,
            i + 1,
            'reference: $id is not defined in doc/spec/behavior',
          ),
        );
      }
    }
    if (!isTest) continue;
    for (final match in testName.allMatches(line)) {
      if (line.startsWith(idList, match.start + 1)) continue;
      out.add(
        Violation(
          path,
          i + 1,
          'test name: "${match[1]}" must be followed by ": " and the behavior '
          "('FAV-2: guest sees no toggle'), or by more IDs "
          "('FAV-1, FAV-2: …')",
        ),
      );
    }
  }
}

/// Rule link.
void _checkLinks(
  String path,
  String content,
  bool Function(String path) exists,
  String? Function(String path) read,
  List<Violation> out,
) {
  final lines = content.split(_newline);
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_fence.hasMatch(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    for (final match in _link.allMatches(line.replaceAll(_inlineCode, ''))) {
      final target = match[1]!;
      if (_scheme.hasMatch(target)) continue;
      final hash = target.indexOf('#');
      final file = hash < 0 ? target : target.substring(0, hash);
      final anchor = hash < 0 ? '' : target.substring(hash + 1);

      final resolved = file.isEmpty ? path : _resolve(path, _decode(file));
      if (resolved == null || !exists(resolved)) {
        out.add(Violation(path, i + 1, 'link: $target does not exist'));
        continue;
      }
      if (anchor.isEmpty || !resolved.endsWith('.md')) continue;
      final targetContent = read(resolved);
      if (targetContent == null) continue;
      if (!_anchors(targetContent).contains(_decode(anchor).toLowerCase())) {
        out.add(
          Violation(path, i + 1, 'link: $resolved has no heading #$anchor'),
        );
      }
    }
  }
}

/// Resolves [target] against the folder of [from]; null when it leaves the
/// project.
String? _resolve(String from, String target) {
  final segments = target.startsWith('/')
      ? <String>[]
      : (from.split('/')..removeLast());
  for (final part in target.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (segments.isEmpty) return null;
      segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}

String _decode(String text) {
  try {
    return Uri.decodeComponent(text);
  } on FormatException {
    return text;
  }
}

/// GitHub heading anchors of a Markdown file.
Set<String> _anchors(String content) {
  final counts = <String, int>{};
  final anchors = <String>{};
  var inFence = false;
  for (final line in content.split(_newline)) {
    if (_fence.hasMatch(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final heading = _heading.firstMatch(line);
    if (heading == null) continue;
    final slug = heading[1]!
        .replaceAllMapped(_headingLink, (match) => match[1]!)
        .toLowerCase()
        .replaceAll(_slugDrop, '')
        .replaceAll(' ', '-');
    final count = counts[slug] ?? 0;
    anchors.add(count == 0 ? slug : '$slug-$count');
    counts[slug] = count + 1;
  }
  return anchors;
}
