import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import 'nubiko_card.dart';

class NubikoStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? comparisonText;
  final double? percentageChange;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;

  const NubikoStatCard({
    super.key,
    required this.title,
    required this.value,
    this.comparisonText,
    this.percentageChange,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIconColor = iconColor ?? AppColors.primary500;
    final primaryIconBg = iconBackgroundColor ??
        (isDark ? primaryIconColor.withOpacity(0.15) : primaryIconColor.withOpacity(0.1));

    final isPositive = (percentageChange ?? 0) >= 0;
    final trendColor = isPositive ? AppColors.emerald500 : AppColors.rose500;
    final trendBg = isDark
        ? trendColor.withOpacity(0.15)
        : (isPositive ? AppColors.emerald50 : AppColors.rose50);

    return NubikoCard(
      onTap: onTap,
      enableHover: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryIconBg,
                  borderRadius: AppRadius.roundedMd,
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: primaryIconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: isDark ? Colors.white : AppColors.slate900,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (percentageChange != null || comparisonText != null)
            Row(
              children: [
                if (percentageChange != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: trendBg,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14,
                          color: trendColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${percentageChange!.toStringAsFixed(1)}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (comparisonText != null)
                  Expanded(
                    child: Text(
                      comparisonText!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
