import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/auth/usecases/delete_account_use_case.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, this._deleteAccount)
    : super(const ProfileState()) {
    _subscription = _repository.authStateChanges().listen(
      (user) => emit(state.copyWith(user: user, isAuthKnown: true)),
    );
  }

  final AuthRepository _repository;
  final DeleteAccountUseCase _deleteAccount;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> signOut() async {
    emit(state.copyWith(signOutFailure: null));
    final result = await _repository.signOut();
    if (isClosed) return;
    if (result case Err(:final failure)) {
      emit(state.copyWith(signOutFailure: failure));
    }
  }

  Future<void> deleteAccount({required String password}) async {
    emit(state.copyWith(isDeleting: true, deleteFailure: null));
    final result = await _deleteAccount(password: password);
    if (isClosed) return;
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

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
