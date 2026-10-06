import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/expenses_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({super.key});

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a 0'),
          backgroundColor: AppColors.rose500,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(expensesControllerProvider.notifier).createExpense(
      concept: _conceptController.text,
      amount: amount,
      paymentMethod: _paymentMethod,
      categoryId: _selectedCategoryId,
      reference: _referenceController.text,
      notes: _notesController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Actualizar métricas del dashboard en tiempo real
        ref.read(dashboardControllerProvider.notifier).loadMetrics();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto registrado con éxito'),
            backgroundColor: AppColors.emerald500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expState = ref.watch(expensesControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: NubikoCard(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.12),
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: const Icon(LucideIcons.receipt, color: AppColors.rose500, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar Gasto Operativo',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Ingresa el egreso para mantener al día tus ganancias netas',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.slate400 : AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Concepto
                  NubikoTextField(
                    label: 'Concepto / Descripción del Gasto *',
                    controller: _conceptController,
                    hintText: 'Ej. Factura eléctrica, Alquiler del local, Compra de café',
                    prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Ingresa el concepto del gasto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Monto & Categoría
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: NubikoTextField(
                          label: 'Monto a Pagar (RD\$) *',
                          controller: _amountController,
                          hintText: '0.00',
                          prefixIcon: const Icon(LucideIcons.dollarSign, size: 18),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Requerido';
                            final parsed = double.tryParse(val.replaceAll(',', '.'));
                            if (parsed == null || parsed <= 0) return 'Monto inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Categoría', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.slate800 : AppColors.slate50,
                                borderRadius: AppRadius.roundedMd,
                                border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategoryId,
                                  isExpanded: true,
                                  hint: const Text('Seleccionar...'),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Otros Gastos / General'),
                                    ),
                                    ...expState.categories.map((c) {
                                      return DropdownMenuItem<String>(
                                        value: c.id,
                                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _selectedCategoryId = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Método de Pago
                  Text('Método de Pago', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildPaymentChip('cash', 'Efectivo', LucideIcons.banknote, isDark),
                      const SizedBox(width: 8),
                      _buildPaymentChip('transfer', 'Transferencia', LucideIcons.arrowRightLeft, isDark),
                      const SizedBox(width: 8),
                      _buildPaymentChip('credit_card', 'Tarjeta', LucideIcons.creditCard, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Referencia / Comprobante
                  NubikoTextField(
                    label: 'Referencia / No. Comprobante (Opcional)',
                    controller: _referenceController,
                    hintText: 'Ej. Cheque #4920, Transf #992834, Factura B01',
                    prefixIcon: const Icon(LucideIcons.hash, size: 18),
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  NubikoTextField(
                    label: 'Notas Adicionales (Opcional)',
                    controller: _notesController,
                    hintText: 'Observaciones sobre el pago...',
                    maxLines: 2,
                    prefixIcon: const Icon(LucideIcons.alignLeft, size: 18),
                  ),
                  const SizedBox(height: 24),

                  // Footer Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      NubikoButton(
                        text: _isLoading ? 'Guardando...' : 'Guardar Gasto',
                        icon: LucideIcons.check,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleSave,
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

  Widget _buildPaymentChip(String value, String label, IconData icon, bool isDark) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        borderRadius: AppRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary500.withValues(alpha: 0.12)
                : (isDark ? AppColors.slate800 : AppColors.slate50),
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary500
                  : (isDark ? AppColors.slate700 : AppColors.slate200),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary500
                    : (isDark ? AppColors.slate400 : AppColors.slate600),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary500
                        : (isDark ? Colors.white : AppColors.slate800),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
