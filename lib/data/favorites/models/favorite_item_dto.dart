import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_item_dto.freezed.dart';
part 'favorite_item_dto.g.dart';

/// A stored snapshot of an item. This is persistent data, not a cache: changes
/// must stay backward compatible (`@JsonKey(defaultValue: ...)`) or ship a
/// migration.
@freezed
abstract class FavoriteItemDto with _$FavoriteItemDto {
  const factory FavoriteItemDto({
    required int id,
    required String name,
    required String imageUrl,
    required String status,
    required String species,
    required String gender,
    required String originName,
    required String locationName,
    required int episodeCount,
  }) = _FavoriteItemDto;

  factory FavoriteItemDto.fromJson(Map<String, dynamic> json) =>
      _$FavoriteItemDtoFromJson(json);
}
