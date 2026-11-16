import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_starter/data/character/data_source/character_api_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/character_fixture.dart';
import '../../../helper/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late CharacterApiDataSource api;

  void setUpApi(Object body) {
    adapter = FakeHttpClientAdapter(
      (_) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    api = CharacterApiDataSource(
      Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = adapter,
    );
  }

  test('getCharacters sends the page and parses the response', () async {
    setUpApi(testPageDto(ids: [1]).toJson());

    final page = await api.getCharacters(2, 'rick');

    final request = adapter.requests.single;
    expect(request.uri.path, '/api/character');
    expect(request.queryParameters, {'page': 2, 'name': 'rick'});
    expect(page, testPageDto(ids: [1]));
  });

  test('CHR-2: getCharacters leaves out an empty search', () async {
    setUpApi(testPageDto().toJson());

    await api.getCharacters(1, null);

    expect(adapter.requests.single.queryParameters, {'page': 1});
  });

  test('getCharacter requests the character by id', () async {
    setUpApi(testCharacterDto(7).toJson());

    final character = await api.getCharacter(7);

    expect(adapter.requests.single.uri.path, '/api/character/7');
    expect(character, testCharacterDto(7));
  });
}
