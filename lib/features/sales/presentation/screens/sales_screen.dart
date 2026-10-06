import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/sales_controller.dart';
import '../widgets/pos_product_selector.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/sales_history_view.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final posState = ref.watch(posControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra Superior Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 880;
                  final headerText = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: AppRadius.roundedMd,
                            ),
                            child: const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Ventas & POS',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Facturación rápida y control de comprobantes',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );

                  final tabsWidget = Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppRadius.roundedLg,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.roundedLg,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      tabs: [
                        Tab(
                          child: Row(
                            children: [
                              const Icon(LucideIcons.shoppingBag, size: 15),
                              const SizedBox(width: 6),
                              const Text('Punto de Venta (POS)'),
                              if (posState.totalItemsCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${posState.totalItemsCount}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Tab(
                          child: Row(
                            children: [
                              Icon(LucideIcons.receiptText, size: 15),
                              SizedBox(width: 6),
                              Text('Historial de Facturas'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: headerText),
                        tabsWidget,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        headerText,
                        const SizedBox(height: 12),
                        tabsWidget,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 18),

              // Contenido Principal
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab 1: POS (Layout Split Responsive)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 700;

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Izquierda: Catálogo Interactivo
                              const Expanded(
                                flex: 6,
                                child: PosProductSelector(),
                              ),
                              const SizedBox(width: 18),
                              // Derecha: Panel de Orden y Cobro
                              const Expanded(
                                flex: 4,
                                child: PosCartPanel(),
                              ),
                            ],
                          );
                        } else {
                          // Móvil / Pantallas pequeñas
                          return DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(icon: Icon(LucideIcons.package), text: 'Catálogo'),
                                    Tab(icon: Icon(LucideIcons.shoppingCart), text: 'Orden'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Expanded(
                                  child: TabBarView(
                                    children: [
                                      PosProductSelector(),
                                      PosCartPanel(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),

                    // Tab 2: Historial de Ventas
                    const SalesHistoryView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
