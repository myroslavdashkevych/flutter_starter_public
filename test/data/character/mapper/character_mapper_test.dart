import 'package:flutter_starter/data/character/mapper/character_mapper.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/character_fixture.dart';

void main() {
  test('CHR-14: maps a character DTO to a character', () {
    expect(testCharacterDto(1).toEntity(), testCharacter(1));
  });

  test('maps every status, an unexpected one to unknown', () {
    CharacterStatus statusOf(String status) =>
        testCharacterDto(1).copyWith(status: status).toEntity().status;

    expect(statusOf('Alive'), CharacterStatus.alive);
    expect(statusOf('Dead'), CharacterStatus.dead);
    expect(statusOf('unknown'), CharacterStatus.unknown);
    expect(statusOf('Other'), CharacterStatus.unknown);
  });

  test('CHR-3: a page without a next link is the last one', () {
    expect(testPageDto().toEntity(page: 3), testPage(3));
    expect(
      testPageDto(next: null).toEntity(page: 3),
      testPage(3, hasMore: false),
    );
  });
}
