import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_place_dto.freezed.dart';
part 'character_place_dto.g.dart';

@freezed
abstract class CharacterPlaceDto with _$CharacterPlaceDto {
  const factory CharacterPlaceDto({required String name}) = _CharacterPlaceDto;

  factory CharacterPlaceDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterPlaceDtoFromJson(json);
}
