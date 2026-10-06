import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/nubiko_badge.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_empty_state.dart';
import '../../../../shared/widgets/nubiko_responsive_layout.dart';
import '../../../../shared/widgets/nubiko_skeleton.dart';
import '../../../../shared/widgets/nubiko_stat_card.dart';
import '../controllers/categories_controller.dart';
import '../controllers/products_controller.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/product_form_dialog.dart';
import '../../domain/models/product_model.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../onboarding/domain/business_settings_model.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsControllerProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductForm(BuildContext context, [ProductModel? product]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(productToEdit: product),
    );
  }

  void _openCategoryForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CategoryFormDialog(),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppColors.rose500, size: 22),
              SizedBox(width: 10),
              Text('Eliminar Producto'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${product.name}"? Esta acción no se puede deshacer.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose500),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(productsControllerProvider.notifier).deleteProduct(product.id);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsState = ref.watch(productsControllerProvider);
    final categoriesState = ref.watch(categoriesControllerProvider);
    BusinessSettingsModel settings = const BusinessSettingsModel(businessName: '');
    try {
      settings = ref.watch(onboardingControllerProvider).settings;
    } catch (_) {}
    final isMobile = NubikoBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(productsControllerProvider.notifier).loadProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catálogo de Productos',
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Administra precios, costos, inversión, margen de ganancias y existencias',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        NubikoButton(
                          text: 'Categorías',
                          icon: LucideIcons.tag,
                          variant: NubikoButtonVariant.secondary,
                          onPressed: () => _openCategoryForm(context),
                        ),
                        const SizedBox(width: 12),
                        NubikoButton(
                          text: 'Nuevo Producto',
                          icon: LucideIcons.plus,
                          onPressed: () => _openProductForm(context),
                        ),
                      ],
                    ),
                  ],
                ],
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),

              // KPI Stats Grid
              _buildStatsGrid(context, productsState),
              const SizedBox(height: 24),

              // Filters & Search Bar
              _buildFilterBar(context, ref, productsState, categoriesState, isDark),
              const SizedBox(height: 18),

              // Products View (Desktop Table vs Mobile Cards)
              if (productsState.isLoading) ...[
                const NubikoSkeleton(height: 60),
                const SizedBox(height: 12),
                const NubikoSkeleton(height: 60),
                const SizedBox(height: 12),
                const NubikoSkeleton(height: 60),
              ] else if (productsState.filteredProducts.isEmpty) ...[
                NubikoCard(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: NubikoEmptyState(
                    icon: LucideIcons.packageOpen,
                    title: 'No se encontraron productos',
                    description: productsState.searchQuery.isNotEmpty
                        ? 'No hay productos que coincidan con la búsqueda "${productsState.searchQuery}".'
                        : 'Tu catálogo está vacío. Comienza registrando tu primer producto para vender.',
                    actionText: 'Crear Producto',
                    onAction: () => _openProductForm(context),
                  ),
                ),
              ] else ...[
                NubikoResponsiveLayout(
                  mobile: _buildMobileList(context, ref, productsState.filteredProducts, isDark, settings),
                  desktop: _buildDesktopTable(context, ref, productsState.filteredProducts, isDark, settings),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => _openProductForm(context),
              backgroundColor: AppColors.primary500,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildStatsGrid(BuildContext context, ProductsState state) {
    final isMobile = NubikoBreakpoints.isMobile(context);

    final cards = [
      NubikoStatCard(
        title: 'Total de Productos',
        value: '${state.totalProductsCount} en catálogo',
        icon: LucideIcons.package,
        iconColor: AppColors.primary500,
      ),
      NubikoStatCard(
        title: 'Capital Invertido',
        value: Formatters.currency(state.totalInventoryValue),
        comparisonText: 'Inversión total en existencias',
        icon: LucideIcons.coins,
        iconColor: AppColors.primary600,
      ),
      NubikoStatCard(
        title: 'Ganancia Proyectada',
        value: Formatters.currency(state.totalExpectedProfit),
        comparisonText: 'Beneficio neto al vender todo',
        icon: LucideIcons.trendingUp,
        iconColor: AppColors.emerald500,
      ),
      NubikoStatCard(
        title: 'Alertas de Stock',
        value: '${state.lowStockCount} bajos / ${state.outOfStockCount} agot.',
        comparisonText: 'Requieren reabastecimiento',
        icon: LucideIcons.alertTriangle,
        iconColor: state.lowStockCount > 0 || state.outOfStockCount > 0
            ? AppColors.rose500
            : AppColors.slate500,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    ProductsState state,
    CategoriesState catState,
    bool isDark,
  ) {
    return NubikoCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Input
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, SKU o código de barras...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productsControllerProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.roundedMd,
                  borderSide: BorderSide(color: isDark ? AppColors.slate700 : AppColors.slate200),
                ),
              ),
              onChanged: (val) {
                ref.read(productsControllerProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate50,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedCategoryId ?? 'all',
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todas las Categorías')),
                  ...catState.categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }),
                ],
                onChanged: (val) {
                  ref.read(productsControllerProvider.notifier).setSelectedCategory(val);
                },
              ),
            ),
          ),

          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate50,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProductSortBy>(
                value: state.sortBy,
                items: const [
                  DropdownMenuItem(value: ProductSortBy.nameAsc, child: Text('Nombre (A-Z)')),
                  DropdownMenuItem(value: ProductSortBy.nameDesc, child: Text('Nombre (Z-A)')),
                  DropdownMenuItem(value: ProductSortBy.priceAsc, child: Text('Precio (Menor a Mayor)')),
                  DropdownMenuItem(value: ProductSortBy.priceDesc, child: Text('Precio (Mayor a Menor)')),
                  DropdownMenuItem(value: ProductSortBy.stockAsc, child: Text('Stock (Menor a Mayor)')),
                  DropdownMenuItem(value: ProductSortBy.stockDesc, child: Text('Stock (Mayor a Menor)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(productsControllerProvider.notifier).setSortBy(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    WidgetRef ref,
    List<ProductModel> products,
    bool isDark,
    BusinessSettingsModel settings,
  ) {
    return NubikoCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1050),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.slate800 : AppColors.slate100,
              ),
              dataRowMaxHeight: 74,
              horizontalMargin: 20,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('Producto / SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Inversión (Costo)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Venta & Retorno', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ganancia & Margen', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Disponibilidad', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: products.map((product) {
                // Stock indicator
                NubikoBadgeVariant stockBadge;
                IconData stockIcon;
                String stockText;
                if (product.isOutOfStock) {
                  stockBadge = NubikoBadgeVariant.danger;
                  stockIcon = LucideIcons.xCircle;
                  stockText = 'Agotado (0 ${product.unit})';
                } else if (product.isLowStock) {
                  stockBadge = NubikoBadgeVariant.warning;
                  stockIcon = LucideIcons.alertTriangle;
                  stockText = 'Quedan ${product.currentStock.toInt()} ${product.unit} (Bajo)';
                } else {
                  stockBadge = NubikoBadgeVariant.success;
                  stockIcon = LucideIcons.checkCircle;
                  stockText = 'Quedan ${product.currentStock.toInt()} ${product.unit}';
                }

                return DataRow(
                  cells: [
                    // Producto / SKU
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.slate800 : AppColors.primary50,
                              borderRadius: AppRadius.roundedMd,
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.package,
                                size: 18,
                                color: isDark ? AppColors.primary400 : AppColors.primary600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SKU: ${product.sku} ${product.barcode != null ? '• ${product.barcode}' : ''}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.slate500 : AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Categoría
                    DataCell(
                      NubikoBadge(
                        text: product.categoryName ?? 'Sin categoría',
                        variant: NubikoBadgeVariant.info,
                      ),
                    ),

                    // Inversión (Costo Unitario & Total Invertido)
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Formatters.currency(product.costPrice),
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Inv: ${Formatters.currency(product.totalInvested)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.slate400 : AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Venta & Retorno Estimado
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Formatters.currency(product.salePrice),
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Vta: ${Formatters.currency(product.totalExpectedRevenue)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (settings.taxRate > 0 && product.isTaxable)
                                      ? AppColors.primary500.withValues(alpha: 0.12)
                                      : (isDark ? AppColors.slate800 : AppColors.slate200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (settings.taxRate > 0 && product.isTaxable)
                                      ? '+${settings.taxName} (${settings.taxRate.toStringAsFixed(settings.taxRate % 1 == 0 ? 0 : 1)}%)'
                                      : 'Exento (0%)',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: (settings.taxRate > 0 && product.isTaxable)
                                        ? AppColors.primary500
                                        : (isDark ? AppColors.slate400 : AppColors.slate600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ganancia & Margen
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${Formatters.currency(product.profitPerUnit)}/u',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.emerald500,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (product.profitMarginPercentage >= 20
                                          ? AppColors.emerald500
                                          : AppColors.amber500)
                                      .withValues(alpha: 0.12),
                                  borderRadius: AppRadius.roundedSm,
                                ),
                                child: Text(
                                  '+${product.profitMarginPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: product.profitMarginPercentage >= 20
                                        ? AppColors.emerald500
                                        : AppColors.amber500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gana: +${Formatters.currency(product.totalExpectedProfit)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.emerald600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Disponibilidad / Stock
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NubikoBadge(
                            text: stockText,
                            variant: stockBadge,
                            icon: stockIcon,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mínimo: ${product.minStock.toInt()} ${product.unit}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.slate500 : AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Acciones
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.pencil, size: 18),
                            tooltip: 'Editar',
                            onPressed: () => _openProductForm(context, product),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.rose500),
                            tooltip: 'Eliminar',
                            onPressed: () => _confirmDelete(context, ref, product),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    WidgetRef ref,
    List<ProductModel> products,
    bool isDark,
    BusinessSettingsModel settings,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = products[index];

        return NubikoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') _openProductForm(context, p);
                      if (val == 'delete') _confirmDelete(context, ref, p);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: AppColors.rose500)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${p.sku}',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inversión (Costo)', style: AppTypography.labelSmall),
                      Text(Formatters.currency(p.costPrice), style: AppTypography.bodyMedium),
                      Text('Inv: ${Formatters.currency(p.totalInvested)}', style: AppTypography.labelSmall),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Venta Unit.', style: AppTypography.labelSmall),
                      Text(Formatters.currency(p.salePrice), style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Vta: ${Formatters.currency(p.totalExpectedRevenue)}', style: AppTypography.labelSmall),
                          const SizedBox(width: 4),
                          Text(
                            (settings.taxRate > 0 && p.isTaxable)
                                ? '+${settings.taxName} (${settings.taxRate.toStringAsFixed(0)}%)'
                                : 'Exento (0%)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: (settings.taxRate > 0 && p.isTaxable)
                                  ? AppColors.primary500
                                  : (isDark ? AppColors.slate400 : AppColors.slate500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ganancia', style: AppTypography.labelSmall),
                      Text(
                        '+${Formatters.currency(p.profitPerUnit)}/u (+${p.profitMarginPercentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: AppColors.emerald500,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Total: +${Formatters.currency(p.totalExpectedProfit)}',
                        style: TextStyle(color: AppColors.emerald600, fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      NubikoBadge(
                        text: p.isOutOfStock
                            ? 'Agotado (0 ${p.unit})'
                            : 'Quedan ${p.currentStock.toInt()} ${p.unit}',
                        variant: p.isOutOfStock
                            ? NubikoBadgeVariant.danger
                            : (p.isLowStock ? NubikoBadgeVariant.warning : NubikoBadgeVariant.success),
                      ),
                      const SizedBox(height: 2),
                      Text('Mínimo: ${p.minStock.toInt()} ${p.unit}', style: AppTypography.labelSmall),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
