import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_smart_app/config/services/hotel_service.dart';
import 'package:hotel_smart_app/models/notification_model.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';

// ────────────────────────────────────────────────────────────────────────────────
// Provider de notificaciones
// ────────────────────────────────────────────────────────────────────────────────

/// Stream de alertas activas en tiempo real desde `/alerts`
/// (`isAcknowledged == false` y opcionalmente `hotelId`).
final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final service = ref.watch(hotelServiceProvider);
  final hotelId = ref.watch(hotelIdClaimProvider);
  return service
      .watchActiveNotifications(hotelId: hotelId)
      .map(_snapshotToNotifications);
});

/// Convierte un [QuerySnapshot] en `List<NotificationModel>`, ordenada por
/// `createdAt` descendente y limitada a 10 para evitar desbordamiento visual.
List<NotificationModel> _snapshotToNotifications(
  QuerySnapshot<Map<String, dynamic>> snapshot,
) {
  final alerts = snapshot.docs
      .map((doc) => NotificationModel.fromFirestore(doc.id, doc.data()))
      .where((n) => n.active && !n.isAcknowledged)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return alerts.take(10).toList();
}
