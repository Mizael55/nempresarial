import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../onboarding/domain/business_settings_model.dart';
import '../../domain/models/customer_model.dart';
import '../controllers/sales_controller.dart';
import 'pos_checkout_dialog.dart';
import 'quick_customer_dialog.dart';

class PosCartPanel extends ConsumerWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posState = ref.watch(posControllerProvider);
    final posNotifier = ref.read(posControllerProvider.notifier);
    BusinessSettingsModel settings = const BusinessSettingsModel(businessName: '');
    try {
      settings = ref.watch(onboardingControllerProvider).settings;
    } catch (_) {}
    final currency = settings.currencySymbol.isNotEmpty ? settings.currencySymbol : '\$';
    final customersAsync = ref.watch(customersListProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadius.roundedXl,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Selección de Cliente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.shoppingBag, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Detalle de Venta',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (posState.cart.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 14),
                        label: const Text('Vaciar', style: TextStyle(fontSize: 12)),
                        onPressed: posNotifier.clearCart,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selector de Cliente y Botón Nuevo Cliente
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: customersAsync.when(
                          data: (customers) {
                            return DropdownButtonHideUnderline(
                              child: DropdownButton<CustomerModel?>(
                                isExpanded: true,
                                value: posState.selectedCustomer,
                                hint: Row(
                                  children: [
                                    const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text('Consumidor Final', style: AppTypography.bodySmall),
                                  ],
                                ),
                                items: [
                                  DropdownMenuItem<CustomerModel?>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text('Consumidor Final', style: AppTypography.bodySmall),
                                      ],
                                    ),
                                  ),
                                  ...customers.map((c) => DropdownMenuItem<CustomerModel?>(
                                        value: c,
                                        child: Text(
                                          c.name + (c.taxId != null ? ' (${c.taxId})' : ''),
                                          style: AppTypography.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                ],
                                onChanged: (val) => posNotifier.setCustomer(val),
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 24,
                            child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                          ),
                          error: (_, _) => Text('Consumidor Final', style: AppTypography.bodySmall),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(LucideIcons.userPlus, size: 16),
                      tooltip: 'Registrar Cliente',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                      ),
                      onPressed: () async {
                        final created = await QuickCustomerDialog.show(context);
                        if (created != null) {
                          posNotifier.setCustomer(created);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de Artículos en el Carrito
          Expanded(
            child: posState.cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.shoppingCart,
                              size: 36,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Carrito Vacío',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecciona productos del catálogo para agregarlos a la orden.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: posState.cart.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 16,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = posState.cart[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Nombre y precio unitario
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency${item.unitPrice.toStringAsFixed(2)} x ${item.quantity.toStringAsFixed(0)}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          // Control de Cantidad
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: AppRadius.roundedSm,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => posNotifier.updateQuantity(item.product.id, item.quantity - 1.0),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(LucideIcons.minus, size: 14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    item.quantity.toStringAsFixed(0),
                                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => posNotifier.updateQuantity(item.product.id, item.quantity + 1.0),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(LucideIcons.plus, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Total del item
                          SizedBox(
                            width: 75,
                            child: Text(
                              '$currency${item.totalAmount.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),

                          // Eliminar
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 15, color: Colors.grey),
                            tooltip: 'Quitar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => posNotifier.removeFromCart(item.product.id),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Resumen Financiero y Botón de Cobro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131720) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: AppTypography.bodySmall),
                    Text('$currency${posState.subtotal.toStringAsFixed(2)}', style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      settings.taxRate > 0
                          ? 'Impuesto / ${settings.taxName.isNotEmpty ? settings.taxName : 'ITBIS'} (${settings.taxRate.toStringAsFixed(settings.taxRate % 1 == 0 ? 0 : 1)}%)'
                          : 'Impuesto (${settings.taxName.isNotEmpty ? settings.taxName : 'ITBIS'})',
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      settings.taxRate > 0
                          ? '$currency${posState.totalTax.toStringAsFixed(2)}'
                          : 'Exento (0%)',
                      style: AppTypography.bodySmall.copyWith(
                        color: settings.taxRate > 0 ? null : AppColors.slate400,
                        fontWeight: settings.taxRate > 0 ? null : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (posState.globalDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Descuento General', style: AppTypography.bodySmall),
                      Text(
                        '-$currency${posState.globalDiscount.toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Total Final
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Factura', style: AppTypography.bodySmall),
                        Text(
                          '${posState.totalItemsCount} ${posState.totalItemsCount == 1 ? 'artículo' : 'artículos'}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    Text(
                      '$currency${posState.totalWithDiscount.toStringAsFixed(2)}',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botón Cobrar
                NubikoButton(
                  text: 'Cobrar $currency${posState.totalWithDiscount.toStringAsFixed(2)}',
                  icon: LucideIcons.badgeCheck,
                  isFullWidth: true,
                  height: 48,
                  onPressed: posState.cart.isEmpty
                      ? null
                      : () => PosCheckoutDialog.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
