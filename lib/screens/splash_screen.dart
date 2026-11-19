import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/config/router/app_router.dart';
import 'package:hotel_smart_app/config/services/auth_service.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';

/// Pantalla de carga inicial de la Smart TV.
///
/// Muestra el logo animado mientras se completa la inicialización de Flutter
/// y la verificación de sesión/claims en Firebase Auth (`getIdToken(true)`).
/// Navega automáticamente a [HomeScreen] o [LoginScreen] tras la animación.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── Animación del logo ────────────────────────────────────────────────────
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  Timer? _splashTimer;
  Future<AuthSessionResult>? _sessionFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _startInitialization();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Lógica de inicialización ──────────────────────────────────────────────

  void _startInitialization() {
    if (Firebase.apps.isNotEmpty) {
      _sessionFuture = _resolveSession();
    }

    _splashTimer = Timer(
      const Duration(milliseconds: 1800),
      _navigateAfterSplash,
    );
  }

  Future<AuthSessionResult> _resolveSession() async {
    try {
      return await ref
          .read(authServiceProvider)
          .ensureAuthenticatedAndRefreshClaims();
    } catch (e) {
      debugPrint('[SplashScreen] Error verificando sesión/claims: $e');
      return const AuthSessionResult.unauthenticated();
    }
  }

  Future<void> _navigateAfterSplash() async {
    if (!mounted) return;

    // Si Firebase aún no fue inicializado (ej. entorno de tests), ir a Home.
    if (Firebase.apps.isEmpty) {
      context.go(AppRoutes.home);
      return;
    }

    final session =
        await (_sessionFuture ?? Future.value(const AuthSessionResult.unauthenticated()));
    if (!mounted) return;

    if (session.isAuthenticated) {
      ref.read(authSessionProvider.notifier).state = session;
      ref.read(hotelIdClaimProvider.notifier).state = session.hotelId;
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ────────────────────────────────────────────────────
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withAlpha(100),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Nombre ──────────────────────────────────────────────────
                Text(
                  'Hotel Smart TV',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Panel de gestión hotelera',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF9EA3B2),
                        fontSize: 15,
                      ),
                ),

                const SizedBox(height: 48),

                // ── Loader ───────────────────────────────────────────────────
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Iniciando…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
