import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// The standard surface used across the app: rounded, softly shadowed, with
/// an optional tap ripple. Keeps elevation and radius consistent everywhere.
///
/// By default it carries a crisp hairline border and the prominent, blue-tinted
/// [AppShadows.card] so it reads as a floating surface on the gradient
/// background. Set [glass] for a translucent, frosted-glass treatment that lets
/// the background wash blur through.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;
  final List<BoxShadow>? shadows;
  final Border? border;

  /// Frosted-glass surface: translucent fill + backdrop blur + light border.
  final bool glass;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.color,
    this.gradient,
    this.onTap,
    this.radius = AppRadius.lg,
    this.shadows,
    this.border,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // A subtle border gives cards definition against the gradient. Glass cards
    // use a lighter, brighter edge to read as a lit pane.
    final resolvedBorder = border ??
        Border.all(
          color: glass ? AppColors.glassBorder : AppColors.hairline,
          width: glass ? 1.2 : 0.8,
        );

    Widget inner = AnimatedContainer(
      duration: AppDuration.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null
            ? null
            : (color ??
                (glass ? AppColors.glassFill : AppColors.surface)),
        gradient: gradient,
        borderRadius: borderRadius,
        border: resolvedBorder,
      ),
      child: child,
    );

    if (glass) {
      inner = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: inner,
        ),
      );
    }

    // Shadows live on a wrapping box so they stay crisp outside any clip.
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadows ?? AppShadows.card,
      ),
      child: inner,
    );

    if (onTap == null) {
      return Container(margin: margin, child: content);
    }
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: AppColors.alpha(AppColors.primary, 0.06),
          child: content,
        ),
      ),
    );
  }
}

/// A row title used to head each Home/Calendar section, with an optional
/// trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: AppText.h2),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A small rounded pill/chip used for tags, markers and legends.
class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const Pill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 2),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
