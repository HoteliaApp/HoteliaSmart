import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/models/room_model.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';

/// Vista de Mapa de Pisos en pantalla completa para la Smart TV [H-33].
class FloorMapView extends StatelessWidget {
  final List<RoomModel> rooms;
  final RoomStats stats;
  final bool isLoading;

  const FloorMapView({
    super.key,
    required this.rooms,
    required this.stats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);

    if (isLoading && rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final roomsByFloor = <int, List<RoomModel>>{};
    for (final room in rooms) {
      roomsByFloor.putIfAbsent(room.piso, () => <RoomModel>[]).add(room);
    }
    final floors = roomsByFloor.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg + 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.layers_rounded,
                color: AppColors.primary,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Text(
                'Mapa de Pisos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppPill(
                label: '${stats.total} habitaciones',
                color: statusColors.neutral,
                dense: true,
              ),
              const Spacer(),
              Flexible(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs + 2,
                  alignment: WrapAlignment.end,
                  children: [
                    _LegendPill(
                      label: 'Ocupadas',
                      count: stats.occupied,
                      color: statusColors.danger,
                    ),
                    _LegendPill(
                      label: 'Limpias',
                      count: stats.available,
                      color: statusColors.success,
                    ),
                    _LegendPill(
                      label: 'Sucias',
                      count: stats.dirty,
                      color: statusColors.warning,
                    ),
                    _LegendPill(
                      label: 'En Limpieza',
                      count: stats.maintenance,
                      color: statusColors.purple,
                    ),
                    _LegendPill(
                      label: 'Reservadas',
                      count: stats.reserved,
                      color: statusColors.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: floors.isEmpty
                ? const AppEmptyState(
                    icon: Icons.meeting_room_rounded,
                    title: 'Sin habitaciones registradas',
                  )
                : ListView.separated(
                    itemCount: floors.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md + 2),
                    itemBuilder: (context, index) {
                      final floor = floors[index];
                      return _FloorSection(
                        floor: floor,
                        rooms: roomsByFloor[floor]!,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FloorSection extends StatelessWidget {
  final int floor;
  final List<RoomModel> rooms;

  const _FloorSection({
    required this.floor,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final occupiedCount =
        rooms.where((r) => r.estado == RoomStatus.occupied).length;
    final dirtyCount = rooms.where((r) => r.estado == RoomStatus.dirty).length;

    return AppCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                label: floor > 0 ? 'Piso $floor' : 'Planta General',
                color: AppColors.primary,
                outlined: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '$occupiedCount/${rooms.length} ocupadas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (dirtyCount > 0) ...[
                const SizedBox(width: AppSpacing.sm + 2),
                AppPill(
                  label: '$dirtyCount por limpiar',
                  color: statusColors.warning,
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: rooms.map((room) => _RoomTile(room: room)).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;

  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = room.statusColor;

    return Container(
      width: 158,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Hab. ${room.numero}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            room.tipo.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPill(label: room.statusText, color: statusColor, dense: true),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _LegendPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.badge),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            '$label: $count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
