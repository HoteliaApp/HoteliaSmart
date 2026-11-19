/// Modelo de notificación / alerta para la Smart TV.
///
/// Representa un documento de la colección `alerts` en Firestore.
/// Se limitan a 10 resultados ordenados por fecha descendente para
/// evitar desbordamiento visual en la pantalla.
class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String relatedRoom;
  final DateTime createdAt;
  final bool active;
  final String priority;
  final String type;
  final String? hotelId;
  final bool isAcknowledged;

  static const Set<String> _highPriorityValues = {
    'high',
    'alta',
    'critical',
    'critica',
    'crítica',
    'urgent',
    'urgente',
  };

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.relatedRoom,
    required this.createdAt,
    this.active = true,
    this.priority = 'high',
    this.type = '',
    this.hotelId,
    this.isAcknowledged = false,
  });

  /// Crea un [NotificationModel] a partir de un documento de Firestore.
  factory NotificationModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final isAcknowledged = data['isAcknowledged'] as bool? ?? false;
    final rawTitle =
        (data['title'] ?? data['reason'] ?? data['motivo'])?.toString().trim();
    final rawDescription =
        (data['description'] ?? data['message'] ?? data['reason'] ?? data['motivo'])
            ?.toString()
            .trim();
    final rawRoom = data['relatedRoom'] ??
        data['roomNumber'] ??
        data['room'] ??
        data['roomId'];

    return NotificationModel(
      id: docId,
      title: (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : 'Alerta Crítica',
      description: rawDescription ?? '',
      relatedRoom: rawRoom?.toString().trim() ?? '',
      createdAt: _parseDate(data['createdAt']),
      active: !isAcknowledged,
      priority:
          (data['priority'] ?? data['severity'] ?? data['level'])?.toString() ??
              'high',
      type: (data['type'] ?? data['alertType'] ?? data['category'])
              ?.toString() ??
          '',
      hotelId: data['hotelId']?.toString(),
      isAcknowledged: isAcknowledged,
    );
  }

  /// Convierte el modelo a un mapa compatible con Firestore.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'relatedRoom': relatedRoom,
        'createdAt': createdAt.toIso8601String(),
        'active': active,
        'isAcknowledged': isAcknowledged,
        'priority': priority,
        'type': type,
        if (hotelId != null) 'hotelId': hotelId,
      };

  /// Indica si la alerta es de prioridad alta o crítica (o si no especifica
  /// prioridad explícita).
  bool get isHighPriority {
    final normalized = priority.trim().toLowerCase();
    return normalized.isEmpty || _highPriorityValues.contains(normalized);
  }

  /// Etiqueta legible para mostrar el número de cuarto en el banner/panel.
  String get roomLabel {
    final trimmed = relatedRoom.trim();
    if (trimmed.isEmpty) return 'General';
    if (trimmed.toLowerCase().startsWith('hab')) return trimmed;
    return 'Hab. $trimmed';
  }

  /// Motivo consolidado de la alerta para mostrar en el overlay.
  String get reasonText {
    final trimmedDesc = description.trim();
    final trimmedTitle = title.trim();
    if (trimmedDesc.isEmpty) return trimmedTitle;
    if (trimmedTitle.isEmpty || trimmedDesc == trimmedTitle) {
      return trimmedDesc;
    }
    return '$trimmedTitle: $trimmedDesc';
  }

  /// Helper para parsear fechas de Firestore.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Formato legible del tiempo transcurrido.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
