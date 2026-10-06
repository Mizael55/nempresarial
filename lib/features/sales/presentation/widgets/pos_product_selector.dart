import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../products/presentation/controllers/products_controller.dart';
import '../../../products/presentation/controllers/categories_controller.dart';
import '../controllers/sales_controller.dart';

class PosProductSelector extends ConsumerStatefulWidget {
  const PosProductSelector({super.key});

  @override
  ConsumerState<PosProductSelector> createState() => _PosProductSelectorState();
}

class _PosProductSelectorState extends ConsumerState<PosProductSelector> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posState = ref.watch(posControllerProvider);
    final posNotifier = ref.read(posControllerProvider.notifier);
    final productsState = ref.watch(productsControllerProvider);
    final categoriesState = ref.watch(categoriesControllerProvider);
    final settings = ref.watch(onboardingControllerProvider).settings;
    final currency = settings.currencySymbol.isNotEmpty ? settings.currencySymbol : '\$';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de Búsqueda y Filtro Rápido
        Row(
          children: [
            Expanded(
              child: NubikoTextField(
                controller: _searchController,
                hintText: 'Buscar por nombre, código de barras o SKU...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          posNotifier.setSearchQuery('');
                        },
                      )
                    : const Icon(LucideIcons.scanBarcode, size: 18, color: Colors.grey),
                onChanged: (val) => posNotifier.setSearchQuery(val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filtro Horizontal de Categorías
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: posState.selectedCategoryId == null,
                onSelected: (_) => posNotifier.setCategoryFilter(null),
              ),
              const SizedBox(width: 8),
              ...categoriesState.categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: posState.selectedCategoryId == c.id,
                      onSelected: (_) => posNotifier.setCategoryFilter(c.id),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grilla de Productos
        Expanded(
          child: Builder(
            builder: (context) {
              if (productsState.isLoading && productsState.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = productsState.products;
              final filtered = products.where((p) {
                final matchQuery = posState.searchQuery.isEmpty ||
                    p.name.toLowerCase().contains(posState.searchQuery.toLowerCase()) ||
                    p.sku.toLowerCase().contains(posState.searchQuery.toLowerCase()) ||
                    (p.barcode != null && p.barcode!.toLowerCase().contains(posState.searchQuery.toLowerCase()));

                final matchCat = posState.selectedCategoryId == null || p.categoryId == posState.selectedCategoryId;
                return matchQuery && matchCat;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.packageOpen,
                        size: 48,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        posState.searchQuery.isNotEmpty
                            ? 'No se encontraron productos con "${posState.searchQuery}"'
                            : 'No hay productos disponibles',
                        style: AppTypography.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agrega productos en el módulo de Inventario / Catálogo para venderlos.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 650
                          ? 3
                          : constraints.maxWidth > 420
                              ? 2
                              : 1;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _PosProductCard(
                        product: product,
                        currency: currency,
                        onTap: () => posNotifier.addToCart(product),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PosProductCard extends StatelessWidget {
  final ProductModel product;
  final String currency;
  final VoidCallback onTap;

  const _PosProductCard({
    required this.product,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NubikoCard(
      enableHover: true,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen / Header del Producto
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B26) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      LucideIcons.package,
                      size: 36,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  if (product.categoryName != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Text(
                          product.categoryName!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.roundedSm,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Información del Producto
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currency${product.salePrice.toStringAsFixed(2)}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.barcode != null && product.barcode!.isNotEmpty)
                        Text(
                          product.barcode!,
                          style: AppTypography.labelSmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
