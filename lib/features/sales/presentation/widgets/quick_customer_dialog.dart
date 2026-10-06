import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/models/customer_model.dart';
import '../controllers/sales_controller.dart';

class QuickCustomerDialog extends ConsumerStatefulWidget {
  const QuickCustomerDialog({super.key});

  static Future<CustomerModel?> show(BuildContext context) {
    return showDialog<CustomerModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const QuickCustomerDialog(),
    );
  }

  @override
  ConsumerState<QuickCustomerDialog> createState() => _QuickCustomerDialogState();
}

class _QuickCustomerDialogState extends ConsumerState<QuickCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(salesRepositoryProvider);
      final customer = await repo.createCustomer(
        name: _nameController.text,
        taxId: _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
      );

      ref.invalidate(customersListProvider);

      if (mounted) {
        Navigator.of(context).pop(customer);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: AppRadius.roundedMd,
                          ),
                          child: const Icon(LucideIcons.userPlus, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Registrar Cliente Rápido', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.circleAlert, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                NubikoTextField(
                  controller: _nameController,
                  labelText: 'Nombre o Razón Social *',
                  hintText: 'Ej. Juan Pérez o Inversiones SRL',
                  prefixIcon: const Icon(LucideIcons.user, size: 18),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NubikoTextField(
                        controller: _taxIdController,
                        labelText: 'RNC / Cédula',
                        hintText: 'Ej. 131-00000-0',
                        prefixIcon: const Icon(LucideIcons.idCard, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NubikoTextField(
                        controller: _phoneController,
                        labelText: 'Teléfono / WhatsApp',
                        hintText: 'Ej. 809-555-0199',
                        prefixIcon: const Icon(LucideIcons.phone, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NubikoTextField(
                  controller: _emailController,
                  labelText: 'Correo Electrónico (Opcional)',
                  hintText: 'cliente@correo.com',
                  prefixIcon: const Icon(LucideIcons.mail, size: 18),
                ),
                const SizedBox(height: 12),
                NubikoTextField(
                  controller: _addressController,
                  labelText: 'Dirección (Opcional)',
                  hintText: 'Calle, Sector, Ciudad',
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    NubikoButton(
                      text: 'Guardar y Asignar',
                      icon: LucideIcons.check,
                      isLoading: _isSaving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
