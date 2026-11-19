import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

/// Banner overlay temporal para alertas críticas ambientales [H-23].
///
/// Se despliega en la parte superior de la Smart TV durante 10 segundos
/// mostrando de forma destacada el número de cuarto y el motivo del aviso.
class NotificationBanner extends StatelessWidget {
  final NotificationModel notification;
  final Animation<double>? progressAnimation;
  final VoidCallback? onClose;

  static const Duration displayDuration = Duration(seconds: 10);
  static OverlayEntry? _currentEntry;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.progressAnimation,
    this.onClose,
  });

  /// Cierra inmediatamente el banner overlay activo, si existe.
  static void dismissCurrent() {
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  /// Despliega un banner temporal en la parte superior de la pantalla
  /// durante [duration] (10 segundos por defecto).
  static void show(
    BuildContext context,
    NotificationModel notification, {
    Duration duration = displayDuration,
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    dismissCurrent();

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FloatingNotification(
        notification: notification,
        duration: duration,
        onDismiss: () {
          if (identical(_currentEntry, overlayEntry)) {
            _currentEntry = null;
          }
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    _currentEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final showDescription = notification.description.trim().isNotEmpty &&
        notification.description.trim() != notification.title.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2B0F14),
            Color(0xFF1D0D14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              child: Row(
                children: [
                  // ── Icono de Alerta Crítica ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFCA5A5),
                      size: 30.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),

                  // ── Número de Cuarto destacado ───────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CUARTO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          notification.roomLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18.0),

                  // ── Motivo del aviso ─────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF661A)
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFF661A)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Text(
                                'ALERTA CRÍTICA · PRIORIDAD ALTA',
                                style: TextStyle(
                                  color: Color(0xFFFDBA74),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showDescription) ...[
                          const SizedBox(height: 3.0),
                          Text(
                            notification.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (onClose != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Cerrar alerta',
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Barra de progreso temporal (10s) ───────────────────────────
            if (progressAnimation != null)
              AnimatedBuilder(
                animation: progressAnimation!,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: (1.0 - progressAnimation!.value).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFEF4444),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget interno para manejar la animación y tiempo de vida del banner overlay.
class _FloatingNotification extends StatefulWidget {
  final NotificationModel notification;
  final Duration duration;
  final VoidCallback onDismiss;

  const _FloatingNotification({
    required this.notification,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_FloatingNotification> createState() => _FloatingNotificationState();
}

class _FloatingNotificationState extends State<_FloatingNotification>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _progressController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _progressController.forward();
    _dismissTimer = Timer(widget.duration, _dismissBanner);
  }

  void _dismissBanner() {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _progressController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          widthFactor: 0.9,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: NotificationBanner(
                    notification: widget.notification,
                    progressAnimation: _progressController,
                    onClose: _dismissBanner,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
