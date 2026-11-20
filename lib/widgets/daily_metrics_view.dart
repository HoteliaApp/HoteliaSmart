import 'package:flutter/material.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';

/// Panel de Estadísticas y Métricas Generales del Día en pantalla completa [H-33].
///
/// Muestra el porcentaje de ocupación, el tiempo medio de entrega de
/// habitaciones y el resumen en tiempo real de limpieza y tareas operativas.
class DailyMetricsView extends StatelessWidget {
  final DailyKpiMetrics metrics;

  const DailyMetricsView({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final stats = metrics.roomStats;
    final occupancyProgress = (metrics.occupancyPercentage / 100.0).clamp(0.0, 1.0);
    final deliveryStatus = _deliveryStatusBadge(metrics.averageDeliveryMinutes);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ───────────────────────────────────────────────────
          const Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Color(0xFF3B82F6),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Estadísticas del Día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Monitoreo General de Limpieza y Ocupación',
                style: TextStyle(
                  color: Color(0xFF9EA3B2),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── KPIs Principales: Ocupación y Tiempo Medio de Entrega ────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta 1: Porcentaje de Ocupación
              Expanded(
                child: _HeroKpiCard(
                  accentColor: const Color(0xFFFF661A),
                  title: 'Porcentaje de Ocupación',
                  subtitle:
                      '${stats.occupied} de ${stats.total} habitaciones ocupadas',
                  trailing: SizedBox(
                    width: 108,
                    height: 108,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: occupancyProgress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF661A),
                          ),
                        ),
                        Center(
                          child: Text(
                            metrics.occupancyLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  footer: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _MiniStatChip(
                        label: 'Disponibles',
                        value: '${stats.available}',
                        color: const Color(0xFF4CAF50),
                      ),
                      _MiniStatChip(
                        label: 'Reservadas',
                        value: '${stats.reserved}',
                        color: const Color(0xFF2196F3),
                      ),
                      _MiniStatChip(
                        label: 'Por atender',
                        value: '${stats.needsAttention}',
                        color: const Color(0xFFF44336),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),

              // Tarjeta 2: Tiempo Medio de Entrega de Habitaciones
              Expanded(
                child: _HeroKpiCard(
                  accentColor: const Color(0xFF3B82F6),
                  title: 'Tiempo Medio de Entrega',
                  subtitle:
                      '${metrics.completedTodayCount} habitaciones entregadas hoy',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFF93C5FD),
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          metrics.averageDeliveryLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  footer: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: deliveryStatus.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: deliveryStatus.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          deliveryStatus.label,
                          style: TextStyle(
                            color: deliveryStatus.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Meta operativa: ≤ 30 min por habitación',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
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

          const SizedBox(height: 20),

          // ── Resumen Operativo de Limpieza y Tareas ───────────────────────
          Row(
            children: [
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Habitaciones Sucias',
                  value: '${stats.dirty}',
                  color: const Color(0xFFF44336),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.build_circle_outlined,
                  label: 'En Limpieza',
                  value: '${stats.maintenance}',
                  color: const Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Listas / Limpias',
                  value: '${stats.available}',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.pending_actions_rounded,
                  label: 'Tareas Pendientes',
                  value: '${metrics.pendingTasksCount}',
                  color: const Color(0xFFFF661A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SecondaryMetricTile(
                  icon: Icons.trending_up_rounded,
                  label: 'En Progreso',
                  value: '${metrics.inProgressTasksCount}',
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _deliveryStatusBadge(double? avgMinutes) {
    if (avgMinutes == null) {
      return (label: 'Sin entregas registradas hoy', color: const Color(0xFF9EA3B2));
    }
    if (avgMinutes <= 30.0) {
      return (label: 'Rendimiento óptimo', color: const Color(0xFF4CAF50));
    }
    return (label: 'Tiempo por encima de meta', color: const Color(0xFFFF9800));
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161825),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              trailing,
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161825),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
