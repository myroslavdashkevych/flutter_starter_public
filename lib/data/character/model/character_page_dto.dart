import 'package:flutter_starter/data/character/model/character_dto.dart';
import 'package:flutter_starter/data/character/model/page_info_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_page_dto.freezed.dart';
part 'character_page_dto.g.dart';

@freezed
abstract class CharacterPageDto with _$CharacterPageDto {
  const factory CharacterPageDto({
    required PageInfoDto info,
    required List<CharacterDto> results,
  }) = _CharacterPageDto;

  factory CharacterPageDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterPageDtoFromJson(json);
}
