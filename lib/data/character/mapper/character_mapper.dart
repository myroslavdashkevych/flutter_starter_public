import 'package:flutter_starter/data/character/model/character_dto.dart';
import 'package:flutter_starter/data/character/model/character_page_dto.dart';
import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/entity/character.dart';

extension CharacterDtoMapper on CharacterDto {
  Character toEntity() => Character(
    id: id,
    name: name,
    imageUrl: image,
    status: switch (status.toLowerCase()) {
      'alive' => CharacterStatus.alive,
      'dead' => CharacterStatus.dead,
      _ => CharacterStatus.unknown,
    },
    species: species,
    gender: gender,
    originName: origin.name,
    locationName: location.name,
    episodeCount: episode.length,
  );
}

extension CharacterPageDtoMapper on CharacterPageDto {
  Paginated<Character> toEntity({required int page}) => Paginated(
    items: results.map((character) => character.toEntity()).toList(),
    page: page,
    hasMore: info.next != null,
  );
}
