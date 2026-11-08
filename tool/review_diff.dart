// Gives the change-reviewer agent (.claude/agents/change-reviewer.md) read
// access to git without ever printing a never-read file (global CLAUDE.md,
// section 5; project CLAUDE.md, Working rules). Permission rules match only
// the start of a command, so allowing `git diff*` or `git log*` would also
// allow `git log -p` or a diff without paths. This tool builds every git
// command itself: no flag from the caller ever reaches git, git runs without
// a shell, and diffs name each safe file explicitly after `--`.
//
// Usage: fvm dart run tool/review_diff.dart <mode> ...
//   files [<base>] [<head>]              `base: <commit>` used, then changed
//                                        file names; without <head>, the
//                                        working tree plus untracked files
//   diff [<base>] [<head>] [-- <paths>]  diff of the given files or folders,
//                                        or of all changed files
//   log [<base>] [<head>]                commits in <base>..<head or HEAD>
//   show <commit> <path>                 the file at that commit
//   search <text> [<commit>] [-- <paths>]
//                                        `path:line:content` of every line
//                                        containing <text> (fixed string,
//                                        any case, binary files skipped) in
//                                        the working tree (tracked and
//                                        untracked, not ignored) or at
//                                        <commit>; the reviewer's only way to
//                                        search, since `grep` would print
//                                        never-read files
//
// <base> defaults to `git merge-base HEAD develop`. Never-read files (see
// [isNeverRead]) are dropped and listed as `skipped (never read): <path>`;
// `show` refuses them, and `search` never searches them. Exit codes: 0 done
// (also when `search` finds nothing), 1 git failed or `show` refused, 2 usage
// error.
import 'dart:convert';
import 'dart:io';

const usage = '''
Usage: fvm dart run tool/review_diff.dart <mode> ...
  files [<base>] [<head>]
  diff [<base>] [<head>] [-- <paths>]
  log [<base>] [<head>]
  show <commit> <path>
  search <text> [<commit>] [-- <paths>]
<base> defaults to `git merge-base HEAD develop`; without <head>, files and
diff use the working tree, and without <commit>, search does. Flags are not
accepted.
''';

const _defaultBranch = 'develop';

/// Refs: branch and tag names, commit hashes, `HEAD~2`, `main^`.
final _ref = RegExp(r'^[A-Za-z0-9._/~^-]+$');

/// Never-read file names, matched anywhere in the repository, ignoring case.
const _secretNames = {
  'google-services.json',
  'googleservice-info.plist',
  'key.properties',
};

/// Never-read extensions: keystores, certificates, provisioning profiles,
/// App Store Connect and APNs keys.
const _secretExtensions = [
  '.jks',
  '.keystore',
  '.p12',
  '.pfx',
  '.p8',
  '.pem',
  '.mobileprovision',
];

/// SSH private and public key names outside `.ssh/`: `id_rsa`, `id_ecdsa`,
/// `id_ed25519`, with an optional `_<suffix>` and `.pub`.
final _sshKeyName = RegExp(r'^id_(rsa|ecdsa|ed25519)(_[^.]*)?(\.pub)?$');

/// Whether [path] is never read, printed or diffed. Matches, by file name
/// anywhere in the repository and ignoring case: `google-services.json`,
/// `GoogleService-Info.plist`, `firebase_options*.dart` (the generated
/// Firebase options in lib/app/firebase/), `.env*`, `key.properties`, `*.jks`,
/// `*.keystore`, `*.p12`, `*.pfx`, `*.p8`, `*.pem`, `*.mobileprovision`,
/// `*service-account*.json`, SSH key names (`id_rsa*`, `id_ecdsa*`,
/// `id_ed25519*`); and any path inside a `.ssh/` folder. Empty and `.`
/// segments are ignored, so a trailing `/` or `/.` cannot hide the name.
bool isNeverRead(String path) {
  final segments = path
      .replaceAll(r'\', '/')
      .toLowerCase()
      .split('/')
      .where((segment) => segment.isNotEmpty && segment != '.')
      .toList();
  final name = segments.isEmpty ? '' : segments.last;
  return segments.contains('.ssh') ||
      _secretNames.contains(name) ||
      name.startsWith('.env') ||
      (name.startsWith('firebase_options') && name.endsWith('.dart')) ||
      (name.contains('service-account') && name.endsWith('.json')) ||
      _secretExtensions.any(name.endsWith) ||
      _sshKeyName.hasMatch(name);
}

enum Mode { files, diff, log, show, search }

/// A validated command line. For [Mode.show], [refs] holds the commit and
/// [paths] the path. For [Mode.search], [text] holds the text to find and
/// [refs] the optional commit.
class Request {
  const Request(this.mode, this.refs, this.paths, {this.text = ''});

  final Mode mode;
  final List<String> refs;
  final List<String> paths;
  final String text;
}

class UsageException implements Exception {
  const UsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses and validates [args]; throws [UsageException] for anything else.
Request parseArgs(List<String> args) {
  if (args.isEmpty) throw const UsageException('missing mode');
  final mode = Mode.values.asNameMap()[args.first];
  if (mode == null) throw UsageException('unknown mode: ${args.first}');

  final rest = args.sublist(1);
  final separator = rest.indexOf('--');
  final positional = separator == -1 ? rest : rest.sublist(0, separator);
  final paths = separator == -1 ? <String>[] : rest.sublist(separator + 1);
  if (separator != -1 && mode != Mode.diff && mode != Mode.search) {
    throw const UsageException('`--` is accepted only by diff and search');
  }
  if (separator != -1 && paths.isEmpty) {
    throw const UsageException('no paths after `--`');
  }
  paths.forEach(_checkPath);

  if (mode == Mode.show) {
    if (positional.length != 2) {
      throw const UsageException('show takes <commit> <path>');
    }
    _checkRef(positional[0]);
    _checkPath(positional[1]);
    return Request(mode, [positional[0]], [positional[1]]);
  }
  if (mode == Mode.search) {
    if (positional.isEmpty || positional.length > 2) {
      throw const UsageException('search takes <text> [<commit>]');
    }
    final text = positional.first;
    if (text.isEmpty) throw const UsageException('empty search text');
    if (text.startsWith('-')) {
      throw UsageException('flags are not accepted: $text');
    }
    final refs = positional.sublist(1)..forEach(_checkRef);
    return Request(mode, refs, paths, text: text);
  }
  positional.forEach(_checkRef);
  if (positional.length > 2) {
    throw UsageException('too many arguments: ${positional.join(' ')}');
  }
  return Request(mode, positional, paths);
}

void _checkRef(String ref) {
  if (ref.startsWith('-')) throw UsageException('flags are not accepted: $ref');
  if (!_ref.hasMatch(ref)) throw UsageException('invalid ref: $ref');
}

void _checkPath(String path) {
  if (path.isEmpty) throw const UsageException('empty path');
  if (path.startsWith('-')) {
    throw UsageException('flags are not accepted: $path');
  }
}

/// Runs git with an argument list and returns its stdout. With [noMatchOk],
/// exit code 1 (`git grep` found nothing) returns an empty string.
typedef Git = String Function(List<String> args, {bool noMatchOk});

class GitException implements Exception {
  const GitException(this.message);

  final String message;
}

Git _processGit(String? workingDirectory) => (args, {noMatchOk = false}) {
  final result = Process.runSync(
    'git',
    args,
    workingDirectory: workingDirectory,
    stdoutEncoding: const Utf8Codec(allowMalformed: true),
    stderrEncoding: const Utf8Codec(allowMalformed: true),
  );
  if (noMatchOk && result.exitCode == 1) return '';
  if (result.exitCode != 0) {
    throw GitException(
      'git ${args.first}: ${(result.stderr as String).trim()}',
    );
  }
  return result.stdout as String;
};

/// Writes the result of [args] to [out] and returns the exit code. Git runs
/// in [workingDirectory] (default: the current directory). [batchChars]
/// exists for tests of the `search` batches.
int run(
  List<String> args,
  StringSink out, {
  String? workingDirectory,
  int batchChars = searchBatchChars,
}) {
  final Request request;
  try {
    request = parseArgs(args);
  } on UsageException catch (error) {
    out
      ..writeln('error: ${error.message}')
      ..write(usage);
    return 2;
  }
  try {
    final git = _processGit(workingDirectory);
    return request.mode == Mode.search
        ? _search(request, git, out, batchChars: batchChars)
        : _execute(request, git, out);
  } on GitException catch (error) {
    out.writeln('error: ${error.message}');
    return 1;
  } on ProcessException catch (error) {
    out.writeln('error: could not run git: ${error.message}');
    return 1;
  }
}

void main(List<String> args) {
  exitCode = run(args, stdout);
}

int _execute(Request request, Git git, StringSink out) {
  if (request.mode == Mode.show) {
    final path = request.paths.single;
    if (isNeverRead(path)) {
      out.writeln('refused (never read): $path');
      return 1;
    }
    out.write(
      git([
        'show',
        '--no-textconv',
        '--no-color',
        '${request.refs.single}:$path',
      ]),
    );
    return 0;
  }

  final base = request.refs.isNotEmpty
      ? request.refs.first
      : git(['merge-base', 'HEAD', _defaultBranch]).trim();
  final head = request.refs.length > 1 ? request.refs[1] : null;

  if (request.mode == Mode.log) {
    out.write(
      git([
        'log',
        '--oneline',
        '--no-decorate',
        '--no-color',
        '--no-patch',
        '$base..${head ?? 'HEAD'}',
        '--',
      ]),
    );
    return 0;
  }

  final tracked = _split(
    git(['diff', '--name-only', '--no-renames', '-z', base, ?head, '--']),
  );
  final untracked = head == null
      ? _split(git(['ls-files', '--others', '--exclude-standard', '-z']))
      : <String>[];
  var selected = {...tracked, ...untracked}.toList()..sort();

  if (request.mode == Mode.files) {
    out.writeln('base: $base');
    for (final path in selected.where((path) => !isNeverRead(path))) {
      out.writeln(path);
    }
    _writeSkipped(selected, out);
    return 0;
  }

  if (request.paths.isNotEmpty) {
    for (final path in request.paths) {
      if (!selected.any((file) => _covers(path, file))) {
        out.writeln('not changed: $path');
      }
    }
    selected = [
      for (final file in selected)
        if (request.paths.any((path) => _covers(path, file))) file,
    ];
  }
  final safe = selected.where((path) => !isNeverRead(path));
  final safeTracked = [...safe.where(tracked.contains)];
  if (safeTracked.isNotEmpty) {
    out.write(
      git([
        '--literal-pathspecs',
        'diff',
        '--no-ext-diff',
        '--no-textconv',
        '--no-color',
        '--no-renames',
        base,
        ?head,
        '--',
        ...safeTracked,
      ]),
    );
  }
  for (final path in safe.where(untracked.contains)) {
    out.writeln('untracked, no diff (read the file): $path');
  }
  _writeSkipped(selected, out);
  return 0;
}

/// Total length of the file paths passed to one `git grep` call, well below
/// the smallest command line limit (32767 characters on Windows), with room
/// for the other arguments and the quotes Windows adds around paths with
/// spaces.
const searchBatchChars = 28000;

/// Searches only the files that are not never-read, each named explicitly
/// after `--`, so git never opens a never-read file. The files go to git in
/// batches of at most [batchChars] characters of paths.
int _search(
  Request request,
  Git git,
  StringSink out, {
  int batchChars = searchBatchChars,
}) {
  final commit = request.refs.isEmpty ? null : request.refs.single;
  final files = _split(
    commit == null
        ? git(['ls-files', '-z', '--cached', '--others', '--exclude-standard'])
        : git(['ls-tree', '-r', '-z', '--name-only', commit]),
  ).toSet();
  final inScope = [
    for (final file in files)
      if (request.paths.isEmpty ||
          request.paths.any((path) => _covers(path, file)))
        file,
  ]..sort();
  final safe = inScope.where((path) => !isNeverRead(path)).toList();
  final matches = StringBuffer();
  for (final batch in _batches(safe, batchChars)) {
    matches.write(
      git([
        '--literal-pathspecs',
        'grep',
        '--no-color',
        '--no-textconv',
        '-n',
        '-I',
        '-i',
        '-F',
        '-e',
        request.text,
        commit ?? '--untracked',
        '--',
        ...batch,
      ], noMatchOk: true),
    );
  }
  if (matches.isEmpty) {
    out.writeln('no matches');
  } else {
    // At a commit, git prefixes every line with `<commit>:`.
    final prefix = commit == null ? '' : '$commit:';
    for (final line in const LineSplitter().convert(matches.toString())) {
      out.writeln(
        line.startsWith(prefix) ? line.substring(prefix.length) : line,
      );
    }
  }
  _writeSkipped(inScope, out);
  return 0;
}

/// Splits [paths] into consecutive batches whose path lengths add up to at
/// most [maxChars]; a longer single path gets a batch of its own.
List<List<String>> _batches(List<String> paths, int maxChars) {
  final batches = <List<String>>[];
  var current = <String>[];
  var length = 0;
  for (final path in paths) {
    if (current.isNotEmpty && length + path.length + 1 > maxChars) {
      batches.add(current);
      current = [];
      length = 0;
    }
    current.add(path);
    length += path.length + 1;
  }
  if (current.isNotEmpty) batches.add(current);
  return batches;
}

void _writeSkipped(List<String> paths, StringSink out) {
  for (final path in paths.where(isNeverRead)) {
    out.writeln('skipped (never read): $path');
  }
}

List<String> _split(String output) =>
    output.split('\x00').where((path) => path.isNotEmpty).toList();

/// Whether the file or folder [path] given by the caller covers [file].
bool _covers(String path, String file) {
  var normalized = path.replaceAll(r'\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized.isEmpty ||
      normalized == '.' ||
      file == normalized ||
      file.startsWith('$normalized/');
}
