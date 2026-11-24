import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/config/router/app_router.dart';
import 'package:hotel_smart_app/config/services/auth_service.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';

/// Pantalla de carga inicial de la Smart TV.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
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

    if (Firebase.apps.isEmpty) {
      context.go(AppRoutes.home);
      return;
    }

    final session = await (_sessionFuture ??
        Future.value(const AuthSessionResult.unauthenticated()));
    if (!mounted) return;

    if (session.isAuthenticated) {
      ref.read(authSessionProvider.notifier).state = session;
      ref.read(hotelIdClaimProvider.notifier).state = session.hotelId;
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    size: AppIconSize.hero,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl + 4),
                Text(
                  'Hotelia Smart TV',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  'Panel de gestión hotelera',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl + 16),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Iniciando…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
