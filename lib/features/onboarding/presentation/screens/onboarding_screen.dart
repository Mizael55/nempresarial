import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../domain/business_settings_model.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _businessType = 'retail';

  String _currencyCode = 'DOP';
  String _currencySymbol = 'RD\$';
  final _taxNameController = TextEditingController(text: 'ITBIS');
  final _taxRateController = TextEditingController(text: '18');

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxNameController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _submitStep1() {
    if (!_step1FormKey.currentState!.validate()) return;
    ref.read(onboardingControllerProvider.notifier).updateSettings(
          BusinessSettingsModel(
            businessName: _businessNameController.text.trim(),
            taxId: _taxIdController.text.trim(),
            businessType: _businessType,
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            currencyCode: _currencyCode,
            currencySymbol: _currencySymbol,
            taxName: _taxNameController.text.trim(),
            taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
          ),
        );
    ref.read(onboardingControllerProvider.notifier).nextStep();
  }

  Future<void> _submitStep2() async {
    if (!_step2FormKey.currentState!.validate()) return;
    final prev = ref.read(onboardingControllerProvider).settings;
    final updated = BusinessSettingsModel(
      businessName: _businessNameController.text.trim().isNotEmpty
          ? _businessNameController.text.trim()
          : prev.businessName,
      taxId: _taxIdController.text.trim().isNotEmpty ? _taxIdController.text.trim() : prev.taxId,
      businessType: _businessType,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : prev.phone,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : prev.address,
      currencyCode: _currencyCode,
      currencySymbol: _currencySymbol,
      taxName: _taxNameController.text.trim().isNotEmpty ? _taxNameController.text.trim() : 'ITBIS',
      taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
      onboardingCompleted: true,
    );
    ref.read(onboardingControllerProvider.notifier).updateSettings(updated);
    final success = await ref.read(onboardingControllerProvider.notifier).finishOnboarding();
    if (success && mounted) {
      ref.read(onboardingControllerProvider.notifier).nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Progress Stepper
                _buildStepper(state.currentStep, isDark),
                const SizedBox(height: 32),

                // Card Container with dynamic step
                NubikoCard(
                  padding: const EdgeInsets.all(32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: switch (state.currentStep) {
                      0 => _buildStep1(isDark),
                      1 => _buildStep2(isDark, state.isLoading),
                      _ => _buildStep3Success(isDark),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(int currentStep, bool isDark) {
    final steps = ['Negocio', 'Impuestos y Moneda', 'Listo'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.primary600
                    : (isDark ? AppColors.slate800 : AppColors.slate200),
                border: isCurrent
                    ? Border.all(color: AppColors.primary400, width: 2)
                    : null,
              ),
              child: Center(
                child: isActive && index < currentStep
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive ? Colors.white : AppColors.slate500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              steps[index],
              style: AppTypography.labelMedium.copyWith(
                color: isCurrent
                    ? (isDark ? Colors.white : AppColors.slate900)
                    : (isDark ? AppColors.slate500 : AppColors.slate400),
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (index < steps.length - 1) ...[
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 2,
                color: index < currentStep
                    ? AppColors.primary600
                    : (isDark ? AppColors.slate800 : AppColors.slate200),
              ),
              const SizedBox(width: 12),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildStep1(bool isDark) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withOpacity(0.12),
                  borderRadius: AppRadius.roundedMd,
                ),
                child: const Center(
                  child: Icon(LucideIcons.store, color: AppColors.primary500, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configura tu Negocio',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Paso 1 de 2: Información general de tu empresa',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          NubikoTextField(
            label: 'Nombre Comercial del Negocio *',
            hint: 'Ej. Supermercado El Éxito',
            controller: _businessNameController,
            prefixIcon: const Icon(LucideIcons.briefcase, size: 18),
            validator: (v) => Validators.required(v, 'El nombre es obligatorio'),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: NubikoTextField(
                  label: 'RNC / Identificación Fiscal',
                  hint: '131-00000-0',
                  controller: _taxIdController,
                  prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NubikoTextField(
                  label: 'Teléfono Principal',
                  hint: '+1 (809) 000-0000',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(LucideIcons.phone, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          NubikoTextField(
            label: 'Dirección Física',
            hint: 'Calle Principal #123, Sector...',
            controller: _addressController,
            prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
          ),
          const SizedBox(height: 20),

          // Business Type Selector
          Text(
            'Tipo de Negocio',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeRadio('Comercio / Tienda', 'retail', LucideIcons.shoppingBag),
              const SizedBox(width: 12),
              _buildTypeRadio('Servicios', 'services', LucideIcons.wrench),
              const SizedBox(width: 12),
              _buildTypeRadio('Restaurante / Bar', 'food', LucideIcons.coffee),
            ],
          ),
          const SizedBox(height: 28),

          NubikoButton(
            text: 'Continuar a Configuración Financiera',
            isFullWidth: true,
            trailingIcon: LucideIcons.arrowRight,
            onPressed: _submitStep1,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRadio(String label, String value, IconData icon) {
    final isSelected = _businessType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _businessType = value),
        borderRadius: AppRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary500.withOpacity(0.12)
                : (isDark ? AppColors.slate900 : Colors.white),
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary500
                  : (isDark ? AppColors.slate700 : AppColors.slate300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary500 : AppColors.slate500,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary600)
                      : (isDark ? AppColors.slate400 : AppColors.slate600),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDark, bool isLoading) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withOpacity(0.12),
                  borderRadius: AppRadius.roundedMd,
                ),
                child: const Center(
                  child: Icon(LucideIcons.coins, color: AppColors.emerald500, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moneda e Impuestos',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Paso 2 de 2: Establece los parámetros de facturación',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Currency selector
          Text(
            'Moneda Principal de Operación',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCurrencyOption('DOP', 'RD\$', 'Peso Dominicano'),
              const SizedBox(width: 12),
              _buildCurrencyOption('USD', '\$', 'Dólar Estadounidense'),
              const SizedBox(width: 12),
              _buildCurrencyOption('EUR', '€', 'Euro'),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: NubikoTextField(
                  label: 'Nombre del Impuesto',
                  hint: 'ITBIS, IVA, Tax',
                  controller: _taxNameController,
                  prefixIcon: const Icon(LucideIcons.receipt, size: 18),
                  validator: (v) => Validators.required(v, 'Requerido'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NubikoTextField(
                  label: 'Tasa Porcentual (%)',
                  hint: '18',
                  controller: _taxRateController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(LucideIcons.percent, size: 18),
                  validator: (v) => Validators.number(v, 'Ingresa un número'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: NubikoButton(
                  text: 'Atrás',
                  variant: NubikoButtonVariant.outline,
                  onPressed: () =>
                      ref.read(onboardingControllerProvider.notifier).previousStep(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: NubikoButton(
                  text: 'Guardar y Finalizar',
                  isLoading: isLoading,
                  icon: LucideIcons.checkCheck,
                  onPressed: _submitStep2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String symbol, String name) {
    final isSelected = _currencyCode == code;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currencyCode = code;
            _currencySymbol = symbol;
          });
        },
        borderRadius: AppRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.emerald500.withOpacity(0.12)
                : (isDark ? AppColors.slate900 : Colors.white),
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.emerald500
                  : (isDark ? AppColors.slate700 : AppColors.slate300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                symbol,
                style: AppTypography.titleLarge.copyWith(
                  color: isSelected ? AppColors.emerald500 : AppColors.slate500,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3Success(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.emerald500.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(LucideIcons.checkCheck, size: 44, color: AppColors.emerald500),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          '¡Tu negocio está listo!',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'La base de datos y la instancia han sido configuradas exitosamente. Puedes comenzar a registrar productos, ventas y gestionar tu inventario ahora.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.slate400 : AppColors.slate600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 32),
        NubikoButton(
          text: 'Ir al Panel Principal (Dashboard)',
          icon: LucideIcons.layoutDashboard,
          isFullWidth: true,
          onPressed: () => context.go('/dashboard'),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
