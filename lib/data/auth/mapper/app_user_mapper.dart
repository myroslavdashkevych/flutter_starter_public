import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';

extension FirebaseUserMapper on User {
  AppUser toEntity() => AppUser(id: uid, email: email);
}
