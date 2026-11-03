import 'package:flutter_starter/data/items/models/character_dto.dart';
import 'package:flutter_starter/data/items/models/page_info_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'characters_page_dto.freezed.dart';
part 'characters_page_dto.g.dart';

@freezed
abstract class CharactersPageDto with _$CharactersPageDto {
  const factory CharactersPageDto({
    required PageInfoDto info,
    required List<CharacterDto> results,
  }) = _CharactersPageDto;

  factory CharactersPageDto.fromJson(Map<String, dynamic> json) =>
      _$CharactersPageDtoFromJson(json);
}
