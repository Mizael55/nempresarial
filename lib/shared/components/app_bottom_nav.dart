import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final String currentRoute;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int currentIndex = 0;
    if (currentRoute == '/dashboard') currentIndex = 0;
    if (currentRoute == '/sales') currentIndex = 1;
    if (currentRoute == '/products') currentIndex = 2;
    if (currentRoute == '/inventory') currentIndex = 3;

    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      indicatorColor: AppColors.primary500.withValues(alpha: 0.15),
      elevation: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/sales');
            break;
          case 2:
            context.go('/products');
            break;
          case 3:
            context.go('/inventory');
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Módulo en desarrollo para la siguiente fase.'),
                duration: Duration(seconds: 1),
              ),
            );
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(LucideIcons.layoutDashboard),
          selectedIcon: Icon(LucideIcons.layoutDashboard, color: AppColors.primary500),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.shoppingCart),
          selectedIcon: Icon(LucideIcons.shoppingCart, color: AppColors.primary500),
          label: 'Ventas POS',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.package),
          selectedIcon: Icon(LucideIcons.package, color: AppColors.primary500),
          label: 'Productos',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.boxes),
          selectedIcon: Icon(LucideIcons.boxes, color: AppColors.primary500),
          label: 'Inventario',
        ),
      ],
    );
  }
}
