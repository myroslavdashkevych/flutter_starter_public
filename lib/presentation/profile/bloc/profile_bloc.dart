import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_event.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._watchAuthState, this._signOutUseCase, this._deleteAccount)
    : super(const ProfileState()) {
    on<ProfileStarted>(
      (event, emit) => emit.forEach(
        _watchAuthState(()),
        onData: (user) => state.copyWith(user: user, isAuthKnown: true),
      ),
      transformer: restartable(),
    );
    on<ProfileAction>(
      (event, emit) => switch (event) {
        ProfileSignOutRequested() => _signOut(emit),
        ProfileDeleteRequested(:final password) => _delete(password, emit),
      },
      transformer: droppable(),
    );
    add(const ProfileStarted());
  }

  final WatchAuthStateUseCase _watchAuthState;
  final SignOutUseCase _signOutUseCase;
  final DeleteAccountUseCase _deleteAccount;

  Future<void> _signOut(Emitter<ProfileState> emit) async {
    emit(state.copyWith(signOutFailure: null));
    final result = await _signOutUseCase(());
    if (result case Err(:final failure)) {
      emit(state.copyWith(signOutFailure: failure));
    }
  }

  Future<void> _delete(String password, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isDeleting: true, deleteFailure: null));
    final result = await _deleteAccount((password: password));
    emit(
      state.copyWith(
        isDeleting: false,
        deleteFailure: switch (result) {
          Ok() => null,
          Err(:final failure) => failure,
        },
      ),
    );
  }
}
