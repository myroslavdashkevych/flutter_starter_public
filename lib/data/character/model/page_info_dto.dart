import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_info_dto.freezed.dart';
part 'page_info_dto.g.dart';

@freezed
abstract class PageInfoDto with _$PageInfoDto {
  const factory PageInfoDto({String? next}) = _PageInfoDto;

  factory PageInfoDto.fromJson(Map<String, dynamic> json) =>
      _$PageInfoDtoFromJson(json);
}
