import 'dart:async';

import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:injectable/injectable.dart';

/// Requests a password reset email and sends the reset event when the request
/// succeeds (AUTH-8).
@injectable
class SendPasswordResetUseCase implements UseCase<void, ({String email})> {
  SendPasswordResetUseCase(this._repository, this._analytics);

  final AuthRepository _repository;
  final AnalyticsService _analytics;

  @override
  Future<Result<void>> call(({String email}) params) async {
    final result = await _repository.sendPasswordReset(email: params.email);
    if (result is Ok) {
      unawaited(
        _analytics.logEvent(const AnalyticsEvent.passwordResetRequested()),
      );
    }
    return result;
  }
}
