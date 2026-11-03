import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    AppUser? user,
    @Default(false) bool isAuthKnown,
    @Default(false) bool isDeleting,
    Failure? deleteFailure,
    Failure? signOutFailure,
  }) = _ProfileState;
}
