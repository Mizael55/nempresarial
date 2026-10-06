import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/purchases_controller.dart';
import '../../domain/models/supplier_model.dart';

class SupplierPaymentDialog extends ConsumerStatefulWidget {
  final SupplierModel supplier;

  const SupplierPaymentDialog({super.key, required this.supplier});

  @override
  ConsumerState<SupplierPaymentDialog> createState() => _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState extends ConsumerState<SupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _refController;
  late TextEditingController _notesController;
  String _paymentMethod = 'transfer';
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.supplier.currentDebt > 0 ? widget.supplier.currentDebt.toStringAsFixed(2) : '',
    );
    _refController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(suppliersListProvider.notifier).recordPayment(
        supplierId: widget.supplier.id,
        amount: amount,
        paymentMethod: _paymentMethod,
        reference: _refController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago de ${currencyFormat.format(amount)} registrado a ${widget.supplier.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar pago: $e'), backgroundColor: AppColors.error),
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: const Icon(LucideIcons.banknote, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Abono a Cuenta por Pagar',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text(widget.supplier.name, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Balance actual adeudado
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: AppRadius.roundedLg,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deuda Pendiente Actual', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(widget.supplier.currentDebt),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.supplier.currentDebt > 0 ? AppColors.warning : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (widget.supplier.currentDebt > 0)
                        TextButton(
                          onPressed: () {
                            _amountController.text = widget.supplier.currentDebt.toStringAsFixed(2);
                          },
                          child: const Text('Pagar Totalidad'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                NubikoTextField(
                  controller: _amountController,
                  label: 'Monto a Pagar (RD\$) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(LucideIcons.dollarSign, size: 18),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Método de Pago
                Text('Método de Pago', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Transferencia'),
                      avatar: const Icon(LucideIcons.arrowRightLeft, size: 14),
                      selected: _paymentMethod == 'transfer',
                      onSelected: (val) => setState(() => _paymentMethod = 'transfer'),
                    ),
                    ChoiceChip(
                      label: const Text('Efectivo'),
                      avatar: const Icon(LucideIcons.banknote, size: 14),
                      selected: _paymentMethod == 'cash',
                      onSelected: (val) => setState(() => _paymentMethod = 'cash'),
                    ),
                    ChoiceChip(
                      label: const Text('Tarjeta / Cheque'),
                      avatar: const Icon(LucideIcons.creditCard, size: 14),
                      selected: _paymentMethod == 'card',
                      onSelected: (val) => setState(() => _paymentMethod = 'card'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                NubikoTextField(
                  controller: _refController,
                  label: 'Referencia Bancaria / # Cheque',
                  hintText: 'Ej. TRF-987654321',
                  prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                ),
                const SizedBox(height: 14),

                NubikoTextField(
                  controller: _notesController,
                  label: 'Observaciones / Motivo',
                  hintText: 'Pago parcial de factura de suministro...',
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    NubikoButton(
                      text: 'Confirmar Abono',
                      icon: LucideIcons.checkCircle,
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
    );
  }
}
