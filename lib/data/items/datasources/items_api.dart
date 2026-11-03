import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/network/dio_factory.dart';
import 'package:flutter_starter/data/items/models/character_dto.dart';
import 'package:flutter_starter/data/items/models/characters_page_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'items_api.g.dart';

@lazySingleton
@RestApi()
abstract class ItemsApi {
  @factoryMethod
  factory ItemsApi(@Named(publicDioName) Dio dio) = _ItemsApi;

  @GET('/character')
  Future<CharactersPageDto> getCharacters(
    @Query('page') int page,
    @Query('name') String? name,
  );

  @GET('/character/{id}')
  Future<CharacterDto> getCharacter(@Path('id') int id);
}
