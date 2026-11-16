import 'package:dio/dio.dart';
import 'package:flutter_starter/data/_shared/data_source/network/dio_factory.dart';
import 'package:flutter_starter/data/character/model/character_dto.dart';
import 'package:flutter_starter/data/character/model/character_page_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'character_api_data_source.g.dart';

@lazySingleton
@RestApi()
abstract class CharacterApiDataSource {
  @factoryMethod
  factory CharacterApiDataSource(@Named(publicDioName) Dio dio) =
      _CharacterApiDataSource;

  @GET('/character')
  Future<CharacterPageDto> getCharacters(
    @Query('page') int page,
    @Query('name') String? name,
  );

  @GET('/character/{id}')
  Future<CharacterDto> getCharacter(@Path('id') int id);
}
