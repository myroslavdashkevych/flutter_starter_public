import 'package:flutter_starter/data/auth/mapper/app_user_mapper.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/mock.dart';

void main() {
  test('a Firebase user maps to AppUser', () {
    final user = MockFirebaseUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => user.email).thenReturn('user@example.com');

    expect(
      user.toEntity(),
      const AppUser(id: 'user-1', email: 'user@example.com'),
    );
  });
}
