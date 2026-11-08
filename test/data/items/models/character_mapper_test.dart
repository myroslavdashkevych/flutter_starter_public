import 'package:flutter_starter/data/items/models/character_mapper.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/items_fixtures.dart';

void main() {
  test('ITM-14: maps a character to an item', () {
    expect(testCharacterDto(1).toEntity(), testItem(1));
  });

  test('maps every status, an unexpected one to unknown', () {
    ItemStatus statusOf(String status) =>
        testCharacterDto(1).copyWith(status: status).toEntity().status;

    expect(statusOf('Alive'), ItemStatus.alive);
    expect(statusOf('Dead'), ItemStatus.dead);
    expect(statusOf('unknown'), ItemStatus.unknown);
    expect(statusOf('Other'), ItemStatus.unknown);
  });

  test('ITM-3: a page without a next link is the last one', () {
    expect(testPageDto().toEntity(page: 3), testPage(3));
    expect(
      testPageDto(next: null).toEntity(page: 3),
      testPage(3, hasMore: false),
    );
  });
}
