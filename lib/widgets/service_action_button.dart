import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';

class ServiceActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isHighlighted;
  final VoidCallback onTap;

  const ServiceActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppCard(
      accent: isHighlighted ? AppColors.primary : null,
      tinted: isHighlighted,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconBadge(
            icon: icon,
            color: isHighlighted ? AppColors.primary : cs.onSurfaceVariant,
            size: 64,
            iconSize: AppIconSize.lg,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? AppColors.primary : cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
