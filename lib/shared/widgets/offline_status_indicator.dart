import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/offline_sync_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

class OfflineStatusIndicator extends ConsumerWidget {
  const OfflineStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(offlineSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color dotColor;
    String label;
    Color bgColor;

    switch (syncState.state) {
      case SyncState.synced:
        dotColor = AppColors.emerald500;
        label = 'En línea';
        bgColor = isDark ? AppColors.emerald500.withOpacity(0.12) : AppColors.emerald50;
        break;
      case SyncState.syncing:
        dotColor = AppColors.amber500;
        label = 'Sincronizando...';
        bgColor = isDark ? AppColors.amber500.withOpacity(0.12) : AppColors.amber50;
        break;
      case SyncState.offline:
        dotColor = AppColors.rose500;
        label = 'Sin conexión';
        bgColor = isDark ? AppColors.rose500.withOpacity(0.12) : AppColors.rose50;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: dotColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (syncState.pendingOperationsCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '(${syncState.pendingOperationsCount})',
              style: AppTypography.labelSmall.copyWith(
                color: dotColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
