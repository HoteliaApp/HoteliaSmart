import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
//  HOTELIA UI KIT — SMART TV
//  Copia de HoteliaMovil/lib/presentation/widgets/shared/app_ui.dart
// ════════════════════════════════════════════════════════════════════════════

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIconSize.md, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
        if (subtitle != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: AppPill(
              key: ValueKey<String>(subtitle!),
              label: subtitle!,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class AppPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;
  final bool dense;

  const AppPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.outlined = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = (dense
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xs : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.badge),
        borderRadius: AppRadius.mdAll,
        border: outlined ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? AppIconSize.xs : AppIconSize.sm, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.badge),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.48),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool tinted;
  final double radius;
  final Color? surfaceColor;

  const AppCard({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.tinted = false,
    this.radius = AppRadius.md,
    this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseSurface = surfaceColor ?? theme.colorScheme.surface;
    final borderColor = accent != null
        ? accent!.withValues(alpha: AppAlpha.borderDark)
        : theme.dividerColor.withValues(alpha: 0.65);
    final bg = tinted && accent != null
        ? Color.alphaBlend(accent!.withValues(alpha: AppAlpha.tint), baseSurface)
        : baseSurface;
    final br = BorderRadius.circular(radius);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: bg,
        borderRadius: br,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(color: borderColor),
              boxShadow: tinted ? null : AppShadows.soft,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.hero, color: c),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: c),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final String? title;

  const AppInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      accent: color,
      tinted: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppIconSize.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
