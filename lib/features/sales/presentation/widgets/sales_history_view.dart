import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_badge.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/sale_model.dart';
import '../../data/sales_repository_impl.dart';
import '../controllers/sales_controller.dart';
import 'sale_receipt_dialog.dart';

class SalesHistoryView extends ConsumerStatefulWidget {
  const SalesHistoryView({super.key});

  @override
  ConsumerState<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends ConsumerState<SalesHistoryView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onVoidSale(SaleModel sale) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.triangleAlert, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            const Text('Anular Factura'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de anular la factura ${sale.invoiceNumber}?'),
            const SizedBox(height: 8),
            const Text(
              'Esta acción revertirá los productos al inventario y marcará la venta como cancelada.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulación',
                hintText: 'Ej. Error en cobro o devolución de cliente',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final user = ref.read(authControllerProvider).user;
                final repo = ref.read(salesRepositoryProvider);
                await repo.voidSale(
                  saleId: sale.id,
                  reason: reasonController.text.isNotEmpty ? reasonController.text : 'Anulado por usuario',
                  userId: user?.id,
                );
                ref.invalidate(salesListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Factura ${sale.invoiceNumber} anulada y stock retornado.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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

  void _onViewReceipt(SaleModel sale) async {
    final repo = ref.read(salesRepositoryProvider);
    final items = await repo.getSaleItems(sale.id);

    if (!mounted) return;

    SaleReceiptDialog.show(context, {
      'invoice_number': sale.invoiceNumber,
      'total_amount': sale.totalAmount,
      'subtotal': sale.subtotal,
      'tax_amount': sale.taxAmount,
      'discount_amount': sale.discountAmount,
      'customer_name': sale.customerName,
      'customer_tax_id': sale.customerTaxId,
      'payment_method': sale.paymentMethod,
      'items': items.map((i) => {
        'name': i.productName,
        'quantity': i.quantity,
        'price': i.unitPrice,
        'subtotal': i.unitPrice * i.quantity,
        'tax': i.taxAmount,
        'total': i.totalAmount,
      }).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salesAsync = ref.watch(salesListProvider);
    final filter = ref.watch(salesFilterProvider);
    final filterNotifier = ref.read(salesFilterProvider.notifier);
    final settings = ref.watch(onboardingControllerProvider).settings;
    final currency = settings.currencySymbol.isNotEmpty ? settings.currencySymbol : '\$';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtros y Búsqueda
        Row(
          children: [
            Expanded(
              flex: 3,
              child: NubikoTextField(
                controller: _searchController,
                hintText: 'Buscar por No. Factura o Cliente...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          filterNotifier.state = filter.copyWith(searchQuery: '');
                        },
                      )
                    : null,
                onChanged: (val) {
                  filterNotifier.state = filter.copyWith(searchQuery: val);
                },
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Todas')),
                ButtonSegment(value: 'completed', label: Text('Completadas')),
                ButtonSegment(value: 'cancelled', label: Text('Anuladas')),
              ],
              selected: {filter.status},
              onSelectionChanged: (val) {
                filterNotifier.state = filter.copyWith(status: val.first);
              },
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'Actualizar',
              onPressed: () => ref.invalidate(salesListProvider),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lista / Tabla de Facturas
        Expanded(
          child: salesAsync.when(
            data: (sales) {
              if (sales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.receiptText,
                        size: 54,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text('No hay ventas registradas', style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Las facturas emitidas desde el Punto de Venta aparecerán aquí.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final isCancelled = sale.status == 'cancelled';
                  final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(sale.createdAt);

                  return NubikoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        // Icono de Estado
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? AppColors.error.withValues(alpha: 0.12)
                                : AppColors.success.withValues(alpha: 0.12),
                            borderRadius: AppRadius.roundedMd,
                          ),
                          child: Icon(
                            isCancelled ? LucideIcons.ban : LucideIcons.receiptText,
                            color: isCancelled ? AppColors.error : AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Datos de Factura
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sale.invoiceNumber,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  NubikoBadge(
                                    text: isCancelled ? 'ANULADA' : 'COMPLETADA',
                                    variant: isCancelled ? NubikoBadgeVariant.danger : NubikoBadgeVariant.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cliente: ${sale.customerName} • ${sale.itemsCount} ${sale.itemsCount == 1 ? 'ítem' : 'ítems'}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        // Fecha y Cajero
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormatted, style: AppTypography.bodySmall),
                              const SizedBox(height: 2),
                              Text('Cajero: ${sale.cashierName}', style: AppTypography.labelSmall),
                            ],
                          ),
                        ),

                        // Método y Total
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$currency${sale.totalAmount.toStringAsFixed(2)}',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled ? Colors.grey : AppColors.primary,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sale.paymentMethod.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Acciones
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (val) {
                            if (val == 'receipt') {
                              _onViewReceipt(sale);
                            } else if (val == 'void') {
                              _onVoidSale(sale);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'receipt',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.printer, size: 16),
                                  SizedBox(width: 8),
                                  Text('Ver / Imprimir Ticket'),
                                ],
                              ),
                            ),
                            if (!isCancelled)
                              const PopupMenuItem(
                                value: 'void',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.ban, size: 16, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Anular Venta', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
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
            error: (err, _) => Center(
              child: Text('Error al cargar ventas: $err', style: const TextStyle(color: AppColors.error)),
            ),
          ),
        ),
      ],
    );
  }
}
