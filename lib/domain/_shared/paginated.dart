import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated.freezed.dart';

@freezed
abstract class Paginated<T> with _$Paginated<T> {
  const factory Paginated({
    required List<T> items,
    required int page,
    required bool hasMore,
  }) = _Paginated<T>;
}
