import 'package:flutter_starter/data/favorites/models/favorite_item_dto.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';

extension FavoriteItemDtoMapper on FavoriteItemDto {
  Item toEntity() => Item(
    id: id,
    name: name,
    imageUrl: imageUrl,
    status: ItemStatus.values.asNameMap()[status] ?? ItemStatus.unknown,
    species: species,
    gender: gender,
    originName: originName,
    locationName: locationName,
    episodeCount: episodeCount,
  );
}

extension ItemToFavoriteDtoMapper on Item {
  FavoriteItemDto toFavoriteDto() => FavoriteItemDto(
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
