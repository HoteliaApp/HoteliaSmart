import 'package:firebase_auth/firebase_auth.dart';

/// Resultado de sesión autenticada y claims de hotel para la Smart TV.
class AuthSessionResult {
  final bool isAuthenticated;
  final String? uid;
  final String? email;
  final String? hotelId;

  const AuthSessionResult({
    required this.isAuthenticated,
    this.uid,
    this.email,
    this.hotelId,
  });

  const AuthSessionResult.unauthenticated()
      : isAuthenticated = false,
        uid = null,
        email = null,
        hotelId = null;
}

/// Servicio de autenticación de Firebase para HoteliaSmart.
///
/// Soporta:
///   • Reutilización de sesión activa en [FirebaseAuth].
///   • Auto-login silencioso mediante `--dart-define=SMART_TV_EMAIL=...`
///     y `--dart-define=SMART_TV_PASSWORD=...`.
///   • Refresco forzado del JWT (`getIdToken(true)`) al iniciar sesión o
///     arrancar la app para obtener el Custom Claim `hotelId`.
class AuthService {
  final FirebaseAuth? _injectedAuth;

  AuthService({FirebaseAuth? auth}) : _injectedAuth = auth;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  static const String _autoEmail = String.fromEnvironment('SMART_TV_EMAIL');
  static const String _autoPassword =
      String.fromEnvironment('SMART_TV_PASSWORD');
  static const String _defaultHotelId =
      String.fromEnvironment('DEFAULT_HOTEL_ID');

  /// Indica si existen credenciales preconfiguradas para auto-login silencioso.
  bool get hasAutoLoginCredentials =>
      _autoEmail.trim().isNotEmpty && _autoPassword.isNotEmpty;

  /// Verifica la sesión activa (o realiza auto-login si hay credenciales
  /// configuradas) y fuerza el refresco del token JWT (`getIdToken(true)`)
  /// para recuperar el Custom Claim `hotelId`.
  Future<AuthSessionResult> ensureAuthenticatedAndRefreshClaims() async {
    User? user = _auth.currentUser;

    if (user == null && hasAutoLoginCredentials) {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _autoEmail.trim(),
        password: _autoPassword,
      );
      user = credential.user;
    }

    if (user == null) {
      return const AuthSessionResult.unauthenticated();
    }

    return _refreshAndBuildSession(user);
  }

  /// Inicia sesión con correo y contraseña y fuerza el refresco del token
  /// JWT (`getIdToken(true)`) para disponer inmediatamente de `hotelId`.
  Future<AuthSessionResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      return const AuthSessionResult.unauthenticated();
    }

    return _refreshAndBuildSession(user);
  }

  /// Fuerza el refresco del token JWT del usuario actual (`getIdToken(true)`)
  /// y devuelve el valor actualizado del claim `hotelId`.
  Future<String?> refreshIdTokenClaims() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final session = await _refreshAndBuildSession(user);
    return session.hotelId;
  }

  /// Cierra la sesión actual de Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AuthSessionResult> _refreshAndBuildSession(User user) async {
    await user.getIdToken(true);
    final tokenResult = await user.getIdTokenResult(true);
    final hotelId = _extractHotelId(tokenResult.claims);

    return AuthSessionResult(
      isAuthenticated: true,
      uid: user.uid,
      email: user.email,
      hotelId: hotelId,
    );
  }

  String? _extractHotelId(Map<String, dynamic>? claims) {
    final claimHotelId = claims?['hotelId']?.toString().trim();
    if (claimHotelId != null && claimHotelId.isNotEmpty) {
      return claimHotelId;
    }

    final fallback = _defaultHotelId.trim();
    return fallback.isNotEmpty ? fallback : null;
  }
}
