import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

class NubikoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableHover;
  final Color? backgroundColor;
  final Border? border;
  final double? width;
  final double? height;

  const NubikoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.enableHover = false,
    this.backgroundColor,
    this.border,
    this.width,
    this.height,
  });

  @override
  State<NubikoCard> createState() => _NubikoCardState();
}

class _NubikoCardState extends State<NubikoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final defaultBorder = Border.all(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 1,
    );

    final shadows = _isHovered && widget.enableHover
        ? (isDark ? AppShadows.darkCard : AppShadows.md)
        : (isDark ? const <BoxShadow>[] : AppShadows.sm);

    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHover) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enableHover) setState(() => _isHovered = false);
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: _isHovered && widget.enableHover
            ? const Offset(0, -0.015)
            : Offset.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? defaultBg,
          borderRadius: AppRadius.roundedLg,
          border: widget.border ?? defaultBorder,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.roundedLg,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}
}
