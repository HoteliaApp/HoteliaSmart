import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_smart_app/config/services/auth_service.dart';

/// Provider del servicio de autenticación de Firebase para la Smart TV.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Claim `hotelId` extraído del token JWT tras `getIdToken(true)`.
final hotelIdClaimProvider = StateProvider<String?>((ref) => null);

/// Estado de la última sesión autenticada y sus claims.
final authSessionProvider = StateProvider<AuthSessionResult?>((ref) => null);
