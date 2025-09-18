// lib/domain/repositories/user_repository.dart
import '../entities/user.dart';

/// Interfaz del repositorio de usuarios
/// Define los métodos que debe implementar cualquier fuente de datos de usuarios
abstract class UserRepository {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONSULTA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene un usuario por su ID
  Future<User?> getUserById(String userId);
  
  /// Obtiene un usuario por su email
  Future<User?> getUserByEmail(String email);
  
  /// Obtiene todos los usuarios activos
  Future<List<User>> getAllUsers();
  
  /// Obtiene usuarios por rol
  Future<List<User>> getUsersByRole(UserRole role);
  
  /// Obtiene usuarios hijos de un socio titular
  Future<List<User>> getChildrenOfMember(String parentMemberId);
  
  /// Obtiene usuarios con acceso temporal próximo a vencer
  Future<List<User>> getUsersWithExpiringAccess([int daysThreshold = 7]);
  
  /// Obtiene usuarios con membresía próxima a vencer
  Future<List<User>> getUsersWithExpiringMembership([int daysThreshold = 30]);
  
  /// Busca usuarios por nombre (búsqueda parcial)
  Future<List<User>> searchUsersByName(String searchTerm);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MODIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Crea un nuevo usuario
  Future<void> createUser(User user);
  
  /// Actualiza un usuario existente
  Future<void> updateUser(User user);
  
  /// Actualiza solo las preferencias del usuario
  Future<void> updateUserPreferences(String userId, UserPreferences preferences);
  
  /// Actualiza las estadísticas de un usuario
  Future<void> updateUserStats(String userId, UserStats stats);
  
  /// Actualiza el último login del usuario
  Future<void> updateLastLogin(String userId);
  
  /// Activa o desactiva un usuario
  Future<void> toggleUserActive(String userId, bool isActive);
  
  /// Extiende el acceso temporal de una visita
  Future<void> extendTemporaryAccess(String userId, DateTime newExpiry);
  
  /// Actualiza el rol de un usuario
  Future<void> updateUserRole(String userId, UserRole newRole);
  
  /// Elimina un usuario (soft delete - marca como inactivo)
  Future<void> deleteUser(String userId);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Verifica si un email ya está registrado
  Future<bool> isEmailRegistered(String email);
  
  /// Verifica si un número de membresía ya está en uso
  Future<bool> isMembershipNumberInUse(String membershipNumber);
  
  /// Valida si un usuario puede hacer reservas
  Future<bool> canUserMakeReservations(String userId);
  
  /// Obtiene las restricciones de horario para un usuario
  Future<List<String>> getUserAllowedTimeSlots(String userId);
  
  /// Obtiene los días permitidos para un usuario
  Future<List<int>> getUserAllowedWeekdays(String userId);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS Y REPORTES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene el conteo de usuarios por rol
  Future<Map<UserRole, int>> getUserCountByRole();
  
  /// Obtiene usuarios más activos (por cantidad de reservas)
  Future<List<User>> getMostActiveUsers([int limit = 10]);
  
  /// Obtiene el total recaudado por categoría de usuario
  Future<Map<UserRole, double>> getRevenueByUserRole();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE STREAM (TIEMPO REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Stream de cambios en un usuario específico
  Stream<User?> watchUser(String userId);
  
  /// Stream de todos los usuarios activos
  Stream<List<User>> watchAllUsers();
  
  /// Stream de usuarios por rol
  Stream<List<User>> watchUsersByRole(UserRole role);
}