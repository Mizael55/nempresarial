import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/storage/local_database_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../domain/business_settings_model.dart';

class OnboardingState {
  final int currentStep;
  final bool isLoading;
  final bool isCompleted;
  final String? errorMessage;
  final BusinessSettingsModel settings;

  const OnboardingState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isCompleted = false,
    this.errorMessage,
    this.settings = const BusinessSettingsModel(businessName: ''),
  });

  OnboardingState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isCompleted,
    String? errorMessage,
    BusinessSettingsModel? settings,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      settings: settings ?? this.settings,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  final PreferencesService _preferencesService;
  final LocalDatabaseService _localDb;

  OnboardingController(this._preferencesService, this._localDb) : super(const OnboardingState()) {
    checkBusinessProfileStatus();
  }

  Future<void> checkBusinessProfileStatus() async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        final res = await Supabase.instance.client
            .from('business_settings')
            .select('id, business_name, tax_id, business_type, phone, address, currency_code, currency_symbol, tax_rate, tax_name, onboarding_completed')
            .maybeSingle();

        if (res != null &&
            (res['onboarding_completed'] == true) &&
            (res['business_name'] != null && (res['business_name'] as String).trim().isNotEmpty)) {
          final settings = BusinessSettingsModel.fromJson(res);
          await _preferencesService.setOnboardingCompleted(true);
          state = state.copyWith(isCompleted: true, settings: settings);
          return;
        }
      }

      // Local Mode check
      await _localDb.ensureInitialized();
      final localSettings = await _localDb.query(LocalDatabaseService.tableBusinessSettings);
      if (localSettings.isNotEmpty) {
        final first = localSettings.first;
        if (first['business_name'] != null && (first['business_name'] as String).trim().isNotEmpty) {
          final settings = BusinessSettingsModel.fromJson(first);
          await _preferencesService.setOnboardingCompleted(true);
          state = state.copyWith(isCompleted: true, settings: settings);
          return;
        }
      }
    } catch (_) {}

    final completed = await _preferencesService.isOnboardingCompleted();
    state = state.copyWith(isCompleted: completed);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateSettings(BusinessSettingsModel updated) {
    state = state.copyWith(settings: updated);
  }

  Future<bool> finishOnboarding() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final mode = await _localDb.getStorageMode();
      final payload = state.settings.toJson();
      payload['onboarding_completed'] = true;

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final cloudPayload = Map<String, dynamic>.from(payload);
          cloudPayload.remove('id');

          final existing = await Supabase.instance.client
              .from('business_settings')
              .select('id')
              .maybeSingle();

          if (existing != null && existing['id'] != null) {
            await Supabase.instance.client
                .from('business_settings')
                .update(cloudPayload)
                .eq('id', existing['id']);
          } else {
            await Supabase.instance.client.from('business_settings').insert(cloudPayload);
          }
        } catch (_) {}
      }

      // Persist in LocalDatabaseService
      await _localDb.ensureInitialized();
      final existingLocal = await _localDb.query(LocalDatabaseService.tableBusinessSettings);
      if (existingLocal.isNotEmpty) {
        final id = existingLocal.first['id'] as String;
        await _localDb.update(LocalDatabaseService.tableBusinessSettings, id, payload);
      } else {
        await _localDb.insert(LocalDatabaseService.tableBusinessSettings, payload);
      }

      await _preferencesService.setOnboardingCompleted(true);
      state = state.copyWith(isLoading: false, isCompleted: true, currentStep: 2);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo guardar la configuración del negocio: $e',
      );
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final localDb = ref.watch(localDatabaseServiceProvider);
  return OnboardingController(prefs, localDb);
});
