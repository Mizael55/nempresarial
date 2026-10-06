import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_badge.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../domain/dashboard_metrics.dart';

class LowStockCard extends StatelessWidget {
  final List<LowStockItem> items;
  final VoidCallback? onViewAll;

  const LowStockCard({
    super.key,
    required this.items,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NubikoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.amber500),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Alertas de Stock Bajo',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'Ver inventario',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              height: 16,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${item.sku}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.slate500 : AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NubikoBadge(
                    text: '${item.currentStock.toInt()} / mín ${item.minStock.toInt()}',
                    variant: NubikoBadgeVariant.danger,
                    icon: LucideIcons.alertCircle,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
