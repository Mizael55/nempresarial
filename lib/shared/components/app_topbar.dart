import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_manager.dart';
import '../widgets/offline_status_indicator.dart';

class AppTopbar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onOpenDrawer;

  const AppTopbar({
    super.key,
    this.onSearchTap,
    this.onOpenDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mobile menu toggle
          if (onOpenDrawer != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.menu, size: 20),
              onPressed: onOpenDrawer,
            ),
            const SizedBox(width: 8),
          ],

          // Active Branch Selector Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(
                color: isDark ? AppColors.slate700 : AppColors.slate200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.store, size: 14, color: AppColors.primary500),
                const SizedBox(width: 8),
                Text(
                  'Sucursal Principal',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Quick Search Button with Cmd+K hint
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: InkWell(
                  onTap: onSearchTap ?? () {},
                  borderRadius: AppRadius.roundedMd,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : AppColors.slate50,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 16,
                          color: isDark ? AppColors.slate500 : AppColors.slate400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Buscar productos, ventas, clientes...',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.slate500 : AppColors.slate400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate800 : AppColors.slate200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⌘ K',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.slate300 : AppColors.slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Offline Status Indicator
          const OfflineStatusIndicator(),
          const SizedBox(width: 12),

          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 18,
              color: isDark ? AppColors.amber400 : AppColors.slate600,
            ),
            tooltip: 'Cambiar modo claro/oscuro',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 4),

          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 18),
                tooltip: 'Notificaciones',
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.rose500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
