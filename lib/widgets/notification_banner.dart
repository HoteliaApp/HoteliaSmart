import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';
import '../models/notification_model.dart';

/// Banner overlay temporal para alertas críticas ambientales [H-23].
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

  static void dismissCurrent() {
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final danger = statusColors.danger;
    final showDescription = notification.description.trim().isNotEmpty &&
        notification.description.trim() != notification.title.trim();
    final bg = Color.alphaBlend(
      danger.withValues(alpha: 0.16),
      AppColors.surfaceDark,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: danger.withValues(alpha: 0.85),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: danger.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          ...AppShadows.soft,
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg + 4,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md + 2,
              ),
              child: Row(
                children: [
                  AppIconBadge(
                    icon: Icons.warning_amber_rounded,
                    color: danger,
                    size: 52,
                    iconSize: AppIconSize.lg,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md + 2,
                      vertical: AppSpacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: danger,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CUARTO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.black.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          notification.roomLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const AppPill(
                              label: 'ALERTA CRÍTICA · PRIORIDAD ALTA',
                              color: AppColors.primary,
                              outlined: true,
                              dense: true,
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Text(
                              notification.timeAgo,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Text(
                          notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showDescription) ...[
                          const SizedBox(height: AppSpacing.xxs + 1),
                          Text(
                            notification.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.88),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Cerrar alerta',
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (progressAnimation != null)
              AnimatedBuilder(
                animation: progressAnimation!,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: (1.0 - progressAnimation!.value).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(danger),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

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
                  padding: const EdgeInsets.only(top: AppSpacing.md),
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
