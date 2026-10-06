import '../models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserProfile> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
