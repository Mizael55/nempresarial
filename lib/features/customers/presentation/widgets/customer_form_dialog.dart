import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/customers_controller.dart';
import '../../domain/models/customer_model.dart';

class CustomerFormDialog extends ConsumerStatefulWidget {
  final CustomerModel? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _taxIdController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _addressController;
  late TextEditingController _creditLimitController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _taxIdController = TextEditingController(text: c?.taxId ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _whatsappController = TextEditingController(text: c?.whatsapp ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _creditLimitController = TextEditingController(
      text: c != null && c.creditLimit > 0 ? c.creditLimit.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final creditLimit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;

    setState(() => _isLoading = true);
    try {
      if (isEditing) {
        final updated = widget.customer!.copyWith(
          name: _nameController.text.trim(),
          taxId: _taxIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
          address: _addressController.text.trim(),
          creditLimit: creditLimit,
          notes: _notesController.text.trim(),
        );
        await ref.read(customersListProvider.notifier).updateCustomer(updated);
      } else {
        final newCustomer = CustomerModel(
          id: '',
          name: _nameController.text.trim(),
          taxId: _taxIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
          address: _addressController.text.trim(),
          creditLimit: creditLimit,
          notes: _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await ref.read(customersListProvider.notifier).addCustomer(newCustomer);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cliente: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Text(
                        isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  NubikoTextField(
                    controller: _nameController,
                    label: 'Nombre Completo / Razón Social *',
                    hintText: 'Ej. Juan Pérez o Comercial Gómez S.R.L.',
                    prefixIcon: const Icon(LucideIcons.user, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: NubikoTextField(
                          controller: _taxIdController,
                          label: 'RNC / Cédula Fiscal',
                          hintText: 'Ej. 402-0000000-0',
                          prefixIcon: const Icon(LucideIcons.idCard, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NubikoTextField(
                          controller: _creditLimitController,
                          label: 'Límite de Crédito (RD\$)',
                          hintText: '0.00 (Sin límite)',
                          prefixIcon: const Icon(LucideIcons.dollarSign, size: 18),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: NubikoTextField(
                          controller: _phoneController,
                          label: 'Teléfono',
                          hintText: '809-555-1234',
                          prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NubikoTextField(
                          controller: _whatsappController,
                          label: 'WhatsApp',
                          hintText: '829-555-5678',
                          prefixIcon: const Icon(LucideIcons.messageCircle, size: 18),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  NubikoTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    hintText: 'cliente@ejemplo.com',
                    prefixIcon: const Icon(LucideIcons.mail, size: 18),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  NubikoTextField(
                    controller: _addressController,
                    label: 'Dirección de Entrega / Facturación',
                    hintText: 'Calle Principal #12, Santo Domingo',
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                  ),
                  const SizedBox(height: 14),

                  NubikoTextField(
                    controller: _notesController,
                    label: 'Notas del Cliente',
                    hintText: 'Horario de entrega preferido, preferencias...',
                    maxLines: 2,
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
                        text: isEditing ? 'Guardar Cambios' : 'Registrar Cliente',
                        icon: LucideIcons.save,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ],
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
