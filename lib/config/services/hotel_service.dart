import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio principal de datos de la Smart TV.
///
/// Se conecta a la misma instancia de Firebase / Firestore que usa
/// [hotel_app] y [hotel_wear_app], por lo que cualquier cambio realizado
/// se refleja en tiempo real en la pantalla Smart TV gracias a los
/// [Stream]s de Firestore.
///
/// Colecciones utilizadas:
///   • `rooms`  → estado de habitaciones por piso y ocupación [H-33]
///   • `tasks`  → tareas del personal (Kanban y tiempo medio de entrega)
///   • `alerts` → alertas activas (`isAcknowledged == false`) [H-23]
class HotelService {
  HotelService(this._firestore);

  final FirebaseFirestore _firestore;

  // ─────────────────────────────────────────────────────────────────────────
  // Colecciones
  // ─────────────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('alerts');

  // ─────────────────────────────────────────────────────────────────────────
  // Habitaciones — Mapa de Pisos y Ocupación [H-33]
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream en tiempo real de todas las habitaciones del hotel.
  /// Si [hotelId] está presente en el token JWT, filtra por `hotelId`.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRooms({
    String? hotelId,
  }) {
    Query<Map<String, dynamic>> query = _rooms;

    if (hotelId != null && hotelId.isNotEmpty) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }

    return query.snapshots();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tareas — Tablero Kanban y Métricas del Día
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream de tareas pendientes (`status == 'pending'`).
  /// Cuando [hotelId] está presente, filtra también por `hotelId` del claim.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingTasks({
    String? hotelId,
  }) =>
      _buildTaskQuery(status: 'pending', hotelId: hotelId).snapshots();

  /// Stream de tareas en progreso (`status == 'inProgress'`).
  /// Usa camelCase para coincidir con WearTaskStatus.inProgress.name del wear-app.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchInProgressTasks({
    String? hotelId,
  }) =>
      _buildTaskQuery(status: 'inProgress', hotelId: hotelId).snapshots();

  /// Stream de tareas completadas (`status == 'completed'`) para calcular
  /// el tiempo medio de entrega de habitaciones del día [H-33].
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCompletedTasks({
    int limit = 50,
    String? hotelId,
  }) =>
      _buildTaskQuery(status: 'completed', hotelId: hotelId)
          .limit(limit)
          .snapshots();

  /// Stream de las últimas [limit] tareas NO completadas.
  /// Usa 'inProgress' (camelCase) para coincidir con WearTaskStatus.inProgress.name.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveTasks({
    int limit = 20,
    String? hotelId,
  }) {
    Query<Map<String, dynamic>> query = _tasks.where(
      'status',
      whereIn: ['pending', 'inProgress'],
    );

    if (hotelId != null && hotelId.isNotEmpty) {
      query = query.where('hotelId', isEqualTo: hotelId);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.limit(limit).snapshots();
  }

  Query<Map<String, dynamic>> _buildTaskQuery({
    required String status,
    String? hotelId,
  }) {
    Query<Map<String, dynamic>> query = _tasks.where(
      'status',
      isEqualTo: status,
    );

    if (hotelId != null && hotelId.isNotEmpty) {
      // Se evita combinar dos `where` + `orderBy` en Firestore para no exigir
      // índices compuestos; el orden descendente se aplica en memoria.
      return query.where('hotelId', isEqualTo: hotelId);
    }

    return query.orderBy('createdAt', descending: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notificaciones / Alertas
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream de alertas activas en `/alerts` filtrando `isAcknowledged == false`.
  /// Si [hotelId] está presente en el token JWT, filtra también por `hotelId`.
  ///
  /// El ordenamiento por `createdAt` descendente se realiza en cliente para
  /// evitar requerir un índice compuesto en Firestore.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveNotifications({
    String? hotelId,
  }) {
    Query<Map<String, dynamic>> query = _notifications.where(
      'isAcknowledged',
      isEqualTo: false,
    );

    if (hotelId != null && hotelId.isNotEmpty) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }

    return query.limit(30).snapshots();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers (Riverpod)
// ─────────────────────────────────────────────────────────────────────────────

/// Provider de la instancia de [FirebaseFirestore].
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Provider del [HotelService].
/// Inyecta [firestoreProvider] para que el servicio sea testeable.
final hotelServiceProvider = Provider<HotelService>(
  (ref) => HotelService(ref.watch(firestoreProvider)),
);
