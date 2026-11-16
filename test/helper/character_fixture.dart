import 'package:flutter_starter/data/character/model/character_dto.dart';
import 'package:flutter_starter/data/character/model/character_page_dto.dart';
import 'package:flutter_starter/data/character/model/character_place_dto.dart';
import 'package:flutter_starter/data/character/model/page_info_dto.dart';
import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/entity/character.dart';

Character testCharacter(int id) => Character(
  id: id,
  name: 'Character $id',
  imageUrl: 'https://example.invalid/$id.jpeg',
  status: CharacterStatus.alive,
  species: 'Human',
  gender: 'Male',
  originName: 'Earth',
  locationName: 'Citadel',
  episodeCount: 2,
);

Paginated<Character> testPage(
  int page, {
  List<int> ids = const [1, 2],
  bool hasMore = true,
}) => Paginated(
  items: ids.map(testCharacter).toList(),
  page: page,
  hasMore: hasMore,
);

CharacterDto testCharacterDto(int id) => CharacterDto(
  id: id,
  name: 'Character $id',
  status: 'Alive',
  species: 'Human',
  gender: 'Male',
  origin: const CharacterPlaceDto(name: 'Earth'),
  location: const CharacterPlaceDto(name: 'Citadel'),
  image: 'https://example.invalid/$id.jpeg',
  episode: const ['https://example.invalid/e/1', 'https://example.invalid/e/2'],
);

CharacterPageDto testPageDto({
  List<int> ids = const [1, 2],
  String? next = 'https://example.invalid/next',
}) => CharacterPageDto(
  info: PageInfoDto(next: next),
  results: ids.map(testCharacterDto).toList(),
);
