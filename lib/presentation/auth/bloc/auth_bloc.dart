import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_state.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._watchAuthState) : super(const AuthState.unknown()) {
    on<AuthSubscriptionRequested>(
      (event, emit) => emit.forEach(_watchAuthState(()), onData: _stateFor),
      transformer: restartable(),
    );
    add(const AuthSubscriptionRequested());
  }

  final WatchAuthStateUseCase _watchAuthState;

  AuthState _stateFor(AppUser? user) => user == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(user);
}
