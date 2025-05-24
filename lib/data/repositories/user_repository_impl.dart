// lib/data/repositories/user_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;
  final String _collection = FirebaseConstants.usersCollection;

  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONSULTA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al buscar usuario por email: $e');
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener todos los usuarios: $e');
    }
  }

  @override
  Future<List<User>> getUsersByRole(UserRole role) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: role.value)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol: $e');
    }
  }

  @override
  Future<List<User>> getChildrenOfMember(String parentMemberId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('parentMemberId', isEqualTo: parentMemberId)
          .where('role', isEqualTo: UserRole.hijoSocio.value)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener hijos de socio: $e');
    }
  }

  @override
  Future<List<User>> getUsersWithExpiringAccess([int daysThreshold = 7]) async {
    try {
      final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
      
      final query = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: UserRole.visita.value)
          .where('isActive', isEqualTo: true)
          .where('temporaryAccessExpiry', isLessThanOrEqualTo: Timestamp.fromDate(thresholdDate))
          .orderBy('temporaryAccessExpiry')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios con acceso por vencer: $e');
    }
  }

  @override
  Future<List<User>> getUsersWithExpiringMembership([int daysThreshold = 30]) async {
    try {
      final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));
      
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('membershipExpiry', isLessThanOrEqualTo: Timestamp.fromDate(thresholdDate))
          .orderBy('membershipExpiry')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios con membresía por vencer: $e');
    }
  }

  @override
  Future<List<User>> searchUsersByName(String searchTerm) async {
    try {
      final searchUpper = searchTerm.toUpperCase();
      
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: searchUpper)
          .where('name', isLessThan: searchUpper + '\uf8ff')
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios por nombre: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MODIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> createUser(User user) async {
    try {
      final userModel = user is UserModel ? user : UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isExempt: user.isExempt,
        isActive: user.isActive,
        membershipNumber: user.membershipNumber,
        parentMemberId: user.parentMemberId,
        birthDate: user.birthDate,
        membershipExpiry: user.membershipExpiry,
        sponsorMemberId: user.sponsorMemberId,
        temporaryAccessExpiry: user.temporaryAccessExpiry,
        preferences: user.preferences,
        stats: user.stats,
        metadata: user.metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(user.id)
          .set(userModel.toFirestore());
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      final userModel = user is UserModel ? user : UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isExempt: user.isExempt,
        isActive: user.isActive,
        membershipNumber: user.membershipNumber,
        parentMemberId: user.parentMemberId,
        birthDate: user.birthDate,
        membershipExpiry: user.membershipExpiry,
        sponsorMemberId: user.sponsorMemberId,
        temporaryAccessExpiry: user.temporaryAccessExpiry,
        preferences: user.preferences,
        stats: user.stats,
        metadata: user.metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(user.id)
          .update(userModel.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  @override
  Future<void> updateUserPreferences(String userId, UserPreferences preferences) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'preferences': preferences.toMap(),
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar preferencias: $e');
    }
  }

  @override
  Future<void> updateUserStats(String userId, UserStats stats) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'stats': stats.toMap(),
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar estadísticas: $e');
    }
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'metadata.lastLogin': FieldValue.serverTimestamp(),
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar último login: $e');
    }
  }

  @override
  Future<void> toggleUserActive(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'isActive': isActive,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al cambiar estado activo: $e');
    }
  }

  @override
  Future<void> extendTemporaryAccess(String userId, DateTime newExpiry) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'temporaryAccessExpiry': Timestamp.fromDate(newExpiry),
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al extender acceso temporal: $e');
    }
  }

  @override
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'role': newRole.value,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar rol de usuario: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      // Soft delete - marcar como inactivo
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({
            'isActive': false,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar email: $e');
    }
  }

  @override
  Future<bool> isMembershipNumberInUse(String membershipNumber) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('membershipNumber', isEqualTo: membershipNumber)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar número de membresía: $e');
    }
  }

  @override
  Future<bool> canUserMakeReservations(String userId) async {
    try {
      final user = await getUserById(userId);
      return user?.canMakeReservations ?? false;
    } catch (e) {
      throw Exception('Error al verificar permisos de reserva: $e');
    }
  }

  @override
  Future<List<String>> getUserAllowedTimeSlots(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return [];
      
      return AppConstants.getAllowedTimeSlotsForRole(user.role.value);
    } catch (e) {
      throw Exception('Error al obtener horarios permitidos: $e');
    }
  }

  @override
  Future<List<int>> getUserAllowedWeekdays(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return [];
      
      return AppConstants.getAllowedDaysForRole(user.role.value);
    } catch (e) {
      throw Exception('Error al obtener días permitidos: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS Y REPORTES
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Map<UserRole, int>> getUserCountByRole() async {
    try {
      final users = await getAllUsers();
      final Map<UserRole, int> counts = {};
      
      for (final role in UserRole.values) {
        counts[role] = users.where((user) => user.role == role).length;
      }
      
      return counts;
    } catch (e) {
      throw Exception('Error al obtener conteo por rol: $e');
    }
  }

  @override
  Future<List<User>> getMostActiveUsers([int limit = 10]) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('stats.totalBookings', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios más activos: $e');
    }
  }

  @override
  Future<Map<UserRole, double>> getRevenueByUserRole() async {
    try {
      final users = await getAllUsers();
      final Map<UserRole, double> revenue = {};
      
      for (final role in UserRole.values) {
        final usersOfRole = users.where((user) => user.role == role);
        final totalRevenue = usersOfRole
            .map((user) => user.stats.totalAmountPaid)
            .fold(0.0, (sum, amount) => sum + amount);
        revenue[role] = totalRevenue;
      }
      
      return revenue;
    } catch (e) {
      throw Exception('Error al obtener ingresos por rol: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE STREAM (TIEMPO REAL)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<User?> watchUser(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
  }

  @override
  Stream<List<User>> watchAllUsers() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<User>> watchUsersByRole(UserRole role) {
    return _firestore
        .collection(_collection)
        .where('role', isEqualTo: role.value)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }
}