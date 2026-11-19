import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/screens/home_screen.dart';
import 'package:hotel_smart_app/screens/login_screen.dart';
import 'package:hotel_smart_app/screens/splash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constantes de rutas
// ─────────────────────────────────────────────────────────────────────────────

/// Centraliza todas las rutas con nombre de la app.
///
/// La Smart TV cuenta con splash (carga y validación de claims), login de
/// respaldo y home (tablero Kanban con overlay de alertas críticas).
abstract final class AppRoutes {
  /// Pantalla de carga inicial.
  static const String splash = '/';

  /// Pantalla de inicio de sesión cuando no hay sesión ni auto-login.
  static const String login = '/login';

  /// Tablero Kanban principal — centro de mando de tareas y alertas.
  static const String home = '/home';
}

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

/// Instancia de [GoRouter] que gestiona la navegación de la Smart TV.
///
/// Flujo:
///   1. La app arranca en [SplashScreen] (ruta `/`).
///   2. Se valida sesión / auto-login y se refresca el JWT (`getIdToken(true)`)
///      para leer el Custom Claim `hotelId`.
///   3. Si hay sesión válida navega a `/home`; si no, a `/login`.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => _RouterErrorScreen(
    message: state.error?.message ?? 'Ruta no encontrada',
  ),
  routes: [
    // ── Splash ───────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Login ────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Tablero Kanban ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla de error de navegación
// ─────────────────────────────────────────────────────────────────────────────

class _RouterErrorScreen extends StatelessWidget {
  final String message;
  const _RouterErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 72, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              '404',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 56,
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
