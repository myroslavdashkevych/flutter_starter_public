import 'package:flutter_starter/data/items/models/character_dto.dart';
import 'package:flutter_starter/data/items/models/characters_page_dto.dart';
import 'package:flutter_starter/data/items/models/page_info_dto.dart';
import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';

Item testItem(int id) => Item(
  id: id,
  name: 'Item $id',
  imageUrl: 'https://example.invalid/$id.jpeg',
  status: ItemStatus.alive,
  species: 'Human',
  gender: 'Male',
  originName: 'Earth',
  locationName: 'Citadel',
  episodeCount: 2,
);

Paginated<Item> testPage(
  int page, {
  List<int> ids = const [1, 2],
  bool hasMore = true,
}) =>
    Paginated(items: ids.map(testItem).toList(), page: page, hasMore: hasMore);

CharacterDto testCharacterDto(int id) => CharacterDto(
  id: id,
  name: 'Item $id',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  origin: const CharacterPlaceDto(name: 'Earth'),
  location: const CharacterPlaceDto(name: 'Citadel'),
  image: 'https://example.invalid/$id.jpeg',
  episode: const ['https://example.invalid/e/1', 'https://example.invalid/e/2'],
);

CharactersPageDto testPageDto({
  List<int> ids = const [1, 2],
  String? next = 'https://example.invalid/next',
}) => CharactersPageDto(
  info: PageInfoDto(next: next),
  results: ids.map(testCharacterDto).toList(),
);
