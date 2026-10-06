import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/purchases_controller.dart';
import '../../domain/models/supplier_model.dart';

class SupplierFormDialog extends ConsumerStatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormDialog({super.key, this.supplier});

  @override
  ConsumerState<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends ConsumerState<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _taxIdController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  bool get isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameController = TextEditingController(text: s?.name ?? '');
    _contactController = TextEditingController(text: s?.contactName ?? '');
    _taxIdController = TextEditingController(text: s?.taxId ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (isEditing) {
        final updated = widget.supplier!.copyWith(
          name: _nameController.text.trim(),
          contactName: _contactController.text.trim(),
          taxId: _taxIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
        );
        await ref.read(suppliersListProvider.notifier).updateSupplier(updated);
      } else {
        final newSupplier = SupplierModel(
          id: '',
          name: _nameController.text.trim(),
          contactName: _contactController.text.trim(),
          taxId: _taxIdController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await ref.read(suppliersListProvider.notifier).addSupplier(newSupplier);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar proveedor: $e'), backgroundColor: AppColors.error),
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
                        child: const Icon(LucideIcons.building, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
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
                    label: 'Razón Social / Nombre Comercial *',
                    hintText: 'Ej. Distribuidora Nacional S.R.L.',
                    prefixIcon: const Icon(LucideIcons.briefcase, size: 18),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: NubikoTextField(
                          controller: _taxIdController,
                          label: 'RNC / Cédula Fiscal',
                          hintText: 'Ej. 1-31-00000-0',
                          prefixIcon: const Icon(LucideIcons.idCard, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NubikoTextField(
                          controller: _contactController,
                          label: 'Persona de Contacto',
                          hintText: 'Ej. Carlos Martínez',
                          prefixIcon: const Icon(LucideIcons.user, size: 18),
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
                          hintText: 'Ej. 809-555-0101',
                          prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NubikoTextField(
                          controller: _emailController,
                          label: 'Correo Electrónico',
                          hintText: 'ventas@distribuidora.com',
                          prefixIcon: const Icon(LucideIcons.mail, size: 18),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  NubikoTextField(
                    controller: _addressController,
                    label: 'Dirección Comercial',
                    hintText: 'Av. Las Palmas #45, Edif. Central',
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                  ),
                  const SizedBox(height: 14),

                  NubikoTextField(
                    controller: _notesController,
                    label: 'Notas / Observaciones',
                    hintText: 'Términos de crédito 30 días, flete incluido...',
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
                        text: isEditing ? 'Guardar Cambios' : 'Registrar Proveedor',
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
