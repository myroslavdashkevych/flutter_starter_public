import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/review_diff.dart';

const _secret = 'FIXTURE-SECRET-CONTENT';

void main() {
  group('isNeverRead', () {
    for (final path in [
      'android/app/google-services.json',
      'android/app/src/dev/google-services.json',
      'google-services.json',
      'ios/config/dev/GoogleService-Info.plist',
      'lib/app/firebase/firebase_options_dev.dart',
      'lib/app/firebase/firebase_options.dart',
      '.env',
      '.env.example',
      'config/.env.prod',
      'android/key.properties',
      'android/app/upload.jks',
      'release.keystore',
      'ios/cert.p12',
      'ios/cert.pfx',
      'ios/AuthKey_ABC123.p8',
      'deploy/id_rsa',
      'deploy/id_rsa.pub',
      'ci/id_ed25519_deploy',
      'id_ecdsa',
      'certs/server.pem',
      'ios/profiles/App.mobileprovision',
      'keys/my-service-account.json',
      'service-account.json',
      '.ssh/id_ed25519',
      'home/.ssh/config',
      'ANDROID/APP/GOOGLE-SERVICES.JSON',
      r'android\app\google-services.json',
      'android/app/google-services.json/',
      'android/app/google-services.json//',
      'android/app/google-services.json/.',
      'android/app/google-services.json/./',
    ]) {
      test('matches $path', () => expect(isNeverRead(path), isTrue));
    }

    for (final path in [
      'lib/app/firebase/firebase_setup.dart',
      'lib/app/firebase/options.dart',
      'docs/google-services.md',
      'google-services.json.md',
      'lib/app/env/config.dart',
      'lib/environment.dart',
      'key.properties.example',
      'android/app/build.gradle.kts',
      'docs/keystore.md',
      'certs/pem_notes.txt',
      'lib/data/service_account.dart',
      'docs/service-account.md',
      'ssh/config',
      'docs/ssh.md',
      'docs/id_rsa.md',
      'lib/id_rsa_parser.dart',
      'docs/p8-keys.md',
      'lib/valid_id.dart',
      'config/dev.json',
      'pubspec.yaml',
    ]) {
      test('passes $path', () => expect(isNeverRead(path), isFalse));
    }
  });

  group('parseArgs', () {
    test('accepts every mode with its arguments', () {
      expect(parseArgs(['files']).refs, isEmpty);
      expect(parseArgs(['files', 'main', 'HEAD']).refs, ['main', 'HEAD']);
      expect(parseArgs(['log', 'develop']).mode, Mode.log);
      final diff = parseArgs(['diff', 'abc123', '--', 'lib', 'docs/a.md']);
      expect(diff.refs, ['abc123']);
      expect(diff.paths, ['lib', 'docs/a.md']);
      final show = parseArgs(['show', 'HEAD~2', 'lib/main.dart']);
      expect(show.refs, ['HEAD~2']);
      expect(show.paths, ['lib/main.dart']);
      final search = parseArgs(['search', 'ADR-015', 'HEAD', '--', 'docs']);
      expect(search.text, 'ADR-015');
      expect(search.refs, ['HEAD']);
      expect(search.paths, ['docs']);
      expect(parseArgs(['search', 'a.b']).refs, isEmpty);
    });

    test('show accepts a path that is not a valid ref', () {
      for (final path in [
        'assets/icon@2x.png',
        'docs/a b.md',
        'x/(y)+[z].txt',
      ]) {
        expect(parseArgs(['show', 'HEAD', path]).paths, [path]);
      }
    });

    test('accepts refs with slashes, dots, tilde and caret', () {
      for (final ref in ['feature/x', 'v1.2.0', 'HEAD~1', 'main^', 'a-b_c']) {
        expect(parseArgs(['log', ref]).refs, [ref]);
      }
    });

    for (final args in [
      <String>[],
      ['status'],
      ['diff', '-p'],
      ['diff', '--patch'],
      ['diff', '--stat'],
      ['diff', '--output=x'],
      ['diff', 'main', '--output=x'],
      ['diff', '--', '-p'],
      ['diff', '--', '--output=x'],
      ['diff', '--', 'a', '--', 'b'],
      ['diff', '--'],
      ['diff', '--', ''],
      ['diff', 'a', 'b', 'c'],
      ['log', '-p'],
      ['log', '--patch'],
      ['log', 'main', '--', 'lib'],
      ['files', '--stat'],
      ['files', 'main:google-services.json'],
      ['files', 'main@{1}'],
      ['files', 'a b'],
      ['files', r'$(touch x)'],
      ['show', 'HEAD'],
      ['show', 'HEAD', 'a', 'b'],
      ['show', '-p', 'a'],
      ['show', 'HEAD', '--output=x'],
      ['search'],
      ['search', ''],
      ['search', '-i'],
      ['search', '--output=x'],
      ['search', 'text', '--output=x'],
      ['search', 'text', 'a', 'b'],
      ['search', 'text', 'main:google-services.json'],
      ['search', 'text', '--'],
      ['search', 'text', '--', '-p'],
    ]) {
      test('rejects ${args.join(' ')}', () {
        expect(() => parseArgs(args), throwsA(isA<UsageException>()));
      });
    }
  });

  group('run', () {
    late Directory repo;

    void git(List<String> args) {
      final result = Process.runSync('git', [
        '-c',
        'user.name=Test',
        '-c',
        'user.email=test@example.com',
        '-c',
        'commit.gpgsign=false',
        '-c',
        'core.hooksPath=/dev/null',
        ...args,
      ], workingDirectory: repo.path);
      if (result.exitCode != 0) fail('git $args: ${result.stderr}');
    }

    void writeFile(String path, String content) {
      File('${repo.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    (int, String) review(List<String> args) {
      final out = StringBuffer();
      final code = run(args, out, workingDirectory: repo.path);
      return (code, out.toString());
    }

    setUp(() {
      repo = Directory.systemTemp.createTempSync('review_diff');
      git(['init', '-q']);
      writeFile('a.txt', 'one\n');
      writeFile('android/app/google-services.json', '$_secret 1\n');
      git(['add', '.']);
      git(['commit', '-q', '-m', 'first commit']);
      git(['branch', 'develop']);
      writeFile('a.txt', 'two\n');
      writeFile('android/app/google-services.json', '$_secret 2\n');
      writeFile('lib/app/firebase/firebase_options_dev.dart', '$_secret 3\n');
      git(['add', '.']);
      git(['commit', '-q', '-m', 'second commit']);
      writeFile('a.txt', 'three\n');
      writeFile('b.txt', 'new\n');
      writeFile('.env', '$_secret 4\n');
    });
    tearDown(() => repo.deleteSync(recursive: true));

    test('files lists changed and untracked files and skips secrets', () {
      final (code, out) = review(['files']);

      expect(code, 0);
      expect(out, matches(RegExp(r'^base: [0-9a-f]{40}\n')));
      expect(out, contains('a.txt\n'));
      expect(out, contains('b.txt\n'));
      expect(
        out,
        contains('skipped (never read): android/app/google-services.json'),
      );
      expect(
        out,
        contains(
          'skipped (never read): lib/app/firebase/firebase_options_dev.dart',
        ),
      );
      expect(out, contains('skipped (never read): .env'));
      expect(out, isNot(contains(_secret)));
    });

    test('files between two commits lists no untracked files', () {
      final (code, out) = review(['files', 'develop', 'HEAD']);

      expect(code, 0);
      expect(out, startsWith('base: develop\n'));
      expect(out, contains('a.txt\n'));
      expect(out, isNot(contains('b.txt')));
      expect(out, isNot(contains('.env')));
    });

    test('diff shows safe files and never a secret', () {
      final (code, out) = review(['diff']);

      expect(code, 0);
      expect(out, contains('+three'));
      expect(out, contains('untracked, no diff (read the file): b.txt'));
      expect(
        out,
        contains('skipped (never read): android/app/google-services.json'),
      );
      expect(out, isNot(contains(_secret)));
    });

    test('diff of a secret, its folder or the root prints no secret', () {
      for (final paths in [
        ['android/app/google-services.json'],
        ['android'],
        ['.'],
        ['./'],
        ['lib/'],
        ['*'],
        [':(glob)**'],
      ]) {
        final (code, out) = review(['diff', 'develop', 'HEAD', '--', ...paths]);

        expect(code, 0, reason: '$paths');
        expect(out, isNot(contains(_secret)), reason: '$paths');
      }
    });

    test('diff of a path without changes says so', () {
      final (code, out) = review(['diff', '--', 'docs']);

      expect(code, 0);
      expect(out, 'not changed: docs\n');
    });

    test('log lists commits without patches', () {
      final (code, out) = review(['log', 'develop']);

      expect(code, 0);
      expect(out, contains('second commit'));
      expect(out, isNot(contains('first commit')));
      expect(out, isNot(contains(_secret)));
    });

    test('show prints a safe file and refuses a secret', () {
      expect(review(['show', 'HEAD', 'a.txt']), (0, 'two\n'));

      final (code, out) = review([
        'show',
        'HEAD',
        'android/app/google-services.json',
      ]);
      expect(code, 1);
      expect(out, isNot(contains(_secret)));
    });

    test(
      'search finds lines in tracked and untracked files, ignoring case',
      () {
        final (code, out) = review(['search', 'THREE', '--', 'a.txt', 'b.txt']);
        expect(code, 0);
        expect(out, 'a.txt:1:three\n');

        expect(review(['search', 'New', '--', 'a.txt', 'b.txt']), (
          0,
          'b.txt:1:new\n',
        ));
      },
    );

    test('search at a commit reads that commit', () {
      expect(review(['search', 'two', 'HEAD', '--', 'a.txt']), (
        0,
        'a.txt:1:two\n',
      ));
      expect(review(['search', 'three', 'HEAD', '--', 'a.txt']), (
        0,
        'no matches\n',
      ));
    });

    test('search limited to paths', () {
      final (code, out) = review(['search', 'e', '--', 'b.txt']);

      expect(code, 0);
      expect(out, 'b.txt:1:new\n');
    });

    test('search never prints a secret and lists skipped files', () {
      for (final args in [
        ['search', _secret],
        ['search', _secret, '--', '.'],
        ['search', _secret, '--', 'android'],
        ['search', _secret, '--', 'android/app/google-services.json'],
        ['search', _secret, 'HEAD'],
        ['search', 'fixture', 'HEAD', '--', 'lib/'],
      ]) {
        final (code, out) = review(args);

        expect(code, 0, reason: '$args');
        expect(out, startsWith('no matches\n'), reason: '$args');
        expect(out, isNot(contains(_secret)), reason: '$args');
      }

      final (_, out) = review(['search', _secret]);
      expect(
        out,
        contains('skipped (never read): android/app/google-services.json'),
      );
      expect(out, contains('skipped (never read): .env'));
    });

    test('search finds a safe file next to a skipped secret', () {
      writeFile('note.txt', 'fixture note\n');

      final (code, out) = review(['search', 'fixture']);

      expect(code, 0);
      expect(out, startsWith('note.txt:1:fixture note\n'));
      expect(
        out,
        contains('skipped (never read): android/app/google-services.json'),
      );
      expect(out, isNot(contains(_secret)));
    });

    test('search in batches prints the same as in one call', () {
      writeFile('c.txt', 'three again\n');
      final args = ['search', 'three'];
      final whole = review(args);

      final out = StringBuffer();
      final code = run(args, out, workingDirectory: repo.path, batchChars: 1);

      expect(whole.$2, startsWith('a.txt:1:three\nc.txt:1:three again\n'));
      expect((code, out.toString()), whole);
    });

    test('search without matches says so and exits 0', () {
      expect(review(['search', 'missing', '--', 'a.txt']), (0, 'no matches\n'));
    });

    test('rejects flags with exit code 2 and writes no file', () {
      for (final args in [
        ['diff', '-p'],
        ['diff', '--patch'],
        ['diff', '--stat'],
        ['diff', '--output=x'],
        ['log', '-p'],
        ['log', '--output=x'],
        ['show', 'HEAD', '--output=x'],
      ]) {
        final (code, out) = review(args);

        expect(code, 2, reason: '$args');
        expect(out, startsWith('error: '), reason: '$args');
        expect(out, isNot(contains(_secret)), reason: '$args');
      }
      expect(File('${repo.path}/x').existsSync(), isFalse);
    });

    test('reports a git failure with exit code 1', () {
      final (code, out) = review(['log', 'no-such-branch']);

      expect(code, 1);
      expect(out, startsWith('error: git log'));
    });

    test('reports a git that cannot start with exit code 1', () {
      final out = StringBuffer();
      final code = run(
        ['log', 'develop'],
        out,
        workingDirectory: '${repo.path}/missing',
      );

      expect(code, 1);
      expect(out.toString(), startsWith('error: could not run git'));
    });
  });
}
