import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';

enum ItemStatus { alive, dead, unknown }

@freezed
abstract class Item with _$Item {
  const factory Item({
    required int id,
    required String name,
    required String imageUrl,
    required ItemStatus status,
    required String species,
    required String gender,
    required String originName,
    required String locationName,
    required int episodeCount,
  }) = _Item;
}
