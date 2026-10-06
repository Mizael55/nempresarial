import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/purchases_controller.dart';
import '../../domain/models/purchase_model.dart';
import 'purchase_detail_dialog.dart';

class PurchasesListView extends ConsumerStatefulWidget {
  const PurchasesListView({super.key});

  @override
  ConsumerState<PurchasesListView> createState() => _PurchasesListViewState();
}

class _PurchasesListViewState extends ConsumerState<PurchasesListView> {
  final _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(PurchaseModel purchase) {
    showDialog(
      context: context,
      builder: (ctx) => PurchaseDetailDialog(purchase: purchase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchasesAsync = ref.watch(purchasesListProvider);
    final selectedFilter = ref.watch(purchasesFilterStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de búsqueda y filtros
        Row(
          children: [
            Expanded(
              child: NubikoTextField(
                controller: _searchController,
                hintText: 'Buscar por # de compra o proveedor...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                onChanged: (val) {
                  ref.read(purchasesSearchQueryProvider.notifier).state = val.trim();
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Refrescar',
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              onPressed: () => ref.read(purchasesListProvider.notifier).refresh(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filtro por estado
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todas'),
                selected: selectedFilter == 'all',
                onSelected: (_) => ref.read(purchasesFilterStatusProvider.notifier).state = 'all',
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Recibidas'),
                selected: selectedFilter == 'received',
                onSelected: (_) => ref.read(purchasesFilterStatusProvider.notifier).state = 'received',
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Anuladas'),
                selected: selectedFilter == 'cancelled',
                onSelected: (_) => ref.read(purchasesFilterStatusProvider.notifier).state = 'cancelled',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de Compras
        Expanded(
          child: purchasesAsync.when(
            data: (purchases) {
              if (purchases.isEmpty) {
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
                        child: const Icon(LucideIcons.truck, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('No hay compras registradas', style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Las compras realizadas aumentarán automáticamente las existencias de inventario.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: purchases.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = purchases[index];
                  final isCancelled = p.status == 'cancelled';
                  final dateFormatted = DateFormat('dd/MM/yyyy hh:mm a').format(p.createdAt);

                  return NubikoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: InkWell(
                      onTap: () => _openDetails(p),
                      borderRadius: AppRadius.roundedLg,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isCancelled ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                              borderRadius: AppRadius.roundedMd,
                            ),
                            child: Icon(
                              isCancelled ? LucideIcons.ban : LucideIcons.receipt,
                              color: isCancelled ? AppColors.error : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.purchaseNumber,
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isCancelled ? AppColors.error : AppColors.success)
                                            .withValues(alpha: 0.12),
                                        borderRadius: AppRadius.roundedSm,
                                      ),
                                      child: Text(
                                        isCancelled ? 'ANULADA' : 'RECIBIDA',
                                        style: TextStyle(
                                          color: isCancelled ? AppColors.error : AppColors.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (p.isPendingPayment && !isCancelled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.15),
                                          borderRadius: AppRadius.roundedSm,
                                        ),
                                        child: const Text(
                                          'POR PAGAR',
                                          style: TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${p.supplierName} • ${p.itemsCount} productos • $dateFormatted',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(p.totalAmount),
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                p.paymentMethod.toUpperCase(),
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
