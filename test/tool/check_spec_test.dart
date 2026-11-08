import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_spec.dart';

const _favPath = 'docs/spec/features/favorites.md';
const _itmPath = 'docs/spec/features/items.md';

const _favorites = '''
# Favorites

## Requirements

- **FAV-1** A signed-in user can add a favorite.
  - GIVEN a signed-in user WHEN the user taps the toggle THEN the item is a
    favorite
- **FAV-2** A guest sees no toggles (ITM-1).
  - WHEN a guest opens the list
    THEN no toggle is shown

## Dialogs

- **Remove dialog**: **Remove** and **Cancel**. Design: pending

## Screens

### SCR-1 Favorites

- Route: `/favorites`.
- Design: pending

Retired: none
''';

const _items = '''
# Items

- **ITM-1** The list loads.
  - WHEN the list opens THEN items are shown

Retired: none
''';

const _fixtureTest = 'test/fixture_test.dart';
final _definition = RegExp(r'^- \*\*([A-Z]+-\d+)\*\* ', multiLine: true);

/// [files] plus a test file named by every requirement they define, so the
/// coverage rule passes unless a test replaces that file.
Map<String, String> _withTests(Map<String, String> files) => {
  _fixtureTest: [
    for (final content in files.values)
      for (final match in _definition.allMatches(content))
        "test('${match[1]}: covered', () {});\n",
  ].join(),
  ...files,
};

Map<String, String> _project([Map<String, String> files = const {}]) =>
    _withTests({_favPath: _favorites, _itmPath: _items, ...files});

/// [_favorites] with [from] replaced by [to].
Map<String, String> _favoritesWith(String from, String to) {
  expect(_favorites, contains(from));
  return _project({_favPath: _favorites.replaceFirst(from, to)});
}

List<String> _rules(Map<String, String> files) =>
    checkFiles(files).map((violation) => violation.rule).toList();

void _expectClean(Map<String, String> files) {
  expect(checkFiles(files), isEmpty);
}

/// At least one violation, and all of them break the rule [name].
void _expectOnly(Map<String, String> files, String name) {
  final rules = _rules(files);
  expect(rules, isNotEmpty);
  expect(rules, everyElement(startsWith('$name:')));
}

void main() {
  test('the fixture project is clean', () {
    _expectClean(_project());
  });

  test('reads files with CRLF line endings', () {
    _expectClean({
      for (final MapEntry(key: path, value: content) in _project().entries)
        path: content.replaceAll('\n', '\r\n'),
    });
  });

  group('format', () {
    test('a bold item that is not an ID passes', () {
      _expectClean(_project());
    });

    test('rejects an ID without a sentence after it', () {
      _expectOnly(
        _favoritesWith('**FAV-2** A guest', '**FAV-2**A guest'),
        'format',
      );
    });

    test('rejects a lowercase ID and an ID without a hyphen', () {
      _expectOnly(_favoritesWith('**FAV-2**', '**fav-2**'), 'format');
      _expectOnly(_favoritesWith('**FAV-2**', '**FAV2**'), 'format');
    });

    test('rejects a number with a leading zero', () {
      _expectOnly(_favoritesWith('**FAV-2**', '**FAV-02**'), 'format');
    });
  });

  group('prefix', () {
    test('rejects a second prefix in one file', () {
      final files = _favoritesWith('**FAV-2**', '**ITM-2**');
      _expectOnly({...files, _itmPath: _items}, 'prefix');
    });

    test('rejects a prefix used by two files', () {
      final files = _project({
        _itmPath: _items.replaceFirst('**ITM-1**', '**FAV-3**'),
      });
      expect(
        _rules(files),
        contains('prefix: FAV is already used by $_favPath'),
      );
    });

    test('rejects SCR as a requirement prefix', () {
      _expectOnly(
        _project({_itmPath: _items.replaceFirst('**ITM-1**', '**SCR-2**')}),
        'prefix',
      );
    });
  });

  group('scenario', () {
    test('joins a scenario continued on the next line', () {
      _expectClean(_project());
    });

    test('rejects a requirement without nested items', () {
      _expectOnly(
        _project({
          _itmPath: _items.replaceFirst(
            '  - WHEN the list opens THEN items are shown\n',
            '',
          ),
        }),
        'scenario',
      );
    });

    test('rejects an item without THEN, or with THEN before WHEN', () {
      _expectOnly(
        _project({_itmPath: _items.replaceFirst('THEN items', 'and items')}),
        'scenario',
      );
      _expectOnly(
        _project({
          _itmPath: _items.replaceFirst(
            'WHEN the list opens THEN items are shown',
            'THEN items are shown WHEN the list opens',
          ),
        }),
        'scenario',
      );
    });
  });

  group('screen', () {
    test('rejects a screen without a Design line', () {
      _expectOnly(_favoritesWith('- Design: pending\n', ''), 'screen');
    });

    test('rejects a screen heading at another level', () {
      _expectOnly(
        _favoritesWith('### SCR-1 Favorites', '## SCR-1 Favorites'),
        'screen',
      );
    });
  });

  group('duplicate', () {
    test('rejects a requirement ID defined twice', () {
      final files = _favoritesWith('**FAV-2**', '**FAV-1**');
      expect(
        _rules(files),
        contains('duplicate: FAV-1 is already defined at $_favPath:5'),
      );
    });

    test('rejects a screen defined in two files', () {
      final files = _project({
        _itmPath: _items.replaceFirst(
          'Retired: none',
          '### SCR-1 Items\n\n- Design: pending\n\nRetired: none',
        ),
      });
      _expectOnly(files, 'duplicate');
    });
  });

  group('retired', () {
    test('accepts retired IDs of the file and of screens', () {
      _expectClean(_favoritesWith('Retired: none', 'Retired: FAV-3, SCR-2'));
    });

    test('rejects a file without a Retired line', () {
      _expectOnly(_favoritesWith('Retired: none\n', ''), 'retired');
    });

    test('rejects a second Retired line and one that is not last', () {
      _expectOnly(
        _favoritesWith('## Dialogs', 'Retired: none\n\n## Dialogs'),
        'retired',
      );
      _expectOnly(
        _favoritesWith('Retired: none', 'Retired: none\n\nMore text.'),
        'retired',
      );
    });

    test('rejects a value that is not an ID', () {
      _expectOnly(
        _favoritesWith('Retired: none', 'Retired: FAV-3, old'),
        'retired',
      );
      _expectOnly(_favoritesWith('Retired: none', 'Retired:'), 'retired');
    });

    test('rejects a retired ID that is still defined', () {
      _expectOnly(_favoritesWith('Retired: none', 'Retired: FAV-2'), 'retired');
    });

    test('rejects a retired ID of another prefix', () {
      _expectOnly(_favoritesWith('Retired: none', 'Retired: ITM-2'), 'retired');
    });
  });

  group('gap', () {
    test('rejects a removed requirement that was not retired', () {
      final files = _favoritesWith(
        '- **FAV-1** A signed-in user can add a favorite.\n'
            '  - GIVEN a signed-in user WHEN the user taps the toggle THEN the '
            'item is a\n'
            '    favorite\n',
        '',
      );
      expect(_rules(files), [
        'gap: FAV-1 is neither defined nor retired; a removed ID goes to the '
            'Retired line of its file',
      ]);
    });

    test('rejects a missing screen number', () {
      _expectOnly(_favoritesWith('### SCR-1', '### SCR-2'), 'gap');
    });

    test('accepts a removed requirement that was retired', () {
      _expectClean(
        _favoritesWith(
          '- **FAV-2** A guest sees no toggles (ITM-1).\n'
              '  - WHEN a guest opens the list\n'
              '    THEN no toggle is shown\n',
          '',
        ).map(
          (path, content) => MapEntry(
            path,
            path == _favPath
                ? content.replaceFirst('Retired: none\n', 'Retired: FAV-2\n')
                : content,
          ),
        ),
      );
    });
  });

  group('removed', () {
    const fav2 =
        '- **FAV-2** A guest sees no toggles (ITM-1).\n'
        '  - WHEN a guest opens the list\n'
        '    THEN no toggle is shown\n';
    const scr1 =
        '### SCR-1 Favorites\n\n- Route: `/favorites`.\n- Design: pending\n\n';
    const retiredNone = 'Retired: none';

    /// The fixture project with FAV-2 removed and retired.
    Map<String, String> fav2Retired() => _project({
      _favPath: _favorites
          .replaceFirst(fav2, '')
          .replaceFirst(retiredNone, 'Retired: FAV-2'),
    });

    List<String> removed(Map<String, String> base, Map<String, String> files) =>
        checkFiles(
          files,
          baseFiles: base,
          baseName: 'develop',
        ).map((violation) => violation.rule).toList();

    String definedMessage(String id) =>
        'removed: $id is defined in develop but neither defined nor retired; '
        'add it to the Retired line of its file';
    String retiredMessage(String id) =>
        'removed: $id is retired in develop; a retired ID stays on the '
        'Retired line and is never reused';

    test('passes when the base equals the current spec', () {
      expect(removed(_project(), _project()), isEmpty);
    });

    test('passes when a requirement is added', () {
      final files = _favoritesWith(
        '## Dialogs',
        '- **FAV-3** A user can share a favorite.\n'
            '  - WHEN the user taps share THEN the share sheet opens\n\n'
            '## Dialogs',
      );
      expect(removed(_project(), files), isEmpty);
    });

    test('passes when a removed requirement is retired', () {
      expect(removed(_project(), fav2Retired()), isEmpty);
    });

    test('rejects the highest requirement removed without retiring it', () {
      final files = _favoritesWith(fav2, '');
      expect(checkFiles(files), isEmpty, reason: 'gap alone misses it');

      final violations = checkFiles(
        files,
        baseFiles: _project(),
        baseName: 'develop',
      );
      expect(violations.map((violation) => violation.rule), [
        definedMessage('FAV-2'),
      ]);
      expect(violations.single.path, _favPath);
      expect(
        violations.single.line,
        files[_favPath]!.split('\n').indexOf(retiredNone) + 1,
      );
    });

    test('rejects a middle requirement removed without retiring it', () {
      final files = _favoritesWith(
        '- **FAV-1** A signed-in user can add a favorite.\n'
            '  - GIVEN a signed-in user WHEN the user taps the toggle THEN the '
            'item is a\n'
            '    favorite\n',
        '',
      );
      expect(removed(_project(), files), contains(definedMessage('FAV-1')));
    });

    test('rejects a retired ID that is defined again', () {
      final violations = checkFiles(
        _project(),
        baseFiles: fav2Retired(),
        baseName: 'develop',
      );
      expect(violations.map((violation) => violation.rule), [
        retiredMessage('FAV-2'),
      ]);
      expect(violations.single.path, _favPath);
    });

    test('rejects a retired ID dropped from the Retired line', () {
      final base = _favoritesWith(retiredNone, 'Retired: FAV-3');
      expect(removed(base, _project()), [retiredMessage('FAV-3')]);
    });

    test('rejects a screen removed without retiring it', () {
      final files = _favoritesWith(scr1, '');
      expect(checkFiles(files), isEmpty, reason: 'gap alone misses it');
      final violations = checkFiles(
        files,
        baseFiles: _project(),
        baseName: 'develop',
      );
      expect(violations.map((violation) => violation.rule), [
        definedMessage('SCR-1'),
      ]);
      expect(violations.single.path, _favPath);
    });

    test('reports a screen of a deleted file at the first feature file', () {
      final violations = checkFiles(
        _withTests({_itmPath: _items}),
        baseFiles: _project(),
        baseName: 'develop',
      );
      expect(violations.map((violation) => violation.rule), [
        definedMessage('SCR-1'),
      ]);
      expect(violations.single.path, _itmPath);
    });

    test('rejects a retired screen that is defined again', () {
      final base = _favoritesWith(retiredNone, 'Retired: SCR-2');
      final files = _project({
        _itmPath: _items.replaceFirst(
          retiredNone,
          '### SCR-2 Items\n\n- Design: pending\n\n$retiredNone',
        ),
      });
      expect(removed(base, files), [retiredMessage('SCR-2')]);
    });

    test('ignores a prefix that no feature file uses any more', () {
      expect(removed(_project(), _withTests({_favPath: _favorites})), isEmpty);
    });

    test('passes when a screen moves to another feature file', () {
      final files = _favoritesWith(scr1, '');
      files[_itmPath] = _items.replaceFirst(retiredNone, '$scr1$retiredNone');
      expect(removed(_project(), files), isEmpty);
    });
  });

  group('reference', () {
    test('accepts defined IDs and tokens of unknown prefixes', () {
      _expectClean(
        _project({
          'README.md': 'See FAV-2, SCR-1 and ITM-1. UTF-8, SHA-256.\n',
          'lib/a.dart': '/// Rule ITM-1.\n',
        }),
      );
    });

    test('rejects an undefined ID', () {
      expect(_rules(_project({'CLAUDE.md': 'Like FAV-9.\n'})), [
        'reference: FAV-9 is not defined in docs/spec/features',
      ]);
    });

    test('rejects a retired ID outside the Retired line', () {
      final files = _favoritesWith('Retired: none', 'Retired: FAV-3');
      expect(_rules({...files, 'lib/a.dart': '// FAV-3\n'}), [
        'reference: FAV-3 is retired',
      ]);
    });
  });

  group('test name', () {
    test('accepts "<ID>: <behavior>"', () {
      _expectClean(
        _project({
          'test/a_test.dart': "test('FAV-2: guest sees no toggle', () {});\n",
        }),
      );
    });

    test('accepts several IDs separated by ", "', () {
      _expectClean(
        _project({
          'test/a_test.dart': "test('FAV-1, FAV-2, ITM-1: toggles', () {});\n",
        }),
      );
    });

    test('rejects a malformed ID list', () {
      _expectOnly(
        _project({
          'test/a_test.dart':
              "test('FAV-1,FAV-2: x', () {});\n"
              "test('FAV-1 FAV-2: x', () {});\n"
              "test('FAV-1, toggles', () {});\n",
        }),
        'test name',
      );
    });

    test('rejects an ID without ": " after it', () {
      _expectOnly(
        _project({
          'test/a_test.dart':
              "test('FAV-2 guest sees no toggle', () {});\n"
              'test("FAV-1 - adds", () {});\n',
        }),
        'test name',
      );
    });

    test('checks only test files', () {
      _expectClean(_project({'lib/a.dart': "const a = 'FAV-2 text';\n"}));
    });
  });

  group('coverage', () {
    const uncoveredFav2 =
        "coverage: FAV-2 has no test named by it; add one ('FAV-2: …') or put "
        'it on the Manual line';

    /// The fixture project with [tests] as its only test file.
    Map<String, String> withTests(String tests) =>
        _project({_fixtureTest: tests});

    test('reports a requirement without a test at its definition', () {
      final violations = checkFiles(
        withTests("test('FAV-1, ITM-1: covered', () {});\n"),
      );
      expect(violations.map((violation) => violation.rule), [uncoveredFav2]);
      expect(violations.single.path, _favPath);
      expect(violations.single.line, 8);
    });

    test('a group name with an ID list covers each ID', () {
      _expectClean(withTests("group('FAV-1, FAV-2, ITM-1: all', () {});\n"));
    });

    test('an ID inside a name or outside test/ does not cover', () {
      final files = withTests(
        "test('FAV-1, ITM-1: covered', () {});\n"
        "test('adds FAV-2: twice', () {});\n",
      );
      expect(_rules(files), [uncoveredFav2]);
      expect(_rules({...files, 'lib/a.dart': "const a = 'FAV-2: x';\n"}), [
        uncoveredFav2,
      ]);
    });

    test('a Manual entry covers', () {
      _expectClean({
        ..._favoritesWith('Retired: none', 'Manual: FAV-2\n\nRetired: none'),
        _fixtureTest: "test('FAV-1, ITM-1: covered', () {});\n",
      });
    });

    test('a screen needs no test', () {
      expect(_project()[_fixtureTest], isNot(contains('SCR-1')));
      _expectClean(_project());
    });
  });

  group('manual', () {
    const allTested = "test('FAV-1, FAV-2, ITM-1: covered', () {});\n";
    const fav2Untested = "test('FAV-1, ITM-1: covered', () {});\n";
    const itm1Tested = "test('ITM-1: covered', () {});\n";

    /// The fixture project with [manual] right before the Retired line of the
    /// favorites file, and [tests] as its only test file.
    Map<String, String> withManual(
      String manual, {
      String tests = fav2Untested,
      String retired = 'Retired: none',
    }) => {
      ..._favoritesWith('Retired: none', '$manual\n\n$retired'),
      _fixtureTest: tests,
    };

    test('accepts IDs of the file right before the Retired line', () {
      _expectClean(withManual('Manual: FAV-2'));
      _expectClean(withManual('Manual: FAV-1, FAV-2', tests: itm1Tested));
    });

    test('rejects a second Manual line', () {
      expect(
        _rules(withManual('Manual: FAV-1\nManual: FAV-2', tests: itm1Tested)),
        [
          'manual: the Manual line comes right before the Retired line',
          'manual: one Manual line per file',
        ],
      );
    });

    test('rejects a Manual line that is not right before Retired', () {
      expect(
        _rules({
          ..._favoritesWith('## Dialogs', 'Manual: FAV-2\n\n## Dialogs'),
          _fixtureTest: fav2Untested,
        }),
        ['manual: the Manual line comes right before the Retired line'],
      );
    });

    test('rejects an empty value, none and a token that is not an ID', () {
      const value =
          'manual: "Manual: <IDs>"; omit the line when there are none';
      expect(_rules(withManual('Manual:', tests: allTested)), [value]);
      expect(_rules(withManual('Manual: none', tests: allTested)), [value]);
      expect(_rules(withManual('Manual: FAV-2, later')), [
        'manual: "later" is not an ID',
      ]);
    });

    test('rejects an ID of another prefix', () {
      expect(_rules(withManual('Manual: FAV-2, ITM-1')), [
        'manual: ITM-1 does not belong to this file',
      ]);
    });

    test(
      'rejects an undefined or retired ID once, not also as a reference',
      () {
        expect(_rules(withManual('Manual: FAV-2, FAV-3')), [
          'manual: FAV-3 is not defined',
        ]);
        expect(
          _rules(withManual('Manual: FAV-2, FAV-3', retired: 'Retired: FAV-3')),
          ['manual: FAV-3 is retired'],
        );
      },
    );

    test('rejects an ID listed twice', () {
      expect(_rules(withManual('Manual: FAV-2, FAV-2')), [
        'manual: FAV-2 is listed twice',
      ]);
    });

    test('rejects an ID that has a test', () {
      expect(_rules(withManual('Manual: FAV-2', tests: allTested)), [
        'manual: FAV-2 has a test at $_fixtureTest:1; remove it from the '
            'Manual line',
      ]);
    });
  });

  group('link', () {
    test('accepts existing files, folders and headings', () {
      _expectClean(
        _project({
          'README.md':
              '[a]($_itmPath) [b](docs/spec/features/) '
              '[c]($_favPath#scr-1-favorites) [d](#notes) [e](#notes-1)\n'
              '[f](docs/guide.md#2-rename-with-toolinit_projectdart)\n'
              '\n## Notes\n\n## Notes\n',
          'docs/guide.md':
              '# Guide\n\n## 2. Rename with `tool/init_project.dart`\n',
        }),
      );
    });

    test('skips external links, inline code and code blocks', () {
      _expectClean(
        _project({
          'README.md':
              '[a](https://example.com/x.md) [b](mailto:a@b.c)\n'
              '`[c](missing.md)`\n'
              '```\n[d](missing.md)\n```\n',
        }),
      );
    });

    test('rejects a missing file and a link out of the project', () {
      expect(_rules(_project({'docs/a.md': '[a](b.md) [c](../../x.md)\n'})), [
        'link: b.md does not exist',
        'link: ../../x.md does not exist',
      ]);
    });

    test('rejects a missing heading', () {
      expect(_rules(_project({'README.md': '[a]($_itmPath#nope)\n'})), [
        'link: $_itmPath has no heading #nope',
      ]);
    });
  });

  group('isChecked', () {
    test('reads docs, README, CLAUDE and own Dart code', () {
      for (final path in [
        'README.md',
        'CLAUDE.md',
        'docs/README.md',
        'docs/spec/features/items.md',
        'lib/app/app.dart',
        'test/a_test.dart',
        'tool/check_imports.dart',
      ]) {
        expect(isChecked(path), isTrue, reason: path);
      }
    });

    test('skips change folders, generated code and its own files', () {
      for (final path in [
        'docs/changes/2026-01-01-x/proposal.md',
        'docs/design/screens/a.webp',
        'lib/a.g.dart',
        'lib/a.freezed.dart',
        'lib/a.config.dart',
        'test/a.mocks.dart',
        'lib/l10n/gen/app_localizations.dart',
        'tool/check_spec.dart',
        'test/tool/check_spec_test.dart',
        'android/app/a.dart',
      ]) {
        expect(isChecked(path), isFalse, reason: path);
      }
    });

    test('skips never-read files', () {
      for (final path in [
        'lib/app/firebase/firebase_options_dev.dart',
        'lib/app/firebase/firebase_options_prod.dart',
        'docs/.env.md',
      ]) {
        expect(isChecked(path), isFalse, reason: path);
      }
    });
  });

  group('run', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('check_spec'));
    tearDown(() => root.deleteSync(recursive: true));

    void writeFiles(Map<String, String> files) {
      for (final MapEntry(key: path, value: content) in files.entries) {
        File('${root.path}/$path')
          ..createSync(recursive: true)
          ..writeAsStringSync(content);
      }
    }

    test('returns 0 for a project without violations', () {
      writeFiles(_project({'README.md': '[a]($_favPath)\n'}));
      final out = StringBuffer();

      expect(run(root, out), 0);
      expect(out.toString(), contains('No spec violations.'));
    });

    test('never opens a never-read file', () {
      writeFiles(_project({'README.md': '[a]($_favPath)\n'}));
      // Not valid UTF-8: reading it as a string would throw.
      File('${root.path}/lib/app/firebase/firebase_options_dev.dart')
        ..createSync(recursive: true)
        ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
      final out = StringBuffer();

      expect(run(root, out), 0);
      expect(out.toString(), contains('No spec violations.'));
    });

    test('never opens a never-read link target to check its anchor', () {
      writeFiles(_project({'README.md': '[a](docs/.env.md#a)\n'}));
      // Not valid UTF-8: reading it as a string would throw.
      File('${root.path}/docs/.env.md')
        ..createSync(recursive: true)
        ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
      final out = StringBuffer();

      expect(run(root, out), 0);
    });

    test('returns 1 and reports a deliberately broken spec', () {
      writeFiles(_project({'README.md': 'See FAV-7.\n'}));
      final out = StringBuffer();

      expect(run(root, out), 1);
      expect(
        out.toString(),
        contains('README.md:1: reference: FAV-7 is not defined'),
      );
      expect(out.toString(), contains('1 spec violation(s).'));
    });

    test('skips change folders', () {
      writeFiles(
        _project({'docs/changes/2026-01-01-x/proposal.md': '**FAV-3** new\n'}),
      );

      expect(run(root, StringBuffer()), 0);
    });

    group('with a git base', () {
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
        ], workingDirectory: root.path);
        if (result.exitCode != 0) fail('git $args: ${result.stderr}');
      }

      setUp(() {
        git(['init', '-q']);
        writeFiles(_project());
        git(['add', '.']);
        git(['commit', '-q', '-m', 'base']);
        git(['branch', 'base']);
      });

      test('with a base, returns 0 when nothing was removed', () {
        final out = StringBuffer();

        expect(run(root, out, base: 'base'), 0);
        expect(out.toString(), contains('No spec violations.'));
      });

      test('with a base, reports an ID removed since that revision', () {
        writeFiles({
          _favPath: _favorites.replaceFirst(
            '- **FAV-2** A guest sees no toggles (ITM-1).\n'
                '  - WHEN a guest opens the list\n'
                '    THEN no toggle is shown\n',
            '',
          ),
        });
        final out = StringBuffer();

        expect(run(root, out, base: 'base'), 1);
        expect(out.toString(), contains('removed: FAV-2 is defined in base'));
      });

      test('returns 2 for an unknown base revision', () {
        final out = StringBuffer();

        expect(run(root, out, base: 'no-such-branch'), 2);
        expect(out.toString(), startsWith('error: git rev-parse:'));
      });

      test('returns 2 for a base that looks like a flag', () {
        final out = StringBuffer();

        expect(run(root, out, base: '--output=x'), 2);
        expect(out.toString(), contains('not a revision: "--output=x"'));
      });
    });
  });
}
