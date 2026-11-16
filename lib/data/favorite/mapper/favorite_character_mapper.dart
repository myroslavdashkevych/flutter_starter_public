import 'package:flutter_starter/data/favorite/model/favorite_character_dto.dart';
import 'package:flutter_starter/domain/entity/character.dart';

extension FavoriteCharacterDtoMapper on FavoriteCharacterDto {
  Character toEntity() => Character(
    id: id,
    name: name,
    imageUrl: imageUrl,
    status:
        CharacterStatus.values.asNameMap()[status] ?? CharacterStatus.unknown,
    species: species,
    gender: gender,
    originName: originName,
    locationName: locationName,
    episodeCount: episodeCount,
  );
}

extension CharacterToFavoriteDtoMapper on Character {
  FavoriteCharacterDto toFavoriteDto() => FavoriteCharacterDto(
    id: id,
    name: name,
    imageUrl: imageUrl,
    status: status.name,
    species: species,
    gender: gender,
    originName: originName,
    locationName: locationName,
    episodeCount: episodeCount,
  );
}
