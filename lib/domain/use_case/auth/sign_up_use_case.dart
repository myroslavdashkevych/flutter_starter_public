import 'dart:async';

import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:injectable/injectable.dart';

/// Creates an account with email and password and sends the sign-up event
/// when it succeeds (AUTH-8).
@injectable
class SignUpUseCase
    implements UseCase<AppUser, ({String email, String password})> {
  SignUpUseCase(this._repository, this._analytics);

  final AuthRepository _repository;
  final AnalyticsService _analytics;

  @override
  Future<Result<AppUser>> call(({String email, String password}) params) async {
    final result = await _repository.signUp(
      email: params.email,
      password: params.password,
    );
    if (result is Ok) {
      unawaited(_analytics.logEvent(const AnalyticsEvent.signedUp()));
    }
    return result;
  }
}
