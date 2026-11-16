import 'package:freezed_annotation/freezed_annotation.dart';

part 'cached_record_dto.freezed.dart';
part 'cached_record_dto.g.dart';

/// The envelope of every record in the character cache:
/// `{ "schemaVersion": 1, "fetchedAt": <iso8601>, "data": <dto.toJson()> }`.
/// `CharacterHiveDataSource` owns the schema version and checks it before
/// [CachedRecordDto.fromJson].
@Freezed(genericArgumentFactories: true)
abstract class CachedRecordDto<T> with _$CachedRecordDto<T> {
  const factory CachedRecordDto({
    required int schemaVersion,
    required DateTime fetchedAt,
    required T data,
  }) = _CachedRecordDto<T>;

  factory CachedRecordDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$CachedRecordDtoFromJson(json, fromJsonT);
}
