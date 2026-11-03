import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';

extension FirebaseUserMapper on User {
  AppUser toEntity() => AppUser(id: uid, email: email);
}

AuthFailureReason authFailureReasonFromCode(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => AuthFailureReason.invalidCredentials,
  'email-already-in-use' => AuthFailureReason.emailAlreadyInUse,
  'weak-password' => AuthFailureReason.weakPassword,
  'invalid-email' => AuthFailureReason.invalidEmail,
  'user-disabled' => AuthFailureReason.userDisabled,
  'too-many-requests' => AuthFailureReason.tooManyRequests,
  'requires-recent-login' => AuthFailureReason.requiresRecentLogin,
  'network-request-failed' => AuthFailureReason.network,
  _ => AuthFailureReason.unknown,
};
