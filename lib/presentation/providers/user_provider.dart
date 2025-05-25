// lib/presentation/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Provider que maneja el estado del usuario y autenticación
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  UserProvider({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

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
  // MÉTODOS DE AUTENTICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicia sesión con un usuario (simulado por ahora)
  Future<void> signIn(String email) async {
    try {
      _setLoading(true);
      
      final user = await _userRepository.getUserByEmail(email);
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }

      if (!user.isActive) {
        throw Exception('Usuario inactivo');
      }

      _currentUser = user;
      _isAuthenticated = true;
      
      // Actualizar último login
      await _userRepository.updateLastLogin(user.id);
      
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

  /// Verifica si hay una sesión activa (simulado)
  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);
      
      // En una implementación real, verificaríamos Firebase Auth
      // Por ahora simulamos con SharedPreferences o similar
      
      // Simulación: usuario de prueba
      if (_currentUser == null) {
        // Intentar cargar usuario de prueba (Felipe)
        final testUser = await _userRepository.getUserByEmail('felipe@garciab.cl');
        if (testUser != null) {
          _currentUser = testUser;
          _isAuthenticated = true;
        }
      }
      
    } catch (e) {
      _setError('Error al verificar autenticación: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE INFORMACIÓN DEL USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene información detallada del usuario actual
  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = await _userRepository.getUserById(_currentUser!.id);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al actualizar usuario: $e');
    }
  }

  /// Actualiza las preferencias del usuario
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      
      await _userRepository.updateUserPreferences(_currentUser!.id, preferences);
      
      // Actualizar usuario local
      _currentUser = _currentUser!.copyWith(preferences: preferences);
      
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Error al actualizar preferencias: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza el perfil del usuario
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    DateTime? birthDate,
  }) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        birthDate: birthDate ?? _currentUser!.birthDate,
      );
      
      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;
      
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
    return _currentUser?.canMakeReservations ?? false;
  }

  /// Verifica si el usuario debe pagar por las reservas
  bool get mustPayForReservations {
    return _currentUser?.mustPayForReservations ?? false;
  }

  /// Obtiene los horarios permitidos para el usuario actual
  List<String> get allowedTimeSlots {
    if (_currentUser == null) return [];
    return AppConstants.getAllowedTimeSlotsForRole(_currentUser!.role.value);
  }

  /// Obtiene los días permitidos para el usuario actual
  List<int> get allowedWeekdays {
    if (_currentUser == null) return [];
    return AppConstants.getAllowedDaysForRole(_currentUser!.role.value);
  }

  /// Verifica si un horario está permitido para el usuario
  bool isTimeSlotAllowed(String timeSlot) {
    return allowedTimeSlots.contains(timeSlot);
  }

  /// Verifica si un día está permitido para el usuario
  bool isWeekdayAllowed(int weekday) {
    return allowedWeekdays.contains(weekday);
  }

  /// Obtiene la tarifa que debe pagar el usuario
  double get userRate {
    if (_currentUser == null) return 0.0;
    return AppConstants.getRateForRole(_currentUser!.role.value);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ADMINISTRACIÓN (solo para admins)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si el usuario actual es administrador
  bool get isAdmin {
    return _currentUser?.role.isAdmin ?? false;
  }

  /// Carga todos los usuarios (solo para admins)
  Future<void> loadAllUsers() async {
    if (!isAdmin) return;

    try {
      _setLoading(true);
      _users = await _userRepository.getAllUsers();
      _clearError();
    } catch (e) {
      _setError('Error al cargar usuarios: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene usuarios por rol
  Future<List<User>> getUsersByRole(UserRole role) async {
    if (!isAdmin) return [];

    try {
      return await _userRepository.getUsersByRole(role);
    } catch (e) {
      _setError('Error al obtener usuarios por rol: $e');
      return [];
    }
  }

  /// Busca usuarios por nombre
  Future<List<User>> searchUsers(String searchTerm) async {
    if (!isAdmin) return [];

    try {
      return await _userRepository.searchUsersByName(searchTerm);
    } catch (e) {
      _setError('Error al buscar usuarios: $e');
      return [];
    }
  }

  /// Activa/desactiva un usuario
  Future<void> toggleUserActive(String userId, bool isActive) async {
    if (!isAdmin) return;

    try {
      await _userRepository.toggleUserActive(userId, isActive);
      await loadAllUsers(); // Recargar lista
    } catch (e) {
      _setError('Error al cambiar estado de usuario: $e');
    }
  }

  /// Actualiza el rol de un usuario
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    if (!isAdmin) return;

    try {
      await _userRepository.updateUserRole(userId, newRole);
      await loadAllUsers(); // Recargar lista
    } catch (e) {
      _setError('Error al actualizar rol: $e');
    }
  }

  /// Extiende el acceso temporal de una visita
  Future<void> extendTemporaryAccess(String userId, DateTime newExpiry) async {
    if (!isAdmin) return;

    try {
      await _userRepository.extendTemporaryAccess(userId, newExpiry);
      await loadAllUsers(); // Recargar lista
    } catch (e) {
      _setError('Error al extender acceso: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene estadísticas de usuarios por rol
  Future<Map<UserRole, int>> getUserStatsByRole() async {
    if (!isAdmin) return {};

    try {
      return await _userRepository.getUserCountByRole();
    } catch (e) {
      _setError('Error al obtener estadísticas: $e');
      return {};
    }
  }

  /// Obtiene usuarios más activos
  Future<List<User>> getMostActiveUsers([int limit = 10]) async {
    if (!isAdmin) return [];

    try {
      return await _userRepository.getMostActiveUsers(limit);
    } catch (e) {
      _setError('Error al obtener usuarios activos: $e');
      return [];
    }
  }

  /// Obtiene ingresos por rol de usuario
  Future<Map<UserRole, double>> getRevenueByUserRole() async {
    if (!isAdmin) return {};

    try {
      return await _userRepository.getRevenueByUserRole();
    } catch (e) {
      _setError('Error al obtener ingresos por rol: $e');
      return {};
    }
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
    return _currentUser?.role.displayName ?? '';
  }

  /// Obtiene el color asociado al rol del usuario
  Color get roleColor {
    if (_currentUser == null) return AppColors.primaryBlue;
    return AppColorsExtension.getRoleColor(_currentUser!.role.value);
  }

  /// Obtiene el mensaje de bienvenida personalizado
  String get welcomeMessage {
    if (_currentUser == null) return AppConstants.welcomeMessage;
    
    final roleMessage = AppConstants.categoryWelcomeMessages[_currentUser!.role.value];
    return roleMessage ?? AppConstants.welcomeMessage;
  }

  /// Verifica si el usuario tiene acceso válido
  bool get hasValidAccess {
    return _currentUser?.canMakeReservations ?? false;
  }

  /// Obtiene warnings del usuario (acceso por vencer, etc.)
  List<String> get userWarnings {
    if (_currentUser == null) return [];
    
    final warnings = <String>[];
    
    // Verificar edad límite para hijos de socios
    if (_currentUser!.role == UserRole.hijoSocio && _currentUser!.age != null) {
      if (_currentUser!.age! > 23) {
        warnings.add('Cerca del límite de edad (25 años)');
      }
    }
    
    // Verificar acceso temporal
    // Verificar acceso temporal
    if (_currentUser!.role == UserRole.visita && 
        _currentUser!.temporaryAccessExpiry.isNotEmpty) {
      // Si temporaryAccessExpiry es String con fecha, convertir:
      final expiryDate = DateTime.tryParse(_currentUser!.temporaryAccessExpiry);
      if (expiryDate != null) {
        final daysLeft = expiryDate.difference(DateTime.now()).inDays;
        if (daysLeft < 7) {
          warnings.add('Acceso temporal vence en $daysLeft días');
        }
      }
    }
    
    // Verificar membresía
    if (_currentUser!.membershipExpiry != null) {
      final daysLeft = _currentUser!.membershipExpiry!
          .difference(DateTime.now()).inDays;
      if (daysLeft < 30) {
        warnings.add('Membresía vence en $daysLeft días');
      }
    }
    
    return warnings;
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
    // Limpiar recursos si es necesario
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSIONES PARA IMPORTAR COLORES
// ═══════════════════════════════════════════════════════════════════════════════

