import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/config/router/app_router.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/models/notification_model.dart';
import 'package:hotel_smart_app/models/room_model.dart';
import 'package:hotel_smart_app/models/task_model.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';
import 'package:hotel_smart_app/providers/notifications_provider.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';
import 'package:hotel_smart_app/providers/tasks_provider.dart';
import 'package:hotel_smart_app/widgets/alerts_panel.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';
import 'package:hotel_smart_app/widgets/daily_metrics_view.dart';
import 'package:hotel_smart_app/widgets/floor_map_view.dart';
import 'package:hotel_smart_app/widgets/kanban_column.dart';
import 'package:hotel_smart_app/widgets/notification_banner.dart';

/// Vistas principales disponibles en el Dashboard de la Smart TV.
enum DashboardView {
  floorMap,
  dailyMetrics,
  kanban,
}

/// Pantalla principal de la Smart TV — Monitoreo General y Centro de Mando.
class HomeScreen extends ConsumerStatefulWidget {
  static const Duration defaultRotationInterval = Duration(seconds: 60);

  final Duration rotationInterval;
  final bool initialKioskMode;
  final DashboardView initialView;

  const HomeScreen({
    super.key,
    this.rotationInterval = defaultRotationInterval,
    this.initialKioskMode = true,
    this.initialView = DashboardView.floorMap,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _displayedAlertIds = <String>{};
  final FocusNode _remoteFocusNode = FocusNode(debugLabel: 'SmartTvRemote');

  late DashboardView _currentView;
  late bool _isKioskMode;
  Timer? _kioskTimer;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
    _isKioskMode = widget.initialKioskMode;
    _resetKioskTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificationsProvider).whenData(_handleIncomingAlerts);
    });
  }

  @override
  void dispose() {
    _kioskTimer?.cancel();
    _remoteFocusNode.dispose();
    NotificationBanner.dismissCurrent();
    super.dispose();
  }

  void _resetKioskTimer() {
    _kioskTimer?.cancel();
    if (!_isKioskMode) return;
    _kioskTimer = Timer(widget.rotationInterval, _rotateKioskView);
  }

  void _rotateKioskView() {
    if (!mounted || !_isKioskMode) return;
    setState(() {
      _currentView = _currentView == DashboardView.floorMap
          ? DashboardView.dailyMetrics
          : DashboardView.floorMap;
    });
    _resetKioskTimer();
  }

  void _onUserInteraction() {
    _resetKioskTimer();
  }

  void _handleRemoteKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    _onUserInteraction();

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      const views = DashboardView.values;
      final nextIndex = (views.indexOf(_currentView) + 1) % views.length;
      _selectView(views[nextIndex]);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      const views = DashboardView.values;
      final prevIndex =
          (views.indexOf(_currentView) - 1 + views.length) % views.length;
      _selectView(views[prevIndex]);
    }
  }

  void _selectView(DashboardView view) {
    if (_currentView == view) {
      _resetKioskTimer();
      return;
    }
    setState(() => _currentView = view);
    _resetKioskTimer();
  }

  void _toggleKioskMode() {
    setState(() => _isKioskMode = !_isKioskMode);
    _resetKioskTimer();
  }

  void _handleIncomingAlerts(List<NotificationModel> alerts) {
    final activeIds = alerts.map((a) => a.id).toSet();
    _displayedAlertIds.removeWhere((id) => !activeIds.contains(id));

    final newHighPriorityAlerts = alerts
        .where(
          (alert) =>
              alert.active &&
              !alert.isAcknowledged &&
              alert.isHighPriority &&
              !_displayedAlertIds.contains(alert.id),
        )
        .toList();

    if (newHighPriorityAlerts.isEmpty) return;

    for (final alert in newHighPriorityAlerts) {
      _displayedAlertIds.add(alert.id);
    }

    final latestAlert = newHighPriorityAlerts.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationBanner.show(context, latestAlert);
    });
  }

  Future<void> _refreshTokenClaims() async {
    _onUserInteraction();
    try {
      final updatedHotelId =
          await ref.read(authServiceProvider).refreshIdTokenClaims();
      if (!mounted) return;
      ref.read(hotelIdClaimProvider.notifier).state = updatedHotelId;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedHotelId != null && updatedHotelId.isNotEmpty
                ? 'Token actualizado (Hotel: $updatedHotelId)'
                : 'Token actualizado sin claim hotelId asignado',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refrescando token: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    _kioskTimer?.cancel();
    NotificationBanner.dismissCurrent();
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    ref.read(authSessionProvider.notifier).state = null;
    ref.read(hotelIdClaimProvider.notifier).state = null;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<NotificationModel>>>(
      notificationsProvider,
      (previous, next) {
        next.whenData(_handleIncomingAlerts);
      },
    );

    final roomsAsync = ref.watch(roomsStreamProvider);
    final pendingAsync = ref.watch(pendingTasksStreamProvider);
    final inProgressAsync = ref.watch(inProgressTasksStreamProvider);
    final alertsAsync = ref.watch(notificationsProvider);
    final metrics = ref.watch(dailyKpiMetricsProvider);
    final hotelId = ref.watch(hotelIdClaimProvider);
    final session = ref.watch(authSessionProvider);

    final rooms = roomsAsync.valueOrNull ?? const <RoomModel>[];
    final pendingTasks = pendingAsync.valueOrNull ?? const <TaskModel>[];
    final inProgressTasks = inProgressAsync.valueOrNull ?? const <TaskModel>[];
    final alerts = alertsAsync.valueOrNull ?? const <NotificationModel>[];

    final isLoadingTasks = pendingAsync.isLoading || inProgressAsync.isLoading;
    final isLoadingAlerts = alertsAsync.isLoading;

    return KeyboardListener(
      focusNode: _remoteFocusNode,
      autofocus: true,
      onKeyEvent: _handleRemoteKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onUserInteraction(),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(
                  context: context,
                  hotelId: hotelId,
                  isAuthenticated: session?.isAuthenticated == true,
                ),
                if (!isLoadingAlerts) AlertsPanel(alerts: alerts),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<DashboardView>(_currentView),
                      child: _buildActiveView(
                        rooms: rooms,
                        isLoadingRooms: roomsAsync.isLoading,
                        metrics: metrics,
                        isLoadingTasks: isLoadingTasks,
                        pendingTasks: pendingTasks,
                        inProgressTasks: inProgressTasks,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView({
    required List<RoomModel> rooms,
    required bool isLoadingRooms,
    required DailyKpiMetrics metrics,
    required bool isLoadingTasks,
    required List<TaskModel> pendingTasks,
    required List<TaskModel> inProgressTasks,
  }) {
    final statusColors = AppStatusColors.of(context);
    switch (_currentView) {
      case DashboardView.floorMap:
        return FloorMapView(
          rooms: rooms,
          stats: metrics.roomStats,
          isLoading: isLoadingRooms,
        );
      case DashboardView.dailyMetrics:
        return DailyMetricsView(metrics: metrics);
      case DashboardView.kanban:
        if (isLoadingTasks) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg + 4),
          child: Row(
            children: [
              Expanded(
                child: KanbanColumn(
                  title: 'Tareas Pendientes',
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.primary,
                  tasks: pendingTasks,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: KanbanColumn(
                  title: 'En Progreso',
                  icon: Icons.trending_up_rounded,
                  color: statusColors.info,
                  tasks: inProgressTasks,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildAppBar({
    required BuildContext context,
    required String? hotelId,
    required bool isAuthenticated,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final kioskColor =
        _isKioskMode ? statusColors.success : statusColors.neutral;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          const AppIconBadge(
            icon: Icons.hotel_rounded,
            color: AppColors.primary,
            size: 42,
            iconSize: AppIconSize.md,
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Centro de Mando',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Monitoreo — Limpieza y Ocupación',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          _ViewChip(
            label: 'Pisos',
            icon: Icons.layers_rounded,
            selected: _currentView == DashboardView.floorMap,
            onTap: () => _selectView(DashboardView.floorMap),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          _ViewChip(
            label: 'Métricas',
            icon: Icons.analytics_rounded,
            selected: _currentView == DashboardView.dailyMetrics,
            onTap: () => _selectView(DashboardView.dailyMetrics),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          _ViewChip(
            label: 'Kanban',
            icon: Icons.view_kanban_rounded,
            selected: _currentView == DashboardView.kanban,
            onTap: () => _selectView(DashboardView.kanban),
          ),
          const Spacer(),
          InkWell(
            onTap: _toggleKioskMode,
            borderRadius: AppRadius.mdAll,
            child: AppPill(
              label: _isKioskMode ? 'Quiosco 60s' : 'Quiosco Pausado',
              color: kioskColor,
              icon: _isKioskMode
                  ? Icons.autorenew_rounded
                  : Icons.pause_circle_rounded,
              outlined: true,
              dense: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          if (hotelId != null && hotelId.isNotEmpty) ...[
            AppPill(
              label: 'Hotel: $hotelId',
              color: statusColors.info,
              icon: Icons.apartment_rounded,
              outlined: true,
              dense: true,
            ),
            const SizedBox(width: AppSpacing.sm + 2),
          ],
          if (isAuthenticated) ...[
            Tooltip(
              message: 'Refrescar claims (getIdToken)',
              child: IconButton(
                onPressed: _refreshTokenClaims,
                icon: Icon(
                  Icons.sync_lock_rounded,
                  size: AppIconSize.sm,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Tooltip(
              message: 'Cerrar sesión',
              child: IconButton(
                onPressed: _signOut,
                icon: Icon(
                  Icons.logout_rounded,
                  size: AppIconSize.sm,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 30)),
            builder: (context, _) {
              final now = DateTime.now();
              return Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.8,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.18)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.65)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSize.xs,
              color: selected ? AppColors.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
