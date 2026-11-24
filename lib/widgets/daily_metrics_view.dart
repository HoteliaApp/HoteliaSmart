import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';

/// Panel de Estadísticas y Métricas Generales del Día en pantalla completa [H-33].
class DailyMetricsView extends StatelessWidget {
  final DailyKpiMetrics metrics;

  const DailyMetricsView({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final stats = metrics.roomStats;
    final occupancyProgress =
        (metrics.occupancyPercentage / 100.0).clamp(0.0, 1.0);
    final deliveryStatus = _deliveryStatusBadge(
      metrics.averageDeliveryMinutes,
      statusColors,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.primary,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Estadísticas del Día',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  'Monitoreo General de Limpieza y Ocupación',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg + 2),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroKpiCard(
                  accentColor: AppColors.primary,
                  title: 'Porcentaje de Ocupación',
                  subtitle:
                      '${stats.occupied} de ${stats.total} habitaciones ocupadas',
                  trailing: SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: occupancyProgress,
                          strokeWidth: 10,
                          backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        Center(
                          child: Text(
                            metrics.occupancyLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  footer: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppPill(
                        label: 'Disponibles: ${stats.available}',
                        color: statusColors.success,
                        dense: true,
                      ),
                      AppPill(
                        label: 'Reservadas: ${stats.reserved}',
                        color: statusColors.info,
                        dense: true,
                      ),
                      AppPill(
                        label: 'Por atender: ${stats.needsAttention}',
                        color: statusColors.danger,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg + 2),
              Expanded(
                child: _HeroKpiCard(
                  accentColor: statusColors.info,
                  title: 'Tiempo Medio de Entrega',
                  subtitle:
                      '${metrics.completedTodayCount} habitaciones entregadas hoy',
                  trailing: AppCard(
                    accent: statusColors.info,
                    tinted: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg + 4,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: statusColors.info,
                          size: AppIconSize.md,
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Text(
                          metrics.averageDeliveryLabel,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  footer: Row(
                    children: [
                      AppPill(
                        label: deliveryStatus.label,
                        color: deliveryStatus.color,
                        outlined: true,
                        dense: true,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Meta operativa: ≤ 30 min por habitación',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg + 4),

          Row(
            children: [
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Habitaciones Sucias',
                  value: '${stats.dirty}',
                  color: statusColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.build_circle_rounded,
                  label: 'En Limpieza',
                  value: '${stats.maintenance}',
                  color: statusColors.purple,
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Listas / Limpias',
                  value: '${stats.available}',
                  color: statusColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.pending_actions_rounded,
                  label: 'Tareas Pendientes',
                  value: '${metrics.pendingTasksCount}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.trending_up_rounded,
                  label: 'En Progreso',
                  value: '${metrics.inProgressTasksCount}',
                  color: statusColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _deliveryStatusBadge(
    double? avgMinutes,
    AppStatusColors statusColors,
  ) {
    if (avgMinutes == null) {
      return (label: 'Sin entregas registradas hoy', color: statusColors.neutral);
    }
    if (avgMinutes <= 30.0) {
      return (label: 'Rendimiento óptimo', color: statusColors.success);
    }
    return (label: 'Tiempo por encima de meta', color: statusColors.warning);
  }
}

class _HeroKpiCard extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget footer;

  const _HeroKpiCard({
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AppCard(
      accent: accentColor,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.xl - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.lg + 2),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md + 2),
          footer,
        ],
      ),
    );
  }
}

class _SecondaryMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SecondaryMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      accent: color,
      tinted: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBadge(
            icon: icon,
            color: color,
            size: 40,
            iconSize: AppIconSize.sm,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
