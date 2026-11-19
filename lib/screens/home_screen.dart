import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/config/router/app_router.dart';
import 'package:hotel_smart_app/models/notification_model.dart';
import 'package:hotel_smart_app/models/task_model.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';
import 'package:hotel_smart_app/providers/notifications_provider.dart';
import 'package:hotel_smart_app/providers/tasks_provider.dart';
import 'package:hotel_smart_app/widgets/alerts_panel.dart';
import 'package:hotel_smart_app/widgets/kanban_column.dart';
import 'package:hotel_smart_app/widgets/notification_banner.dart';

/// Pantalla principal de la Smart TV — Tablero de Control Kanban.
///
/// Centro de mando visual (Back of House) para que gerentes o coordinadores
/// monitoreen en tiempo real el estado de las tareas del personal.
///
/// Además escucha el stream `/alerts` (`isAcknowledged == false`) y, cuando
/// llega una nueva alerta con prioridad alta/crítica, despliega un banner
/// overlay superior durante 10 segundos ([H-23]).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _displayedAlertIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificationsProvider).whenData(_handleIncomingAlerts);
    });
  }

  @override
  void dispose() {
    NotificationBanner.dismissCurrent();
    super.dispose();
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
    final pendingAsync = ref.watch(pendingTasksStreamProvider);
    final inProgressAsync = ref.watch(inProgressTasksStreamProvider);
    final alertsAsync = ref.watch(notificationsProvider);
    final hotelId = ref.watch(hotelIdClaimProvider);
    final session = ref.watch(authSessionProvider);

    // ── Extraer datos con manejo de estado ───────────────────────────────────
    final pendingTasks = pendingAsync.valueOrNull ?? <TaskModel>[];
    final inProgressTasks = inProgressAsync.valueOrNull ?? <TaskModel>[];
    final alerts = alertsAsync.valueOrNull ?? <NotificationModel>[];

    final isLoadingTasks = pendingAsync.isLoading || inProgressAsync.isLoading;
    final isLoadingAlerts = alertsAsync.isLoading;

    // ── Errores de Firestore en debug ─────────────────────────────────────────
    assert(() {
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar personalizada ──────────────────────────────────────
            _buildAppBar(
              hotelId: hotelId,
              isAuthenticated: session?.isAuthenticated == true,
            ),

            // ── Panel de Alertas (colapsable) ────────────────────────────
            if (!isLoadingAlerts) AlertsPanel(alerts: alerts),

            // ── Tablero Kanban (2 columnas) ──────────────────────────────
            Expanded(
              child: isLoadingTasks
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF661A),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // ── Columna 1: Tareas Pendientes ───────────────
                          Expanded(
                            child: KanbanColumn(
                              title: 'Tareas Pendientes',
                              icon: Icons.pending_actions_rounded,
                              color: const Color(0xFFFF661A), // Naranja
                              tasks: pendingTasks,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // ── Columna 2: En Progreso ─────────────────────
                          Expanded(
                            child: KanbanColumn(
                              title: 'En Progreso',
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF3B82F6), // Azul
                              tasks: inProgressTasks,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// AppBar personalizada para el tablero Kanban.
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro de Mando',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Tablero Kanban — Tareas del Personal',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const Spacer(),

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
