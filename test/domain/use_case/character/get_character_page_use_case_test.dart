import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/character/get_character_page_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/character_fixture.dart';
import '../../../helper/mock.dart';

void main() {
  late MockCharacterRepository repository;
  late GetCharacterPageUseCase useCase;

  setUp(() {
    repository = MockCharacterRepository();
    useCase = GetCharacterPageUseCase(repository);
    when(
      () => repository.getPage(
        page: any(named: 'page'),
        query: any(named: 'query'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => Ok(testPage(1)));
  });

  test('CHR-2: trims the query and passes the other arguments', () async {
    await useCase((page: 2, query: '  rick ', forceRefresh: true));

    verify(() => repository.getPage(page: 2, query: 'rick', forceRefresh: true))
        .called(1);
  });

  test('CHR-2: a blank query means no search', () async {
    await useCase((page: 1, query: '   ', forceRefresh: false));

    verify(() => repository.getPage(page: 1)).called(1);
  });
}
