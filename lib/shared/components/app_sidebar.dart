import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class SidebarItemData {
  final String label;
  final IconData icon;
  final String route;
  final String? badge;

  const SidebarItemData({
    required this.label,
    required this.icon,
    required this.route,
    this.badge,
  });
}

class AppSidebar extends ConsumerWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  static const List<SidebarItemData> mainItems = [
    SidebarItemData(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/dashboard'),
    SidebarItemData(label: 'Ventas / POS', icon: LucideIcons.shoppingCart, route: '/sales'),
    SidebarItemData(label: 'Productos', icon: LucideIcons.package, route: '/products'),
    SidebarItemData(label: 'Inventario', icon: LucideIcons.boxes, route: '/inventory'),
    SidebarItemData(label: 'Gastos', icon: LucideIcons.receipt, route: '/expenses'),
    SidebarItemData(label: 'Configuración', icon: LucideIcons.settings, route: '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authControllerProvider).user;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary600,
                    borderRadius: AppRadius.roundedMd,
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.boxes, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUBIKO',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Enterprise Edition',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              itemCount: mainItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 3),
              itemBuilder: (context, index) {
                final item = mainItems[index];
                final isSelected = currentRoute == item.route;

                return _SidebarItemTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    }
                    context.go(item.route);
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // User Footer & Theme Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary600,
                  child: Text(
                    user != null && user.fullName.isNotEmpty
                        ? user.fullName.substring(0, 1).toUpperCase()
                        : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'Administrador',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? 'admin@nubiko.app',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.slate500 : AppColors.slate400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  tooltip: 'Cerrar sesión',
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemTile extends StatefulWidget {
  final SidebarItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    if (widget.isSelected) {
      bg = isDark ? AppColors.primary600.withOpacity(0.2) : AppColors.primary50;
      fg = isDark ? AppColors.primary400 : AppColors.primary600;
    } else if (_isHovered) {
      bg = isDark ? AppColors.slate800 : AppColors.slate100;
      fg = isDark ? Colors.white : AppColors.slate900;
    } else {
      bg = Colors.transparent;
      fg = isDark ? AppColors.slate400 : AppColors.slate600;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.roundedMd,
          border: widget.isSelected
              ? Border.all(
                  color: isDark ? AppColors.primary500.withOpacity(0.4) : AppColors.primary200,
                  width: 1,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.roundedMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    widget.item.icon,
                    size: 18,
                    color: fg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: fg,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.rose500.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.item.badge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.rose500,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
