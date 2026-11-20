import 'package:flutter/material.dart';
import 'package:hotel_smart_app/models/room_model.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';

/// Vista de Mapa de Pisos en pantalla completa para la Smart TV [H-33].
///
/// Agrupa las habitaciones por piso y muestra su estado de ocupación y limpieza
/// con código de colores de alto contraste para lectura a distancia.
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
    if (isLoading && rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF661A)),
      );
    }

    final roomsByFloor = <int, List<RoomModel>>{};
    for (final room in rooms) {
      roomsByFloor.putIfAbsent(room.piso, () => <RoomModel>[]).add(room);
    }
    final floors = roomsByFloor.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado y Leyenda de Estados ──────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.layers_rounded,
                color: Color(0xFFFF661A),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Mapa de Pisos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stats.total} habitaciones',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    _LegendPill(
                      label: 'Ocupadas',
                      count: stats.occupied,
                      color: const Color(0xFFFF9800),
                    ),
                    _LegendPill(
                      label: 'Limpias',
                      count: stats.available,
                      color: const Color(0xFF4CAF50),
                    ),
                    _LegendPill(
                      label: 'Sucias',
                      count: stats.dirty,
                      color: const Color(0xFFF44336),
                    ),
                    _LegendPill(
                      label: 'En Limpieza',
                      count: stats.maintenance,
                      color: const Color(0xFF9C27B0),
                    ),
                    _LegendPill(
                      label: 'Reservadas',
                      count: stats.reserved,
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Lista de Pisos ───────────────────────────────────────────────
          Expanded(
            child: floors.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: floors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final floor = floors[index];
                      final floorRooms = roomsByFloor[floor]!;
                      return _FloorSection(
                        floor: floor,
                        rooms: floorRooms,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 52,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin habitaciones registradas',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
    final occupiedCount =
        rooms.where((r) => r.estado == RoomStatus.occupied).length;
    final dirtyCount = rooms.where((r) => r.estado == RoomStatus.dirty).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161825),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF661A).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF661A).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  floor > 0 ? 'Piso $floor' : 'Planta General',
                  style: const TextStyle(
                    color: Color(0xFFFF8A4C),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$occupiedCount/${rooms.length} ocupadas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (dirtyCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$dirtyCount por limpiar',
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
    final statusColor = room.statusColor;

    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030),
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hab. ${room.numero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            room.tipo.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              room.statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
