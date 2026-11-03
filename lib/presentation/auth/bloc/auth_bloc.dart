import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_state.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthRepository repository) : super(const AuthState.unknown()) {
    on<AuthUserChanged>((event, emit) => emit(_stateFor(event.user)));
    _subscription = repository.authStateChanges().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  late final StreamSubscription<AppUser?> _subscription;

  AuthState _stateFor(AppUser? user) => user == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(user);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
