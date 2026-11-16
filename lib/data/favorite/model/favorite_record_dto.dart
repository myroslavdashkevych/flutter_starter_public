import 'package:flutter_starter/data/favorite/model/favorite_character_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_record_dto.freezed.dart';
part 'favorite_record_dto.g.dart';

/// The envelope of a stored favorite:
/// `{ "schemaVersion": 1, "addedAt": <iso8601>, "data": <character.toJson()> }`.
/// User data: changes stay backward compatible or ship a migration.
/// `FavoriteHiveDataSource` owns the schema version and checks it before
/// [FavoriteRecordDto.fromJson].
@freezed
abstract class FavoriteRecordDto with _$FavoriteRecordDto {
  const factory FavoriteRecordDto({
    required int schemaVersion,
    required DateTime addedAt,
    @JsonKey(name: 'data') required FavoriteCharacterDto character,
  }) = _FavoriteRecordDto;

  factory FavoriteRecordDto.fromJson(Map<String, dynamic> json) =>
      _$FavoriteRecordDtoFromJson(json);
}
