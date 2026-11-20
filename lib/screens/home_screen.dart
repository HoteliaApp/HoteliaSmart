import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/config/router/app_router.dart';
import 'package:hotel_smart_app/models/notification_model.dart';
import 'package:hotel_smart_app/models/room_model.dart';
import 'package:hotel_smart_app/models/task_model.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';
import 'package:hotel_smart_app/providers/notifications_provider.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';
import 'package:hotel_smart_app/providers/tasks_provider.dart';
import 'package:hotel_smart_app/widgets/alerts_panel.dart';
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
///
/// En modo quiosco/ambiental ([H-33]), alterna automáticamente cada 60 segundos
/// sin interacción de control remoto entre:
///   1. Mapa de Pisos ([FloorMapView])
///   2. Panel de Estadísticas del Día ([DailyMetricsView])
///
/// También mantiene accesible el Tablero Kanban de tareas del personal, el
/// panel colapsable de alertas y el overlay superior de 10 segundos para
/// alertas críticas ([H-23]).
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

  // ── Modo Quiosco / Rotación Automática [H-33] ─────────────────────────────

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

  // ── Overlay de Alertas Críticas [H-23] ────────────────────────────────────

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

  // ── Sesión y Custom Claims ────────────────────────────────────────────────

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
    // Escuchar nuevas alertas críticas para disparar el overlay de 10s [H-23].
    ref.listen<AsyncValue<List<NotificationModel>>>(
      notificationsProvider,
      (previous, next) {
        next.whenData(_handleIncomingAlerts);
      },
    );

    // ── Streams de Firestore via Riverpod ─────────────────────────────────────
    final roomsAsync = ref.watch(roomsStreamProvider);
    final pendingAsync = ref.watch(pendingTasksStreamProvider);
    final inProgressAsync = ref.watch(inProgressTasksStreamProvider);
    final alertsAsync = ref.watch(notificationsProvider);
    final metrics = ref.watch(dailyKpiMetricsProvider);
    final hotelId = ref.watch(hotelIdClaimProvider);
    final session = ref.watch(authSessionProvider);

    // ── Extraer datos con manejo de estado ───────────────────────────────────
    final rooms = roomsAsync.valueOrNull ?? const <RoomModel>[];
    final pendingTasks = pendingAsync.valueOrNull ?? const <TaskModel>[];
    final inProgressTasks = inProgressAsync.valueOrNull ?? const <TaskModel>[];
    final alerts = alertsAsync.valueOrNull ?? const <NotificationModel>[];

    final isLoadingTasks = pendingAsync.isLoading || inProgressAsync.isLoading;
    final isLoadingAlerts = alertsAsync.isLoading;

    // ── Errores de Firestore en debug ─────────────────────────────────────────
    assert(() {
      if (roomsAsync.hasError) {
        debugPrint('[HomeScreen] Error en habitaciones: ${roomsAsync.error}');
      }
      if (pendingAsync.hasError) {
        debugPrint(
            '[HomeScreen] Error en tareas pendientes: ${pendingAsync.error}');
      }
      if (inProgressAsync.hasError) {
        debugPrint(
            '[HomeScreen] Error en tareas en progreso: ${inProgressAsync.error}');
      }
      if (alertsAsync.hasError) {
        debugPrint('[HomeScreen] Error en alertas: ${alertsAsync.error}');
      }
      return true;
    }());

    return KeyboardListener(
      focusNode: _remoteFocusNode,
      autofocus: true,
      onKeyEvent: _handleRemoteKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onUserInteraction(),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F1117),
          body: SafeArea(
            child: Column(
              children: [
                // ── AppBar personalizada con selector de vista y modo quiosco ─
                _buildAppBar(
                  hotelId: hotelId,
                  isAuthenticated: session?.isAuthenticated == true,
                ),

                // ── Panel de Alertas (colapsable) ────────────────────────────
                if (!isLoadingAlerts) AlertsPanel(alerts: alerts),

                // ── Contenido principal con transición suave [H-33] ──────────
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
            child: CircularProgressIndicator(color: Color(0xFFFF661A)),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: KanbanColumn(
                  title: 'Tareas Pendientes',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFFF661A),
                  tasks: pendingTasks,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KanbanColumn(
                  title: 'En Progreso',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF3B82F6),
                  tasks: inProgressTasks,
                ),
              ),
            ],
          ),
        );
    }
  }

  /// AppBar personalizada para el centro de mando y rotación quiosco.
  Widget _buildAppBar({
    required String? hotelId,
    required bool isAuthenticated,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF661A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.hotel_rounded,
              size: 24,
              color: Color(0xFFFF661A),
            ),
          ),
          const SizedBox(width: 14),
          // Título
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Centro de Mando',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  'Monitoreo — Limpieza y Ocupación',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Selector de vistas
          _ViewChip(
            label: 'Pisos',
            icon: Icons.layers_rounded,
            selected: _currentView == DashboardView.floorMap,
            onTap: () => _selectView(DashboardView.floorMap),
          ),
          const SizedBox(width: 6),
          _ViewChip(
            label: 'Métricas',
            icon: Icons.analytics_rounded,
            selected: _currentView == DashboardView.dailyMetrics,
            onTap: () => _selectView(DashboardView.dailyMetrics),
          ),
          const SizedBox(width: 6),
          _ViewChip(
            label: 'Kanban',
            icon: Icons.view_kanban_rounded,
            selected: _currentView == DashboardView.kanban,
            onTap: () => _selectView(DashboardView.kanban),
          ),

          const Spacer(),

          // Indicador / Toggle Modo Quiosco (60s)
          InkWell(
            onTap: _toggleKioskMode,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (_isKioskMode
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6B7280))
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_isKioskMode
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280))
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isKioskMode
                        ? Icons.autorenew_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 14,
                    color: _isKioskMode
                        ? const Color(0xFF34D399)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isKioskMode ? 'Quiosco 60s' : 'Quiosco Pausado',
                    style: TextStyle(
                      color: _isKioskMode
                          ? const Color(0xFF34D399)
                          : const Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          if (hotelId != null && hotelId.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.apartment_rounded,
                    size: 14,
                    color: Color(0xFF93C5FD),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hotel: $hotelId',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],

          if (isAuthenticated) ...[
            Tooltip(
              message: 'Refrescar claims (getIdToken)',
              child: IconButton(
                onPressed: _refreshTokenClaims,
                icon: Icon(
                  Icons.sync_lock_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
            Tooltip(
              message: 'Cerrar sesión',
              child: IconButton(
                onPressed: _signOut,
                icon: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Reloj
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 30)),
            builder: (context, _) {
              final now = DateTime.now();
              return Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
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
    final activeColor = const Color(0xFFFF661A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? activeColor : Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
