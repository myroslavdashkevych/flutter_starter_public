import 'package:flutter_starter/data/items/models/character_dto.dart';
import 'package:flutter_starter/data/items/models/characters_page_dto.dart';
import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';

extension CharacterDtoMapper on CharacterDto {
  Item toEntity() => Item(
    id: id,
    name: name,
    imageUrl: image,
    status: switch (status.toLowerCase()) {
      'alive' => ItemStatus.alive,
      'dead' => ItemStatus.dead,
      _ => ItemStatus.unknown,
    },
    species: species,
    gender: gender,
    originName: origin.name,
    locationName: location.name,
    episodeCount: episode.length,
  );
}

extension CharactersPageDtoMapper on CharactersPageDto {
  Paginated<Item> toEntity({required int page}) => Paginated(
    items: results.map((character) => character.toEntity()).toList(),
    page: page,
    hasMore: info.next != null,
  );
}
