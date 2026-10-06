import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../controllers/customers_controller.dart';
import '../../domain/models/customer_model.dart';
import 'customer_payment_dialog.dart';

class CustomerStatementDialog extends ConsumerWidget {
  final CustomerModel customer;

  const CustomerStatementDialog({super.key, required this.customer});

  void _openPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => CustomerPaymentDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statementAsync = ref.watch(customerStatementProvider(customer.id));
    final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                        Text('Estado de Cuenta (Kardex de Cobro)',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${customer.name} ${customer.taxId != null ? "• RNC: ${customer.taxId}" : ""}',
                          style: AppTypography.bodySmall,
                        ),
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

              // Tarjetas de Resumen
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Límite Autorizado', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            customer.creditLimit > 0
                                ? currencyFormat.format(customer.creditLimit)
                                : 'Sin Límite',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deuda Pendiente (CXC)', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(customer.currentBalance),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: customer.hasDebt ? AppColors.warning : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (customer.hasDebt)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openPaymentDialog(context);
                        },
                        icon: const Icon(LucideIcons.handCoins, size: 16),
                        label: const Text('Registrar Cobro'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Historial de Movimientos
              Text('Movimientos y Facturación',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
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
                  child: statementAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.fileCheck2, size: 36, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text('Sin transacciones a crédito registradas', style: AppTypography.bodySmall),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 12,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(item.date);

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (item.isSale ? AppColors.primary : AppColors.success)
                                      .withValues(alpha: 0.1),
                                  borderRadius: AppRadius.roundedSm,
                                ),
                                child: Icon(
                                  item.isSale ? LucideIcons.fileText : LucideIcons.arrowDownLeft,
                                  color: item.isSale ? AppColors.primary : AppColors.success,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.documentNumber,
                                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text('$dateStr • ${item.description}', style: AppTypography.bodySmall),
                                  ],
                                ),
                              ),
                              // Cargo (Débito)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Cargo', style: AppTypography.bodySmall),
                                    Text(
                                      item.debit > 0 ? currencyFormat.format(item.debit) : '-',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: item.debit > 0 ? AppColors.error : null,
                                        fontWeight: item.debit > 0 ? FontWeight.bold : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Abono (Crédito)
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Abono', style: AppTypography.bodySmall),
                                    Text(
                                      item.credit > 0 ? currencyFormat.format(item.credit) : '-',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: item.credit > 0 ? AppColors.success : null,
                                        fontWeight: item.credit > 0 ? FontWeight.bold : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Saldo Progresivo
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Saldo', style: AppTypography.bodySmall),
                                    Text(
                                      currencyFormat.format(item.runningBalance),
                                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error al cargar estado: $err')),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NubikoButton(
                    text: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
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
