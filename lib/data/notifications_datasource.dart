import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Fuente de datos de notificaciones/alertas para la Smart TV.
///
/// Conecta con la colección `/alerts` de Firestore en tiempo real filtrando
/// `isAcknowledged == false`. Limita a 10 resultados y ordena por fecha
/// descendente en memoria.
class NotificationsDatasource {
  final FirebaseFirestore _firestore;

  NotificationsDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('alerts');

  // ─────────────────────────────────────────────────────────────────────────
  // Stream en tiempo real (Firestore)
  // ─────────────────────────────────────────────────────────────────────────

  /// Stream de alertas activas (`isAcknowledged == false`) desde Firestore.
  Stream<List<NotificationModel>> watchActiveNotifications({String? hotelId}) {
    Query<Map<String, dynamic>> query = _notifications.where(
      'isAcknowledged',
      isEqualTo: false,
    );

    if (hotelId != null && hotelId.isNotEmpty) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }

    return query.limit(30).snapshots().map((snapshot) {
      final alerts = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.id, doc.data()))
          .where((n) => n.active && !n.isAcknowledged)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return alerts.take(10).toList();
    });
  }
}
