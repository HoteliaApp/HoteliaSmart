import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';

/// Tarjeta visual para cada tarea dentro del tablero Kanban.
class TaskCard extends StatelessWidget {
  final String serviceType;
  final String assignedTo;
  final String room;
  final String timeLabel;
  final String status;

  const TaskCard({
    super.key,
    required this.serviceType,
    required this.assignedTo,
    required this.room,
    required this.timeLabel,
    required this.status,
  });

  String get _serviceLabel => switch (serviceType.toLowerCase()) {
        'cleaning' => 'Limpieza',
        'maintenance' => 'Mantenimiento',
        'inspection' => 'Inspección',
        'delivery' => 'Entrega',
        'guest_request' => 'Sol. Huésped',
        _ => serviceType,
      };

  Color _serviceColor(BuildContext context) {
    final statusColors = AppStatusColors.of(context);
    return switch (serviceType.toLowerCase()) {
      'limpieza' || 'cleaning' => statusColors.info,
      'mantenimiento' || 'maintenance' => AppColors.primary,
      'inspección' || 'inspection' => statusColors.purple,
      'entrega' || 'delivery' || 'room service' => statusColors.success,
      'sol. huésped' || 'guest_request' => statusColors.warning,
      _ => statusColors.neutral,
    };
  }

  IconData get _serviceIcon {
    switch (serviceType.toLowerCase()) {
      case 'limpieza':
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'mantenimiento':
      case 'maintenance':
        return Icons.build_rounded;
      case 'inspección':
      case 'inspection':
        return Icons.search_rounded;
      case 'entrega':
      case 'delivery':
        return Icons.local_shipping_rounded;
      case 'sol. huésped':
      case 'guest_request':
        return Icons.support_agent_rounded;
      case 'room service':
        return Icons.room_service_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _serviceColor(context);

    return AppCard(
      accent: color,
      surfaceColor: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: _serviceIcon,
                color: color,
                size: 36,
                iconSize: AppIconSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  _serviceLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: AppIconSize.xs,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  assignedTo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              Icon(
                Icons.door_front_door_rounded,
                size: AppIconSize.xs,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'Hab. $room',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
