import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

enum NubikoBadgeVariant { success, warning, danger, info, neutral }

class NubikoBadge extends StatelessWidget {
  final String text;
  final NubikoBadgeVariant variant;
  final IconData? icon;

  const NubikoBadge({
    super.key,
    required this.text,
    this.variant = NubikoBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (variant) {
      case NubikoBadgeVariant.success:
        bg = isDark ? AppColors.emerald500.withOpacity(0.15) : AppColors.emerald50;
        fg = isDark ? AppColors.emerald400 : AppColors.emerald700;
        break;
      case NubikoBadgeVariant.warning:
        bg = isDark ? AppColors.amber500.withOpacity(0.15) : AppColors.amber50;
        fg = isDark ? AppColors.amber400 : AppColors.amber700;
        break;
      case NubikoBadgeVariant.danger:
        bg = isDark ? AppColors.rose500.withOpacity(0.15) : AppColors.rose50;
        fg = isDark ? AppColors.rose400 : AppColors.rose700;
        break;
      case NubikoBadgeVariant.info:
        bg = isDark ? AppColors.primary500.withOpacity(0.15) : AppColors.primary50;
        fg = isDark ? AppColors.primary400 : AppColors.primary700;
        break;
      case NubikoBadgeVariant.neutral:
        bg = isDark ? AppColors.slate800 : AppColors.slate100;
        fg = isDark ? AppColors.slate300 : AppColors.slate700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
