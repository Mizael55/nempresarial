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
import '../../data/purchases_repository_impl.dart';
import '../../domain/models/purchase_model.dart';

class PurchaseDetailDialog extends ConsumerStatefulWidget {
  final PurchaseModel purchase;

  const PurchaseDetailDialog({super.key, required this.purchase});

  @override
  ConsumerState<PurchaseDetailDialog> createState() => _PurchaseDetailDialogState();
}

class _PurchaseDetailDialogState extends ConsumerState<PurchaseDetailDialog> {
  late Future<PurchaseModel> _loadDetailsFuture;
  final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadDetailsFuture = ref.read(purchasesRepositoryProvider).getPurchaseById(widget.purchase.id);
  }

  void _confirmVoid(PurchaseModel purchase) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            const Text('Anular Orden de Compra'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción restará del inventario todos los artículos recibidos en la compra ${purchase.purchaseNumber} y ajustará el balance con el proveedor.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 14),
            NubikoTextField(
              controller: reasonController,
              label: 'Motivo de anulación *',
              hintText: 'Ej. Error en facturación del proveedor, mercancía devuelta',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                await ref.read(purchasesListProvider.notifier).voidPurchase(purchase.id, reason);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Compra ${purchase.purchaseNumber} anulada y stock descontado'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al anular: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Confirmar Anulación'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<PurchaseModel>(
            future: _loadDetailsFuture,
            initialData: widget.purchase,
            builder: (context, snapshot) {
              final purchase = snapshot.data ?? widget.purchase;
              final isCancelled = purchase.status == 'cancelled';
              final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(purchase.createdAt);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: const Icon(LucideIcons.fileSpreadsheet, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Compra ${purchase.purchaseNumber}',
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isCancelled ? AppColors.error : AppColors.success).withValues(alpha: 0.12),
                                    borderRadius: AppRadius.roundedSm,
                                  ),
                                  child: Text(
                                    isCancelled ? 'ANULADA' : 'RECIBIDA',
                                    style: TextStyle(
                                      color: isCancelled ? AppColors.error : AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text('Registrada el $dateFormatted', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Información del Proveedor y Pago
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: AppRadius.roundedLg,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PROVEEDOR', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(purchase.supplierName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              if (purchase.supplierTaxId != null && purchase.supplierTaxId!.isNotEmpty)
                                Text('RNC: ${purchase.supplierTaxId}', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CONDICIONES DE PAGO', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Método: ${purchase.paymentMethod.toUpperCase()}', style: AppTypography.bodySmall),
                              Text(
                                'Estado: ${purchase.paymentStatus.toUpperCase()}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: purchase.isPendingPayment ? AppColors.warning : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SUCURSAL & USUARIO', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(purchase.branchName, style: AppTypography.bodySmall),
                              Text('Por: ${purchase.purchaserName}', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tabla de Artículos Recibidos
                  Text('Artículos Recibidos (${purchase.items.length})',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: AppRadius.roundedLg,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: purchase.items.isEmpty
                          ? const Center(child: Text('Sin artículos detallados'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              itemCount: purchase.items.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 12,
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                              itemBuilder: (context, index) {
                                final item = purchase.items[index];
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(item.productName, style: AppTypography.bodyMedium),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'x${item.quantity.toStringAsFixed(0)}',
                                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        currencyFormat.format(item.unitCost),
                                        style: AppTypography.bodySmall,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        currencyFormat.format(item.totalAmount),
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resumen de Totales
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: AppRadius.roundedLg,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal:', style: AppTypography.bodySmall),
                            Text(currencyFormat.format(purchase.subtotal), style: AppTypography.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Impuestos (ITBIS):', style: AppTypography.bodySmall),
                            Text(currencyFormat.format(purchase.taxAmount), style: AppTypography.bodySmall),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL ORDEN:', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              currencyFormat.format(purchase.totalAmount),
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCancelled)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () => _confirmVoid(purchase),
                          icon: const Icon(LucideIcons.ban, size: 16),
                          label: const Text('Anular Compra'),
                        )
                      else
                        const SizedBox(),
                      NubikoButton(
                        text: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
