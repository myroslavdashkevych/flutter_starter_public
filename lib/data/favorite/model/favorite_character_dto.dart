import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_character_dto.freezed.dart';
part 'favorite_character_dto.g.dart';

/// A stored snapshot of a character. This is persistent data, not a cache: changes
/// must stay backward compatible (`@JsonKey(defaultValue: ...)`) or ship a
/// migration.
@freezed
abstract class FavoriteCharacterDto with _$FavoriteCharacterDto {
  const factory FavoriteCharacterDto({
    required int id,
    required String name,
    required String imageUrl,
    required String status,
    required String species,
    required String gender,
    required String originName,
    required String locationName,
    required int episodeCount,
  }) = _FavoriteCharacterDto;

  factory FavoriteCharacterDto.fromJson(Map<String, dynamic> json) =>
      _$FavoriteCharacterDtoFromJson(json);
}
