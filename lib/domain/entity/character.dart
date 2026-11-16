import 'package:freezed_annotation/freezed_annotation.dart';

part 'character.freezed.dart';

enum CharacterStatus { alive, dead, unknown }

@freezed
abstract class Character with _$Character {
  const factory Character({
    required int id,
    required String name,
    required String imageUrl,
    required CharacterStatus status,
    required String species,
    required String gender,
    required String originName,
    required String locationName,
    required int episodeCount,
  }) = _Character;
}
