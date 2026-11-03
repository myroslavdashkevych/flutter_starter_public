import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_dto.freezed.dart';
part 'character_dto.g.dart';

@freezed
abstract class CharacterDto with _$CharacterDto {
  const factory CharacterDto({
    required int id,
    required String name,
    required String status,
    required String species,
    required String gender,
    required CharacterPlaceDto origin,
    required CharacterPlaceDto location,
    required String image,
    required List<String> episode,
  }) = _CharacterDto;

  factory CharacterDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterDtoFromJson(json);
}

@freezed
abstract class CharacterPlaceDto with _$CharacterPlaceDto {
  const factory CharacterPlaceDto({required String name}) = _CharacterPlaceDto;

  factory CharacterPlaceDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterPlaceDtoFromJson(json);
}
