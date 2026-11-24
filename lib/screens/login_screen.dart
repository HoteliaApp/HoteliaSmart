import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_smart_app/config/router/app_router.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/providers/auth_provider.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';

/// Pantalla de inicio de sesión para la Smart TV.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await ref
          .read(authServiceProvider)
          .signInWithEmailPassword(
            _emailController.text,
            _passwordController.text,
          );

      if (!mounted) return;

      if (!session.isAuthenticated) {
        setState(() {
          _errorMessage = 'No se pudo completar la autenticación.';
          _isLoading = false;
        });
        return;
      }

      ref.read(authSessionProvider.notifier).state = session;
      ref.read(hotelIdClaimProvider.notifier).state = session.hotelId;
      context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapAuthError(e.code);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al iniciar sesión: $e';
        _isLoading = false;
      });
    }
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'invalid-email' => 'El correo electrónico no tiene un formato válido.',
      'user-disabled' => 'Esta cuenta de usuario ha sido deshabilitada.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Correo o contraseña incorrectos.',
      'too-many-requests' =>
        'Demasiados intentos fallidos. Intenta de nuevo más tarde.',
      'network-request-failed' =>
        'Sin conexión a internet. Verifica la red de la Smart TV.',
      _ => 'No se pudo iniciar sesión ($code).',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl + 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: AppIconBadge(
                          icon: Icons.hotel_rounded,
                          color: AppColors.primary,
                          size: 76,
                          iconSize: 38,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Hotelia Smart TV',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Acceso de Supervisión General',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _emailController,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo institucional',
                          hintText: 'gerente@hotel.com',
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Ingresa un correo electrónico';
                          }
                          if (!trimmed.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) =>
                            _passwordFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppInfoBanner(
                          icon: Icons.error_outline_rounded,
                          color: statusColors.danger,
                          message: _errorMessage!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            _isLoading
                                ? 'Validando credenciales…'
                                : 'Iniciar Sesión',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go(AppRoutes.home),
                        child: Text(
                          'Continuar en modo supervisión local',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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
