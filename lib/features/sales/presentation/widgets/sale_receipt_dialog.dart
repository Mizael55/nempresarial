import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

class SaleReceiptDialog extends ConsumerWidget {
  final Map<String, dynamic> saleData;

  const SaleReceiptDialog({super.key, required this.saleData});

  static Future<void> show(BuildContext context, Map<String, dynamic> saleData) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SaleReceiptDialog(saleData: saleData),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(onboardingControllerProvider).settings;

    final currency = settings.currencySymbol.isNotEmpty ? settings.currencySymbol : '\$';
    final invoiceNumber = saleData['invoice_number'] as String? ?? 'FAC-000000';
    final total = (saleData['total_amount'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (saleData['subtotal'] as num?)?.toDouble() ?? total;
    final tax = (saleData['tax_amount'] as num?)?.toDouble() ?? 0.0;
    final discount = (saleData['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final received = (saleData['received_amount'] as num?)?.toDouble() ?? total;
    final change = (saleData['change_amount'] as num?)?.toDouble() ?? 0.0;
    final customerName = saleData['customer_name'] as String? ?? 'Consumidor Final';
    final customerTaxId = saleData['customer_tax_id'] as String?;
    final paymentMethod = saleData['payment_method'] as String? ?? 'cash';
    final items = (saleData['items'] as List<dynamic>?) ?? [];

    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    String formatMethod(String m) {
      switch (m) {
        case 'cash':
          return 'Efectivo';
        case 'credit_card':
          return 'Tarjeta de Crédito';
        case 'debit_card':
          return 'Tarjeta de Débito';
        case 'transfer':
          return 'Transferencia';
        case 'credit':
          return 'Crédito';
        default:
          return m.toUpperCase();
      }
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
        child: Column(
          children: [
            // Header del Modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.circleCheckBig, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('¡Venta Completada!', style: AppTypography.titleMedium),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenedor del Ticket (Aspecto Factura Térmica Profesional)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131720) : const Color(0xFFF8FAFC),
                    borderRadius: AppRadius.roundedLg,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Encabezado de la Empresa
                      Text(
                        settings.businessName.isNotEmpty ? settings.businessName : 'NUBIKO POS',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (settings.taxId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('RNC / ID: ${settings.taxId}', style: AppTypography.bodySmall),
                      ],
                      if (settings.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(settings.address, style: AppTypography.bodySmall, textAlign: TextAlign.center),
                      ],
                      if (settings.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Tel: ${settings.phone}', style: AppTypography.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Datos de la Venta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Factura:', style: AppTypography.bodySmall),
                          Text(invoiceNumber, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fecha:', style: AppTypography.bodySmall),
                          Text(dateStr, style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cliente:', style: AppTypography.bodySmall),
                          Text(customerName, style: AppTypography.bodySmall),
                        ],
                      ),
                      if (customerTaxId != null && customerTaxId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RNC Cliente:', style: AppTypography.bodySmall),
                            Text(customerTaxId, style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Tabla de Artículos
                      Row(
                        children: [
                          Expanded(flex: 5, child: Text('Descrip.', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Cant', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('Total', textAlign: TextAlign.right, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...items.map((item) {
                        final name = item['name'] as String? ?? 'Producto';
                        final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
                        final itmTotal = (item['total'] as num?)?.toDouble() ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(flex: 5, child: Text(name, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Expanded(flex: 2, child: Text(qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2), textAlign: TextAlign.center, style: AppTypography.bodySmall)),
                              Expanded(flex: 3, child: Text('$currency${itmTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: AppTypography.bodySmall)),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Totales
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:', style: AppTypography.bodySmall),
                          Text('$currency${subtotal.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                        ],
                      ),
                      if (tax > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${settings.taxName.isNotEmpty ? settings.taxName : 'Impuesto'}:', style: AppTypography.bodySmall),
                            Text('$currency${tax.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                      if (discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Descuento:', style: AppTypography.bodySmall),
                            Text('-$currency${discount.toStringAsFixed(2)}', style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL:', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text('$currency${total.toStringAsFixed(2)}', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Pagos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Método de Pago:', style: AppTypography.bodySmall),
                          Text(formatMethod(paymentMethod), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (paymentMethod == 'cash' && received > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recibido:', style: AppTypography.bodySmall),
                            Text('$currency${received.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cambio / Devuelta:', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                            Text('$currency${change.toStringAsFixed(2)}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        '¡Gracias por su compra!',
                        style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones de acción
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                      ),
                      icon: const Icon(LucideIcons.printer, size: 18),
                      label: const Text('Imprimir'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Documento enviado a la cola de impresión.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NubikoButton(
                      text: 'Nueva Venta',
                      icon: LucideIcons.plus,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
