import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/usecases/get_items_page_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockItemsRepository repository;
  late GetItemsPageUseCase useCase;

  setUp(() {
    repository = MockItemsRepository();
    useCase = GetItemsPageUseCase(repository);
    when(
      () => repository.getPage(
        page: any(named: 'page'),
        query: any(named: 'query'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => Ok(testPage(1)));
  });

  test('trims the query and passes the other arguments', () async {
    await useCase(page: 2, query: '  rick ', forceRefresh: true);

    verify(() => repository.getPage(page: 2, query: 'rick', forceRefresh: true))
        .called(1);
  });

  test('a blank query means no search', () async {
    await useCase(page: 1, query: '   ');

    verify(() => repository.getPage(page: 1)).called(1);
  });
}
