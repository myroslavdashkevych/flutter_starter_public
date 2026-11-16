import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests for `.claude/hooks/review-bash.sh`, the Bash allowlist of the
/// change-reviewer agent. Exit 0 allows a command, exit 2 blocks it.
void main() {
  Future<(int, String)> run(
    String command, {
    String? agent = 'change-reviewer',
    String executable = 'bash',
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      ['.claude/hooks/review-bash.sh'],
      environment: environment,
      includeParentEnvironment: environment == null,
    );
    process.stdin.write(
      jsonEncode({
        'agent_type': ?agent,
        'tool_input': {'command': command},
      }),
    );
    await process.stdin.close();
    final stderr = await process.stderr.transform(utf8.decoder).join();
    return (await process.exitCode, stderr);
  }

  String search(String text) =>
      'fvm dart run tool/review_diff.dart search $text';

  group('change-reviewer', () {
    for (final command in [
      'fvm dart run tool/review_diff.dart files',
      'fvm dart run tool/review_diff.dart diff 5b18f59 HEAD -- doc lib/app',
      'fvm dart run tool/review_diff.dart show HEAD~1 assets/icon@2x.png',
      'fvm dart run tool/check_spec.dart',
      'fvm dart run tool/check_spec.dart --base develop',
      'fvm dart run tool/check_spec.dart --base 5b18f59',
      'fvm dart run tool/check_imports.dart',
      'fvm flutter test',
      'fvm flutter test test/tool test/data',
      'fvm flutter analyze',
      'fvm dart analyze tool test/tool',
      'fvm dart format --output=none --set-exit-if-changed tool/a.dart',
      'fvm dart run tool/review_diff.dart search "feature file"',
      'fvm dart run tool/review_diff.dart search "a b" HEAD -- doc lib',
      // Inside double quotes bash expands no tilde.
      'fvm dart run tool/review_diff.dart search "a-b ~/x"',
    ]) {
      test('allows $command', () async {
        expect((await run(command)).$1, 0);
      });
    }

    for (final (reason, command) in [
      ('git', 'git diff 5b18f59'),
      ('another command', 'cat CLAUDE.md'),
      ('bare flutter', 'flutter test'),
      ('another tool', 'fvm dart run tool/init_project.dart'),
      ('a test flag', 'fvm flutter test --update-goldens'),
      ('an analyze flag', 'fvm flutter analyze --write=out.txt'),
      ('a format flag', 'fvm dart format --output=none -o write lib'),
      ('format without --output=none', 'fvm dart format lib'),
      ('a checker flag', 'fvm dart run tool/check_spec.dart --fix'),
      ('--base without a ref', 'fvm dart run tool/check_spec.dart --base'),
      ('--base=', 'fvm dart run tool/check_spec.dart --base=develop'),
      ('--base with a dash ref', 'fvm dart run tool/check_spec.dart --base -'),
      ('--base with a flag', 'fvm dart run tool/check_spec.dart --base --fix'),
      ('--base twice', 'fvm dart run tool/check_spec.dart --base a --base b'),
      (
        '--base with an extra arg',
        'fvm dart run tool/check_spec.dart --base a b',
      ),
      ('a review_diff flag', 'fvm dart run tool/review_diff.dart diff -p'),
      ('an operator', 'fvm flutter test && git status'),
      ('a redirect', 'fvm flutter test > out.txt'),
      ('a substitution', r'fvm flutter test $(git log -p)'),
      ('a quote', "fvm flutter test 'a b'"),
      ('a line break', 'fvm flutter test\ngit status'),
      ('cd', 'cd lib && fvm flutter test'),
      ('a brace expansion', 'fvm dart format --output=none {-o,write} lib'),
      ('a glob', 'fvm flutter test test/*'),
      ('a tilde at a word start', 'fvm flutter test ~/x'),
      ('a tilde after =', 'fvm flutter test a=~/x'),
      ('an empty command', ''),
      (
        'a quoted search text outside search',
        'fvm dart run tool/review_diff.dart diff "a b"',
      ),
      ('two quoted search texts', search('"a b" "c d"')),
      ('a single-quoted search text', search("'a b'")),
      ('an empty search text', search('""')),
      ('an unclosed quote', search('"a b')),
      ('a search text that starts with a dash', search('"-a b"')),
      ('a substitution in a search text', search(r'"$(id)"')),
      ('a variable in a search text', search(r'"a $HOME"')),
      ('a backtick in a search text', search('"a `id`"')),
      ('a backslash in a search text', search(r'"a \" b"')),
      ('a history expansion in a search text', search('"a !1"')),
      ('a line break in a search text', search('"a\nb"')),
      ('a substitution after a search text', search(r'"a b" $(id)')),
      ('a tilde path after a search text', search('"a b" -- ~/x')),
      ('an operator after a search text', search('"a b"; git log -p')),
      ('a line break after a search text', search('"a b"\ngit log -p')),
      ('a tilde glued to a search text', search('"a b"~/x')),
      ('a quote after a search text', search('"a"b"c d"')),
      ('a variable after a search text', search(r'"a b" $HOME')),
    ]) {
      test('blocks $reason', () async {
        final (code, stderr) = await run(command);

        expect(code, 2);
        expect(stderr, startsWith('Blocked: '));
      });
    }

    test('blocks every command when jq is missing', () async {
      // Longer than a pipe buffer: a hook that exits with its input unread
      // always fails this write with a broken pipe.
      final (code, stderr) = await run(
        'fvm flutter test ${'a' * 100000}',
        executable: '/bin/bash',
        environment: {'PATH': '/nonexistent'},
      );

      expect(code, 2);
      expect(stderr, contains('jq is not installed'));
    });
  });

  group('other callers', () {
    test('a different agent passes untouched', () async {
      expect((await run('git log -p', agent: 'Explore')).$1, 0);
    });

    test('the main session (no agent_type) passes untouched', () async {
      expect((await run('git status', agent: null)).$1, 0);
    });
  });
}
