import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';

enum NubikoButtonVariant { primary, secondary, outline, ghost, danger }

class NubikoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final NubikoButtonVariant variant;
  final double? width;
  final double height;
  final bool isFullWidth;

  const NubikoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.variant = NubikoButtonVariant.primary,
    this.width,
    this.height = 46.0,
    this.isFullWidth = false,
  });

  @override
  State<NubikoButton> createState() => _NubikoButtonState();
}

class _NubikoButtonState extends State<NubikoButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case NubikoButtonVariant.primary:
        backgroundColor = _isHovered ? AppColors.primary700 : AppColors.primary600;
        foregroundColor = Colors.white;
        shadows = isEnabled && _isHovered ? AppShadows.primaryGlow : AppShadows.sm;
        break;
      case NubikoButtonVariant.secondary:
        backgroundColor = isDark
            ? (_isHovered ? AppColors.slate700 : AppColors.slate800)
            : (_isHovered ? AppColors.slate200 : AppColors.slate100);
        foregroundColor = isDark ? Colors.white : AppColors.slate900;
        break;
      case NubikoButtonVariant.outline:
        backgroundColor = _isHovered
            ? (isDark ? AppColors.slate800 : AppColors.slate100)
            : Colors.transparent;
        foregroundColor = isDark ? Colors.white : AppColors.slate800;
        borderSide = BorderSide(
          color: isDark ? AppColors.slate700 : AppColors.slate300,
          width: 1.2,
        );
        break;
      case NubikoButtonVariant.ghost:
        backgroundColor = _isHovered
            ? (isDark ? AppColors.slate800 : AppColors.slate100)
            : Colors.transparent;
        foregroundColor = isDark ? AppColors.slate300 : AppColors.slate700;
        break;
      case NubikoButtonVariant.danger:
        backgroundColor = _isHovered ? AppColors.rose600 : AppColors.rose500;
        foregroundColor = Colors.white;
        break;
    }

    if (!isEnabled) {
      backgroundColor = isDark ? AppColors.slate800 : AppColors.slate200;
      foregroundColor = isDark ? AppColors.slate600 : AppColors.slate400;
      shadows = [];
      borderSide = BorderSide.none;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: 18, color: foregroundColor),
        ],
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: widget.isFullWidth ? double.infinity : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.roundedMd,
          border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: AppRadius.roundedMd,
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
