import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../controllers/sales_controller.dart';
import 'sale_receipt_dialog.dart';

class PosCheckoutDialog extends ConsumerStatefulWidget {
  const PosCheckoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PosCheckoutDialog(),
    );
  }

  @override
  ConsumerState<PosCheckoutDialog> createState() => _PosCheckoutDialogState();
}

class _PosCheckoutDialogState extends ConsumerState<PosCheckoutDialog> {
  String _selectedMethod = 'cash'; // 'cash', 'credit_card', 'transfer', 'credit'
  final _receivedController = TextEditingController();
  final _notesController = TextEditingController();
  double _receivedAmount = 0.0;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final posState = ref.read(posControllerProvider);
    _receivedAmount = posState.totalWithDiscount;
    _receivedController.text = _receivedAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _receivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onReceivedChanged(String val) {
    final parsed = double.tryParse(val) ?? 0.0;
    setState(() {
      _receivedAmount = parsed;
    });
  }

  void _setPresetCash(double amount) {
    setState(() {
      _receivedAmount = amount;
      _receivedController.text = amount.toStringAsFixed(2);
    });
  }

  Future<void> _processPayment() async {
    final posState = ref.read(posControllerProvider);
    final total = posState.totalWithDiscount;

    if (_selectedMethod == 'cash' && _receivedAmount < total) {
      setState(() {
        _localError = 'El monto recibido no puede ser menor al total de la venta.';
      });
      return;
    }

    if (_selectedMethod == 'credit' && posState.selectedCustomer == null) {
      setState(() {
        _localError = 'Para vender a crédito debe seleccionar un cliente.';
      });
      return;
    }

    setState(() => _localError = null);

    final completedSale = await ref.read(posControllerProvider.notifier).checkout(
          paymentMethod: _selectedMethod,
          receivedAmount: _selectedMethod == 'cash' ? _receivedAmount : total,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

    if (completedSale != null && mounted) {
      Navigator.of(context).pop(); // Cierra Checkout Dialog
      SaleReceiptDialog.show(context, completedSale); // Abre comprobante de venta
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posState = ref.watch(posControllerProvider);
    final settings = ref.watch(onboardingControllerProvider).settings;
    final currency = settings.currencySymbol.isNotEmpty ? settings.currencySymbol : '\$';

    final total = posState.totalWithDiscount;
    final change = (_receivedAmount - total).clamp(0.0, double.infinity);

    final methods = [
      {'id': 'cash', 'label': 'Efectivo', 'icon': LucideIcons.banknote},
      {'id': 'credit_card', 'label': 'Tarjeta', 'icon': LucideIcons.creditCard},
      {'id': 'transfer', 'label': 'Transferencia', 'icon': LucideIcons.arrowRightLeft},
      {'id': 'credit', 'label': 'A Crédito', 'icon': LucideIcons.bookOpen},
    ];

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        child: const Icon(LucideIcons.badgeCheck, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cobro de Factura', style: AppTypography.titleLarge),
                          Text(
                            'Cliente: ${posState.selectedCustomer?.name ?? 'Consumidor Final'}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Destacado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.roundedLg,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total a Pagar:', style: AppTypography.titleMedium),
                    Text(
                      '$currency${total.toStringAsFixed(2)}',
                      style: AppTypography.displayMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Métodos de Pago Tabs
              Text('Selecciona Método de Pago', style: AppTypography.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: methods.map((m) {
                  final isSelected = _selectedMethod == m['id'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMethod = m['id'] as String;
                            if (_selectedMethod != 'cash') {
                              _receivedAmount = total;
                              _receivedController.text = total.toStringAsFixed(2);
                            }
                          });
                        },
                        borderRadius: AppRadius.roundedMd,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                m['icon'] as IconData,
                                size: 20,
                                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m['label'] as String,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Sección Específica si es Efectivo
              if (_selectedMethod == 'cash') ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: NubikoTextField(
                        controller: _receivedController,
                        labelText: 'Monto Recibido',
                        prefixText: '$currency ',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _onReceivedChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cambio / Devuelta', style: AppTypography.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '$currency${change.toStringAsFixed(2)}',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: change > 0 ? AppColors.success : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botones rápidos de efectivo
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Exacto'),
                      onPressed: () => _setPresetCash(total),
                    ),
                    ...[100.0, 200.0, 500.0, 1000.0, 2000.0]
                        .where((amt) => amt >= total || total == 0)
                        .take(4)
                        .map((amt) => ActionChip(
                              label: Text('$currency${amt.toStringAsFixed(0)}'),
                              onPressed: () => _setPresetCash(amt),
                            )),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Notas opcionales
              NubikoTextField(
                controller: _notesController,
                labelText: 'Notas / Referencia de Pago',
                hintText: 'Ej. No. Autorización o Comentario',
                prefixIcon: const Icon(LucideIcons.fileText, size: 18),
              ),
              const SizedBox(height: 12),

              if (_localError != null || posState.errorMessage != null)
                Container(
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
                          _localError ?? posState.errorMessage!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Botones de Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: posState.isProcessing ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  NubikoButton(
                    text: 'Confirmar Facturación',
                    icon: LucideIcons.check,
                    isLoading: posState.isProcessing,
                    onPressed: _processPayment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
