import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

class CustomerReceiptDialog extends ConsumerWidget {
  final Map<String, dynamic> paymentData;

  const CustomerReceiptDialog({super.key, required this.paymentData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final businessSettings = ref.watch(onboardingControllerProvider).settings;
    final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    final customerName = paymentData['customer_name'] as String? ?? 'Cliente';
    final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
    final prevBalance = (paymentData['previous_balance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = (paymentData['new_balance'] as num?)?.toDouble() ?? 0.0;
    final method = (paymentData['payment_method'] as String? ?? 'Efectivo').toUpperCase();
    final paymentId = (paymentData['payment_id'] as String? ?? '000000').substring(0, 6).toUpperCase();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado Térmico
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCheck, color: AppColors.success, size: 28),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                businessSettings.businessName.isNotEmpty ? businessSettings.businessName : 'NUBIKO POS',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (businessSettings.taxId.isNotEmpty)
                Text('RNC: ${businessSettings.taxId}', style: AppTypography.bodySmall, textAlign: TextAlign.center),
              if (businessSettings.address.isNotEmpty)
                Text(businessSettings.address, style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'RECIBO DE INGRESO # REC-$paymentId',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Text(dateStr, style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Datos del Cliente y Pago
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recibido de:', style: AppTypography.bodySmall),
                  Text(customerName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Método de Pago:', style: AppTypography.bodySmall),
                  Text(method, style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Balance Anterior:', style: AppTypography.bodySmall),
                  Text(currencyFormat.format(prevBalance), style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MONTO PAGADO:', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(amount),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nuevo Balance Adeudado:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(newBalance),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: newBalance > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enviando a impresora de recibos...')),
                      );
                    },
                    icon: const Icon(LucideIcons.printer, size: 16),
                    label: const Text('Imprimir'),
                  ),
                  const SizedBox(width: 10),
                  NubikoButton(
                    text: 'Listo',
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
