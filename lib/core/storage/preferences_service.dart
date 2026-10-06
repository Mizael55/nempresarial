import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesService {
  static const String _kOnboardingCompletedKey = 'onboarding_completed_flag';
  static const String _kActiveBranchKey = 'active_branch_id';

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompletedKey, value);
  }

  Future<String?> getActiveBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveBranchKey);
  }

  Future<void> setActiveBranchId(String branchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveBranchKey, branchId);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});
