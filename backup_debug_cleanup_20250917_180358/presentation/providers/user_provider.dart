// ============================================================================
// lib/presentation/providers/user_provider.dart - REEMPLAZAR COMPLETAMENTE
// ============================================================================

import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
// Comentamos temporalmente para que compile
// import '../../domain/repositories/user_repository.dart';
import '../../core/constants/app_constants.dart';
// Comentamos temporalmente para que compile  
// import '../../core/theme/app_theme.dart';

/// Provider que maneja el estado del usuario y autenticación
class UserProvider extends ChangeNotifier {
  // Hacemos el repository opcional para que compile con Firebase
  // final UserRepository? _userRepository;

UserProvider(); // ← Constructor simple sin parámetros

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADO DE USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  // Usuario actual autenticado
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Estado de autenticación
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error actual
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Lista de usuarios (para admins)
  List<User> _users = [];
  List<User> get users => _users;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE AUTENTICACIÓN (MOCK PARA FIREBASE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicia sesión con un usuario (mock para Firebase)
  Future<void> signIn(String email) async {
    try {
      _setLoading(true);
      
      // Mock user para testing con Firebase
      if (email == 'felipe@garciab.cl' || email.isNotEmpty) {
        _currentUser = User(
          id: 'user_001',
          name: 'Felipe García',
          email: email,
          role: UserRole.socio,
          isActive: true,
          // createdAt: DateTime.now(),
        );
        _isAuthenticated = true;
      } else {
        throw Exception('Usuario no encontrado');
      }
      
      _clearError();
    } catch (e) {
      _setError('Error al iniciar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    _currentUser = null;
    _isAuthenticated = false;
    _users.clear();
    _clearError();
    notifyListeners();
  }

  /// Verifica si hay una sesión activa (mock)
  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);
      
      // Mock: Usuario de prueba para desarrollo con Firebase
      _currentUser = User(
        id: 'user_001',
        name: 'Felipe García',
        email: 'felipe@garciab.cl',
        role: UserRole.socio,
        isActive: true,
        // createdAt: DateTime.now(),
      );
      _isAuthenticated = true;
      
    } catch (e) {
      _setError('Error al verificar autenticación: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE INFORMACIÓN DEL USUARIO (MOCK)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene información detallada del usuario actual
  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;
    // Mock: mantener usuario actual
    notifyListeners();
  }

  /// Actualiza las preferencias del usuario (mock)
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      
      // Mock: Simular actualización
      // _currentUser = _currentUser!.copyWith(preferences: preferences);
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Error al actualizar preferencias: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza el perfil del usuario (mock)
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    DateTime? birthDate,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      
      // Mock: Simular actualización de perfil
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        birthDate: birthDate ?? _currentUser!.birthDate,
      );
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN Y REGLAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si el usuario puede hacer reservas
  bool get canMakeReservations {
    return _currentUser?.canMakeReservations ?? true; // Mock: permitir por defecto
  }

  /// Verifica si el usuario debe pagar por las reservas
  bool get mustPayForReservations {
    return _currentUser?.mustPayForReservations ?? false;
  }

  /// Obtiene los horarios permitidos para el usuario actual (mock)
  List<String> get allowedTimeSlots {
    // Mock: todos los horarios permitidos
    return ['09:00', '10:30', '12:00', '13:30', '15:00', '16:30', '18:00', '19:30'];
  }

  /// Obtiene los días permitidos para el usuario actual (mock)
  List<int> get allowedWeekdays {
    // Mock: todos los días permitidos
    return [1, 2, 3, 4, 5, 6, 7];
  }

  /// Verifica si un horario está permitido para el usuario
  bool isTimeSlotAllowed(String timeSlot) {
    return allowedTimeSlots.contains(timeSlot);
  }

  /// Verifica si un día está permitido para el usuario
  bool isWeekdayAllowed(int weekday) {
    return allowedWeekdays.contains(weekday);
  }

  /// Obtiene la tarifa que debe pagar el usuario (mock)
  double get userRate {
    return 0.0; // Mock: gratis por ahora
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ADMINISTRACIÓN (mock)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si el usuario actual es administrador
  bool get isAdmin {
    return _currentUser?.role.isAdmin ?? true; // Mock: admin por defecto
  }

  /// Carga todos los usuarios (mock)
  Future<void> loadAllUsers() async {
    if (!isAdmin) return;

    try {
      _setLoading(true);
      // Mock: lista vacía por ahora
      _users = [];
      _clearError();
    } catch (e) {
      _setError('Error al cargar usuarios: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene usuarios por rol (mock)
  Future<List<User>> getUsersByRole(UserRole role) async {
    return []; // Mock: lista vacía
  }

  /// Busca usuarios por nombre (mock)
  Future<List<User>> searchUsers(String searchTerm) async {
    return []; // Mock: lista vacía
  }

  /// Activa/desactiva un usuario (mock)
  Future<void> toggleUserActive(String userId, bool isActive) async {
    // Mock: no hacer nada por ahora
  }

  /// Actualiza el rol de un usuario (mock)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    // Mock: no hacer nada por ahora
  }

  /// Extiende el acceso temporal de una visita (mock)
  Future<void> extendTemporaryAccess(String userId, DateTime newExpiry) async {
    // Mock: no hacer nada por ahora
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS (mock)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene estadísticas de usuarios por rol (mock)
  Future<Map<UserRole, int>> getUserStatsByRole() async {
    return {}; // Mock: vacío
  }

  /// Obtiene usuarios más activos (mock)
  Future<List<User>> getMostActiveUsers([int limit = 10]) async {
    return []; // Mock: lista vacía
  }

  /// Obtiene ingresos por rol de usuario (mock)
  Future<Map<UserRole, double>> getRevenueByUserRole() async {
    return {}; // Mock: vacío
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el nombre de visualización del usuario
  String get displayName {
    return _currentUser?.name ?? 'Usuario';
  }

  /// Obtiene el email del usuario
  String get userEmail {
    return _currentUser?.email ?? '';
  }

  /// Obtiene el rol de visualización del usuario
  String get displayRole {
    return _currentUser?.role.displayName ?? 'Socio';
  }

  /// Obtiene el color asociado al rol del usuario (mock)
  Color get roleColor {
    return Colors.blue; // Mock: color fijo
  }

  /// Obtiene el mensaje de bienvenida personalizado (mock)
  String get welcomeMessage {
    return 'Bienvenido a CGP Reservas';
  }

  /// Verifica si el usuario tiene acceso válido
  bool get hasValidAccess {
    return _currentUser?.canMakeReservations ?? true;
  }

  /// Obtiene warnings del usuario (mock)
  List<String> get userWarnings {
    return []; // Mock: sin warnings
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS DE ESTADO
  // ═══════════════════════════════════════════════════════════════════════════

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE LIMPIEZA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOCK CLASSES - Para que compile mientras implementamos Firebase
// ═══════════════════════════════════════════════════════════════════════════════

class UserPreferences {
  final bool notifications;
  final String theme;
  
  UserPreferences({
    this.notifications = true,
    this.theme = 'light',
  });
}