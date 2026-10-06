import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../onboarding/domain/business_settings_model.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../setup/presentation/controllers/storage_setup_controller.dart';
import '../../../setup/presentation/widgets/supabase_connection_dialog.dart';
import '../../../../core/storage/local_database_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _taxNameController;
  late TextEditingController _taxRateController;
  String _businessType = 'retail';
  String _currencyCode = 'DOP';
  String _currencySymbol = 'RD\$';
  bool _taxEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(onboardingControllerProvider).settings;
    _businessNameController = TextEditingController(text: settings.businessName);
    _taxIdController = TextEditingController(text: settings.taxId);
    _phoneController = TextEditingController(text: settings.phone);
    _addressController = TextEditingController(text: settings.address);
    _taxNameController = TextEditingController(text: settings.taxName.isNotEmpty ? settings.taxName : 'ITBIS');
    _taxRateController = TextEditingController(text: settings.taxRate.toStringAsFixed(settings.taxRate % 1 == 0 ? 0 : 2));
    _taxEnabled = settings.taxRate > 0;
    _businessType = settings.businessType.isNotEmpty ? settings.businessType : 'retail';
    _currencyCode = settings.currencyCode.isNotEmpty ? settings.currencyCode : 'DOP';
    _currencySymbol = settings.currencySymbol.isNotEmpty ? settings.currencySymbol : 'RD\$';
  }

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

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final double inputRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    final double finalRate = (_taxEnabled && inputRate > 0) ? inputRate : 0.0;

    final updated = BusinessSettingsModel(
      businessName: _businessNameController.text.trim(),
      taxId: _taxIdController.text.trim(),
      businessType: _businessType,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      currencyCode: _currencyCode,
      currencySymbol: _currencySymbol,
      taxName: _taxNameController.text.trim().isNotEmpty ? _taxNameController.text.trim() : 'ITBIS',
      taxRate: finalRate,
      onboardingCompleted: true,
    );

    ref.read(onboardingControllerProvider.notifier).updateSettings(updated);
    final success = await ref.read(onboardingControllerProvider.notifier).finishOnboarding();

    if (success) {
      ref.read(posControllerProvider.notifier).syncCartTaxWithSettings();
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración del negocio guardada exitosamente.'),
            backgroundColor: AppColors.emerald600,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la configuración.'),
            backgroundColor: AppColors.rose600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withValues(alpha: 0.12),
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: const Icon(LucideIcons.settings, color: AppColors.primary500, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Configuración del Sistema', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text('Perfil del negocio, facturación y preferencias', style: AppTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Card 1: Perfil de la Empresa
                  NubikoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.store, size: 20, color: AppColors.primary500),
                            const SizedBox(width: 10),
                            Text('Perfil Comercial de la Empresa', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        NubikoTextField(
                          label: 'Nombre Comercial *',
                          controller: _businessNameController,
                          prefixIcon: const Icon(LucideIcons.building, size: 18),
                          validator: (v) => Validators.required(v, 'El nombre es obligatorio'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: NubikoTextField(
                                label: 'RNC / Identificación Fiscal',
                                controller: _taxIdController,
                                prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: NubikoTextField(
                                label: 'Teléfono',
                                controller: _phoneController,
                                prefixIcon: const Icon(LucideIcons.phone, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        NubikoTextField(
                          label: 'Dirección Comercial',
                          controller: _addressController,
                          prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card 2: Moneda e Impuestos
                  NubikoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.coins, size: 20, color: AppColors.emerald500),
                            const SizedBox(width: 10),
                            Text('Moneda e Impuestos (ITBIS / Facturación)', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _currencyCode,
                                decoration: const InputDecoration(
                                  labelText: 'Moneda de Operación',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'DOP', child: Text('DOP - Peso Dominicano (RD\$)')),
                                  DropdownMenuItem(value: 'USD', child: Text('USD - Dólar Estadounidense (\$)')),
                                  DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro (€)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _currencyCode = val;
                                      _currencySymbol = val == 'DOP' ? 'RD\$' : (val == 'USD' ? '\$' : '€');
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Habilitar cobro de ITBIS / Impuestos en Ventas', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            _taxEnabled
                                ? 'El impuesto configurado se aplicará en el catálogo y facturación POS.'
                                : 'Impuestos desactivados (0%). Todas las ventas y productos operarán exentos de ITBIS.',
                            style: AppTypography.bodySmall,
                          ),
                          value: _taxEnabled,
                          activeColor: AppColors.emerald500,
                          onChanged: (val) {
                            setState(() {
                              _taxEnabled = val;
                              if (!val) {
                                _taxRateController.text = '0';
                              } else {
                                if (_taxRateController.text == '0' || _taxRateController.text.isEmpty) {
                                  _taxRateController.text = '18';
                                }
                              }
                            });
                          },
                        ),
                        if (_taxEnabled) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: NubikoTextField(
                                  label: 'Nombre del Impuesto',
                                  hint: 'ITBIS, IVA, Tax',
                                  controller: _taxNameController,
                                  prefixIcon: const Icon(LucideIcons.tag, size: 18),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 1,
                                child: NubikoTextField(
                                  label: 'Tasa %',
                                  hint: '18',
                                  controller: _taxRateController,
                                  prefixIcon: const Icon(LucideIcons.percent, size: 18),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card 3: Preferencias y Usuario Activo
                  NubikoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.user, size: 20, color: AppColors.primary500),
                            const SizedBox(width: 10),
                            Text('Usuario de Acceso & Apariencia', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(user?.fullName ?? 'Administrador General', style: AppTypography.titleSmall),
                          subtitle: Text(user?.email ?? 'admin@empresa.com', style: AppTypography.bodySmall),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withValues(alpha: 0.12),
                              borderRadius: AppRadius.roundedFull,
                            ),
                            child: const Text('Super Admin', style: TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Modo Oscuro', style: AppTypography.labelLarge),
                                Text('Cambiar la apariencia de la interfaz', style: AppTypography.bodySmall),
                              ],
                            ),
                            Switch(
                              value: themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark),
                              onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card 4: Almacenamiento y Base de Datos (Local vs Nube)
                  Consumer(
                    builder: (context, ref, _) {
                      final storageState = ref.watch(storageSetupControllerProvider);
                      final isLocal = storageState.storageMode == 'local';

                      return NubikoCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isLocal ? LucideIcons.hardDrive : LucideIcons.cloud,
                                      size: 20,
                                      color: isLocal ? AppColors.emerald500 : AppColors.primary500,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Almacenamiento & Base de Datos',
                                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLocal
                                        ? AppColors.emerald500.withValues(alpha: 0.12)
                                        : AppColors.primary500.withValues(alpha: 0.12),
                                    borderRadius: AppRadius.roundedFull,
                                    border: Border.all(
                                      color: isLocal
                                          ? AppColors.emerald500.withValues(alpha: 0.3)
                                          : AppColors.primary500.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    isLocal ? 'MODO LOCAL (PC)' : 'NUBE (SUPABASE)',
                                    style: TextStyle(
                                      color: isLocal ? AppColors.emerald500 : AppColors.primary500,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isLocal
                                  ? 'Todos los datos de tu empresa (productos, ventas, inventario, gastos) se guardan en el disco de tu computadora. Trabajas 100% sin internet.'
                                  : 'Conectado a la nube mediante Supabase en ${storageState.supabaseUrl}. Tus datos se sincronizan en PostgreSQL en tiempo real.',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.slate400 : AppColors.slate600,
                                height: 1.4,
                              ),
                            ),
                            const Divider(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                if (isLocal) ...[
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => const SupabaseConnectionDialog(),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.cloudLightning, size: 16),
                                    label: const Text('Conectar a Supabase (Nube)'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary500,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('¿Limpiar datos de prueba?'),
                                          content: const Text(
                                            'Esto eliminará productos, ventas y gastos de prueba en la base de datos local, dejando únicamente el usuario administrador.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(localDatabaseServiceProvider).resetAllData(keepAdminUser: true);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Datos de prueba limpiados. Usuario administrador conservado.'),
                                              backgroundColor: AppColors.emerald600,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(LucideIcons.trash2, size: 16),
                                    label: const Text('Limpiar Datos de Prueba'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.rose500,
                                    ),
                                  ),
                                ] else ...[
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => const SupabaseConnectionDialog(),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.settings2, size: 16),
                                    label: const Text('Reconfigurar Supabase'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await ref.read(storageSetupControllerProvider.notifier).switchMode('local');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cambiado a Modo Local (PC).'),
                                            backgroundColor: AppColors.emerald600,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(LucideIcons.hardDrive, size: 16),
                                    label: const Text('Cambiar a Modo Local (PC)'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Botón Guardar
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 220,
                      child: NubikoButton(
                        text: 'Guardar Configuración',
                        icon: LucideIcons.save,
                        isLoading: _isSaving,
                        onPressed: _saveSettings,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
