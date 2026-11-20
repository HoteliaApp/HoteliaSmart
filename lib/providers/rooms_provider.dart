import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_smart_app/config/services/hotel_service.dart';
import 'package:hotel_smart_app/models/room_model.dart';
import 'package:hotel_smart_app/models/task_model.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';
import 'package:hotel_smart_app/providers/tasks_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers de habitaciones en tiempo real (Firestore) [H-33]
// ─────────────────────────────────────────────────────────────────────────────

/// Emite la lista completa de habitaciones desde Firestore en tiempo real,
/// filtrada por el claim `hotelId` cuando está presente.
final roomsStreamProvider = StreamProvider<List<RoomModel>>((ref) {
  final service = ref.watch(hotelServiceProvider);
  final hotelId = ref.watch(hotelIdClaimProvider);
  return service.watchRooms(hotelId: hotelId).map(_snapshotToRooms);
});

List<RoomModel> _snapshotToRooms(
  QuerySnapshot<Map<String, dynamic>> snapshot,
) {
  final rooms = snapshot.docs
      .map((doc) => RoomModel.fromFirestore(doc.id, doc.data()))
      .toList()
    ..sort((a, b) {
      final floorCmp = a.piso.compareTo(b.piso);
      if (floorCmp != 0) return floorCmp;
      return a.numero.compareTo(b.numero);
    });
  return rooms;
}

/// Emite habitaciones filtradas por [floor] derivadas de [roomsStreamProvider].
final roomsByFloorProvider = Provider.family<List<RoomModel>, int>((ref, floor) {
  final rooms = ref.watch(roomsStreamProvider).valueOrNull ?? const <RoomModel>[];
  return rooms.where((r) => r.piso == floor).toList();
});

/// Lista de pisos únicos disponibles, ordenados ascendentemente.
final availableFloorsProvider = Provider<List<int>>((ref) {
  final rooms = ref.watch(roomsStreamProvider).valueOrNull ?? const <RoomModel>[];
  final floors = rooms.map((r) => r.piso).toSet().toList()..sort();
  return floors;
});

// ─────────────────────────────────────────────────────────────────────────────
// Estadísticas de habitaciones y KPIs del día [H-33]
// ─────────────────────────────────────────────────────────────────────────────

/// Modelo con los contadores de habitaciones por estado.
class RoomStats {
  final int occupied;
  final int available;
  final int dirty;
  final int maintenance;
  final int reserved;
  final int total;

  const RoomStats({
    this.occupied = 0,
    this.available = 0,
    this.dirty = 0,
    this.maintenance = 0,
    this.reserved = 0,
    this.total = 0,
  });

  factory RoomStats.fromRooms(List<RoomModel> rooms) {
    return RoomStats(
      occupied: rooms.where((r) => r.estado == RoomStatus.occupied).length,
      available: rooms.where((r) => r.estado == RoomStatus.available).length,
      dirty: rooms.where((r) => r.estado == RoomStatus.dirty).length,
      maintenance:
          rooms.where((r) => r.estado == RoomStatus.maintenance).length,
      reserved: rooms.where((r) => r.estado == RoomStatus.reserved).length,
      total: rooms.length,
    );
  }

  /// Habitaciones que requieren atención (sucias + en limpieza/mantenimiento).
  int get needsAttention => dirty + maintenance;

  /// Reservas próximas (reserved).
  int get upcoming => reserved;

  /// Porcentaje de ocupación (0.0 a 100.0).
  double get occupancyPercentage {
    if (total == 0) return 0.0;
    return (occupied / total) * 100.0;
  }
}

/// Métricas generales del día para el panel de monitoreo [H-33].
class DailyKpiMetrics {
  final RoomStats roomStats;
  final double? averageDeliveryMinutes;
  final int completedTodayCount;
  final int pendingTasksCount;
  final int inProgressTasksCount;

  const DailyKpiMetrics({
    required this.roomStats,
    required this.averageDeliveryMinutes,
    required this.completedTodayCount,
    required this.pendingTasksCount,
    required this.inProgressTasksCount,
  });

  /// Calcula las métricas generales del día a partir de habitaciones y tareas.
  factory DailyKpiMetrics.fromData({
    required List<RoomModel> rooms,
    required List<TaskModel> completedTasks,
    required int pendingTasksCount,
    required int inProgressTasksCount,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final startOfDay = DateTime(reference.year, reference.month, reference.day);

    final todayCompleted = completedTasks.where((task) {
      final ts = task.completedAt ?? task.createdAt;
      return !ts.isBefore(startOfDay);
    }).toList();

    final durationsMinutes = <double>[];
    for (final task in todayCompleted) {
      final duration = task.completionDuration;
      if (duration != null) {
        durationsMinutes.add(duration.inSeconds / 60.0);
      }
    }

    final avgMinutes = durationsMinutes.isEmpty
        ? null
        : durationsMinutes.reduce((a, b) => a + b) / durationsMinutes.length;

    return DailyKpiMetrics(
      roomStats: RoomStats.fromRooms(rooms),
      averageDeliveryMinutes: avgMinutes,
      completedTodayCount: todayCompleted.length,
      pendingTasksCount: pendingTasksCount,
      inProgressTasksCount: inProgressTasksCount,
    );
  }

  /// Porcentaje de ocupación (0.0 a 100.0).
  double get occupancyPercentage => roomStats.occupancyPercentage;

  /// Etiqueta formateada del porcentaje de ocupación (ej. `75.0%`).
  String get occupancyLabel => '${occupancyPercentage.toStringAsFixed(1)}%';

  /// Etiqueta formateada del tiempo medio de entrega (ej. `24 min` o `-- min`).
  String get averageDeliveryLabel {
    if (averageDeliveryMinutes == null) return '-- min';
    return '${averageDeliveryMinutes!.round()} min';
  }
}

/// Estadísticas de habitaciones calculadas en tiempo real.
final roomStatsProvider = Provider<RoomStats>((ref) {
  final rooms = ref.watch(roomsStreamProvider).valueOrNull ?? const <RoomModel>[];
  return RoomStats.fromRooms(rooms);
});

/// Métricas generales del día (ocupación y tiempo medio de entrega) [H-33].
final dailyKpiMetricsProvider = Provider<DailyKpiMetrics>((ref) {
  final rooms = ref.watch(roomsStreamProvider).valueOrNull ?? const <RoomModel>[];
  final completedTasks =
      ref.watch(completedTasksStreamProvider).valueOrNull ?? const <TaskModel>[];
  final pendingTasks =
      ref.watch(pendingTasksStreamProvider).valueOrNull ?? const <TaskModel>[];
  final inProgressTasks =
      ref.watch(inProgressTasksStreamProvider).valueOrNull ?? const <TaskModel>[];

  return DailyKpiMetrics.fromData(
    rooms: rooms,
    completedTasks: completedTasks,
    pendingTasksCount: pendingTasks.length,
    inProgressTasksCount: inProgressTasks.length,
  );
});
