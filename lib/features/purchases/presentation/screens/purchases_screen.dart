import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/purchases_controller.dart';
import '../widgets/purchases_list_view.dart';
import '../widgets/new_purchase_view.dart';
import '../widgets/suppliers_list_view.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const PurchasesScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newPurchaseState = ref.watch(newPurchaseControllerProvider);

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
                            child: const Icon(LucideIcons.truck, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Compras & Proveedores',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recepción de mercancía, reabastecimiento y cuentas por pagar',
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
                        const Tab(
                          child: Row(
                            children: [
                              Icon(LucideIcons.receipt, size: 15),
                              SizedBox(width: 6),
                              Text('Órdenes de Compra'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            children: [
                              const Icon(LucideIcons.plusCircle, size: 15),
                              const SizedBox(width: 6),
                              const Text('Registrar Compra'),
                              if (newPurchaseState.items.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${newPurchaseState.totalItemsCount}',
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
                              Icon(LucideIcons.building2, size: 15),
                              SizedBox(width: 6),
                              Text('Proveedores & CXP'),
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

              // Contenido de las pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const PurchasesListView(),
                    NewPurchaseView(
                      onPurchaseCompleted: () {
                        _tabController.animateTo(0);
                      },
                    ),
                    const SuppliersListView(),
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
