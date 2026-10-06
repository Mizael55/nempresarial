import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../controllers/customers_controller.dart';
import '../../domain/models/customer_model.dart';
import 'customer_form_dialog.dart';
import 'customer_payment_dialog.dart';
import 'customer_statement_dialog.dart';

class CustomersListView extends ConsumerWidget {
  const CustomersListView({super.key});

  void _openForm(BuildContext context, [CustomerModel? customer]) {
    showDialog(
      context: context,
      builder: (ctx) => CustomerFormDialog(customer: customer),
    );
  }

  void _openPayment(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => CustomerPaymentDialog(customer: customer),
    );
  }

  void _openStatement(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => CustomerStatementDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersAsync = ref.watch(customersListProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.users, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text('No se encontraron clientes', style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Registre clientes para habilitar ventas a crédito, historial de compras y cuentas por cobrar.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: customers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = customers[index];
            final hasDebt = c.hasDebt;

            return NubikoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar con inicial o icono
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (hasDebt ? AppColors.warning : AppColors.primary).withValues(alpha: 0.12),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Center(
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: hasDebt ? AppColors.warning : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nombre e información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(c.name, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            if (c.taxId != null && c.taxId!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightBorder,
                                  borderRadius: AppRadius.roundedSm,
                                ),
                                child: Text('RNC: ${c.taxId}', style: AppTypography.bodySmall),
                              ),
                            ],
                            if (c.isOverCreditLimit) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.roundedSm,
                                ),
                                child: const Text(
                                  'LÍMITE EXCEDIDO',
                                  style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 14,
                          children: [
                            if (c.phone != null && c.phone!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.phone, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(c.phone!, style: AppTypography.bodySmall),
                                ],
                              ),
                            if (c.whatsapp != null && c.whatsapp!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.messageCircle, size: 13, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(c.whatsapp!, style: AppTypography.bodySmall),
                                ],
                              ),
                            if (c.email != null && c.email!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.mail, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(c.email!, style: AppTypography.bodySmall),
                                ],
                              ),
                            if (c.totalSalesCount > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.shoppingBag, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${c.totalSalesCount} facturas (${currencyFormat.format(c.totalPurchasedAmount)})',
                                      style: AppTypography.bodySmall),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Balance Deuda (CXC)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Balance por Cobrar', style: AppTypography.bodySmall),
                      Text(
                        currencyFormat.format(c.currentBalance),
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasDebt ? AppColors.warning : AppColors.success,
                        ),
                      ),
                      if (c.creditLimit > 0)
                        Text(
                          'Límite: ${currencyFormat.format(c.creditLimit)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Botones de acción
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Estado de Cuenta (Kardex)',
                        icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                        onPressed: () => _openStatement(context, c),
                      ),
                      if (hasDebt)
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: AppColors.success),
                          tooltip: 'Cobrar / Abono',
                          icon: const Icon(LucideIcons.handCoins, size: 16),
                          onPressed: () => _openPayment(context, c),
                        ),
                      IconButton.outlined(
                        tooltip: 'Editar Datos',
                        icon: const Icon(LucideIcons.pencil, size: 16),
                        onPressed: () => _openForm(context, c),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
