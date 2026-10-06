import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/nubiko_badge.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_responsive_layout.dart';
import '../../../../shared/widgets/nubiko_skeleton.dart';
import '../../../../shared/widgets/nubiko_stat_card.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/stock_movement_dialog.dart';
import '../../domain/models/inventory_item_model.dart';
import '../../domain/models/inventory_movement_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryControllerProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(inventoryControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(inventoryControllerProvider.notifier).loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: NubikoBreakpoints.isMobile(context)
              ? AppSpacing.mobilePagePadding
              : AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar
              _buildHeader(context, isDark),
              const SizedBox(height: 24),

              // Key Valuation & Stock Metrics
              _buildMetricsOverview(context, state.metrics, isDark),
              const SizedBox(height: 24),

              // Tabs & Search Toolbar
              _buildToolbar(context, state, isDark),
              const SizedBox(height: 16),

              // Dynamic Content: Stock actual vs Movimientos (Kardex)
              if (state.isLoading)
                _buildLoadingSkeleton()
              else if (state.selectedTab == 0)
                _buildStockTab(context, state.items, isDark)
              else
                _buildMovementsTab(context, state.movements, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control de Inventario & Kardex',
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supervisa existencias en tiempo real, cuánto queda tras cada venta, valorización y mermas',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            NubikoButton(
              text: isCompact ? 'Ajustar' : 'Registrar Movimiento',
              icon: LucideIcons.arrowUpDown,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const StockMovementDialog(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsOverview(BuildContext context, Map<String, dynamic> metrics, bool isDark) {
    final costValuation = (metrics['total_cost_valuation'] as num?)?.toDouble() ?? 0.0;
    final saleValuation = (metrics['total_sale_valuation'] as num?)?.toDouble() ?? 0.0;
    final profitValuation = saleValuation - costValuation;
    final totalUnits = (metrics['total_units'] as num?)?.toDouble() ?? 0.0;
    final lowStock = (metrics['low_stock_count'] as num?)?.toInt() ?? 0;

    return NubikoResponsiveLayout(
      mobile: Column(
        children: [
          NubikoStatCard(
            title: 'Valorización al Costo',
            value: Formatters.currency(costValuation),
            comparisonText: 'Capital total invertido en almacén',
            icon: LucideIcons.wallet,
            iconColor: AppColors.primary500,
          ),
          const SizedBox(height: 12),
          NubikoStatCard(
            title: 'Valorización a la Venta',
            value: Formatters.currency(saleValuation),
            comparisonText: 'Ingreso estimado en existencia',
            icon: LucideIcons.trendingUp,
            iconColor: AppColors.emerald500,
          ),
          const SizedBox(height: 12),
          NubikoStatCard(
            title: 'Ganancia en Almacén',
            value: Formatters.currency(profitValuation),
            comparisonText: 'Beneficio neto al liquidar stock',
            icon: LucideIcons.coins,
            iconColor: AppColors.primary600,
          ),
          const SizedBox(height: 12),
          NubikoStatCard(
            title: 'Unidades & Alertas',
            value: '${totalUnits.toStringAsFixed(0)} unidades',
            comparisonText: '$lowStock con alerta de stock bajo',
            icon: LucideIcons.alertTriangle,
            iconColor: lowStock > 0 ? AppColors.rose500 : AppColors.slate500,
          ),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(
            child: NubikoStatCard(
              title: 'Valorización al Costo',
              value: Formatters.currency(costValuation),
              comparisonText: 'Inversión actual en existencias',
              icon: LucideIcons.wallet,
              iconColor: AppColors.primary500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: NubikoStatCard(
              title: 'Valorización a la Venta',
              value: Formatters.currency(saleValuation),
              comparisonText: 'Ingreso potencial total',
              icon: LucideIcons.trendingUp,
              iconColor: AppColors.emerald500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: NubikoStatCard(
              title: 'Ganancia en Almacén',
              value: Formatters.currency(profitValuation),
              comparisonText: 'Beneficio potencial proyectado',
              icon: LucideIcons.coins,
              iconColor: AppColors.primary600,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: NubikoStatCard(
              title: 'Unidades & Alertas',
              value: '${totalUnits.toStringAsFixed(0)} unidades',
              comparisonText: '$lowStock en nivel crítico o agotado',
              icon: LucideIcons.alertTriangle,
              iconColor: lowStock > 0 ? AppColors.rose500 : AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, InventoryState state, bool isDark) {
    return NubikoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Tabs: Stock actual vs Kardex
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate950 : AppColors.slate100,
                  borderRadius: AppRadius.roundedMd,
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      title: 'Existencias Actuales',
                      icon: LucideIcons.boxes,
                      isSelected: state.selectedTab == 0,
                      tabIndex: 0,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      title: 'Kardex / Movimientos',
                      icon: LucideIcons.history,
                      isSelected: state.selectedTab == 1,
                      tabIndex: 1,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Quick Filter: Solo Stock Bajo
              FilterChip(
                label: const Text('Solo Stock Bajo / Crítico'),
                selected: state.onlyLowStock,
                selectedColor: AppColors.amber500.withValues(alpha: 0.2),
                checkmarkColor: AppColors.amber500,
                onSelected: (_) {
                  ref.read(inventoryControllerProvider.notifier).toggleLowStockFilter();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar artículo por nombre, SKU o código de barras...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(inventoryControllerProvider.notifier).setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: isDark ? AppColors.slate950 : AppColors.slate50,
              border: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: BorderSide(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
            ),
            onChanged: (val) => ref.read(inventoryControllerProvider.notifier).setSearchQuery(val),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required int tabIndex,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => ref.read(inventoryControllerProvider.notifier).setSelectedTab(tabIndex),
      borderRadius: AppRadius.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.slate800 : Colors.white)
              : Colors.transparent,
          borderRadius: AppRadius.roundedSm,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary500 : AppColors.slate400,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.slate900)
                    : AppColors.slate400,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTab(
    BuildContext context,
    List<InventoryItemModel> items,
    bool isDark,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(
        isDark,
        title: 'No hay productos en inventario',
        subtitle: 'Registra tus productos desde el módulo de Productos o realiza un ajuste inicial de inventario.',
        actionText: 'Registrar Entrada',
        onAction: () => showDialog(
          context: context,
          builder: (_) => const StockMovementDialog(),
        ),
      );
    }

    return NubikoCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1050),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? AppColors.slate950 : AppColors.slate50,
            ),
            dataRowMaxHeight: 74,
            horizontalMargin: 20,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('Producto / SKU', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Disponibilidad', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Inversión (Costo)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Venta Estimada', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Ganancia Proyectada', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  // Producto & SKU
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary500.withValues(alpha: 0.1),
                            borderRadius: AppRadius.roundedSm,
                          ),
                          child: const Icon(LucideIcons.package, size: 18, color: AppColors.primary500),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.productName,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SKU: ${item.sku} ${item.barcode != null ? '• ${item.barcode}' : ''}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.slate500 : AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Disponibilidad (Cuánto queda)
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Quedan ${item.currentStock.toStringAsFixed(0)} ${item.unit}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: item.isOutOfStock
                                ? AppColors.rose500
                                : (item.isLowStock ? AppColors.amber500 : AppColors.emerald500),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mínimo requerido: ${item.minStock.toStringAsFixed(0)} ${item.unit}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.slate500 : AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Inversión (Costo)
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(Formatters.currency(item.costPrice), style: AppTypography.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Total Inv: ${Formatters.currency(item.totalCostValue)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.slate400 : AppColors.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Venta Estimada
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Formatters.currency(item.salePrice),
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Vta: ${Formatters.currency(item.totalSaleValue)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.slate400 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ganancia Proyectada
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+${Formatters.currency(item.profitPerUnit)} / ud',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.emerald500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: +${Formatters.currency(item.totalExpectedProfit)} (+${item.profitMarginPercentage.toStringAsFixed(0)}%)',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.emerald600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estado Badge
                  DataCell(_buildStatusBadge(item)),

                  // Acciones
                  DataCell(
                    NubikoButton(
                      text: 'Ajustar Stock',
                      icon: LucideIcons.arrowUpDown,
                      variant: NubikoButtonVariant.secondary,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => StockMovementDialog(initialItem: item),
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementsTab(
    BuildContext context,
    List<InventoryMovementModel> movements,
    bool isDark,
  ) {
    if (movements.isEmpty) {
      return _buildEmptyState(
        isDark,
        title: 'Sin movimientos registrados',
        subtitle: 'Los ingresos, ventas, mermas y ajustes aparecerán registrados en este historial detallado.',
        actionText: 'Nuevo Movimiento',
        onAction: () => showDialog(
          context: context,
          builder: (_) => const StockMovementDialog(),
        ),
      );
    }

    return NubikoCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 950),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? AppColors.slate950 : AppColors.slate50,
            ),
            dataRowMaxHeight: 66,
            horizontalMargin: 20,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Operación', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cantidad Movida', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stock: Antes ➔ Después', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Costo Unit.', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Motivo / Factura', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: movements.map((m) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      Formatters.dateTime(m.createdAt),
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  DataCell(
                    Text(
                      m.productName ?? 'Producto',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(_buildMovementBadge(m)),
                  DataCell(
                    Text(
                      '${m.isPositive ? '+' : '-'}${m.quantity.toStringAsFixed(0)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: m.isPositive ? AppColors.emerald500 : AppColors.rose500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${m.previousStock.toStringAsFixed(0)}  ➔  ${m.newStock.toStringAsFixed(0)} (Quedan ${m.newStock.toStringAsFixed(0)})',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: m.newStock <= 0 ? AppColors.rose500 : null,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(m.unitCost != null ? Formatters.currency(m.unitCost!) : '-'),
                  ),
                  DataCell(
                    Text(
                      m.notes ?? '-',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InventoryItemModel item) {
    if (item.isOutOfStock) {
      return const NubikoBadge(
        text: 'Agotado (0 ud)',
        variant: NubikoBadgeVariant.danger,
        icon: LucideIcons.xCircle,
      );
    }
    if (item.isLowStock) {
      return NubikoBadge(
        text: 'Quedan ${item.currentStock.toStringAsFixed(0)} (Bajo)',
        variant: NubikoBadgeVariant.warning,
        icon: LucideIcons.alertTriangle,
      );
    }
    return NubikoBadge(
      text: 'Quedan ${item.currentStock.toStringAsFixed(0)} ud',
      variant: NubikoBadgeVariant.success,
      icon: LucideIcons.checkCircle,
    );
  }

  Widget _buildMovementBadge(InventoryMovementModel m) {
    if (m.movementType == 'sale') {
      return const NubikoBadge(
        text: 'Venta POS',
        variant: NubikoBadgeVariant.danger,
        icon: LucideIcons.shoppingCart,
      );
    }
    if (m.isPositive) {
      return NubikoBadge(
        text: m.typeLabel,
        variant: NubikoBadgeVariant.success,
        icon: LucideIcons.arrowDownLeft,
      );
    }
    return NubikoBadge(
      text: m.typeLabel,
      variant: NubikoBadgeVariant.danger,
      icon: LucideIcons.arrowUpRight,
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: const [
        NubikoSkeleton(height: 60),
        SizedBox(height: 12),
        NubikoSkeleton(height: 60),
        SizedBox(height: 12),
        NubikoSkeleton(height: 60),
      ],
    );
  }

  Widget _buildEmptyState(
    bool isDark, {
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.boxes, size: 48, color: AppColors.primary500),
            ).animate().scale(duration: 350.ms),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            NubikoButton(
              text: actionText,
              icon: LucideIcons.plus,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
