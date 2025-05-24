// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.role,
    required super.isExempt,
    required super.isActive,
    super.membershipNumber,
    super.parentMemberId,
    super.birthDate,
    super.membershipExpiry,
    super.sponsorMemberId,
    super.temporaryAccessExpiry,
    required super.preferences,
    required super.stats,
    required super.metadata,
  });

  /// Crea UserModel desde documento de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: UserRole.fromString(data['role'] ?? 'socio_titular'),
      isExempt: data['isExempt'] ?? false,
      isActive: data['isActive'] ?? true,
      membershipNumber: data['membershipNumber'],
      parentMemberId: data['parentMemberId'],
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      membershipExpiry: data['membershipExpiry'] != null
          ? (data['membershipExpiry'] as Timestamp).toDate()
          : null,
      sponsorMemberId: data['sponsorMemberId'],
      temporaryAccessExpiry: data['temporaryAccessExpiry'] != null
          ? (data['temporaryAccessExpiry'] as Timestamp).toDate()
          : null,
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      metadata: UserMetadata.fromMap(data['metadata'] ?? {}),
    );
  }

  /// Crea UserModel desde Map (para testing o datos locales)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: UserRole.fromString(map['role'] ?? 'socio_titular'),
      isExempt: map['isExempt'] ?? false,
      isActive: map['isActive'] ?? true,
      membershipNumber: map['membershipNumber'],
      parentMemberId: map['parentMemberId'],
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : null,
      membershipExpiry: map['membershipExpiry'] != null
          ? DateTime.parse(map['membershipExpiry'])
          : null,
      sponsorMemberId: map['sponsorMemberId'],
      temporaryAccessExpiry: map['temporaryAccessExpiry'] != null
          ? DateTime.parse(map['temporaryAccessExpiry'])
          : null,
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      stats: UserStats.fromMap(map['stats'] ?? {}),
      metadata: UserMetadata.fromMap(map['metadata'] ?? {}),
    );
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'isExempt': isExempt,
      'isActive': isActive,
      'membershipNumber': membershipNumber,
      'parentMemberId': parentMemberId,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'membershipExpiry': membershipExpiry != null 
          ? Timestamp.fromDate(membershipExpiry!) 
          : null,
      'sponsorMemberId': sponsorMemberId,
      'temporaryAccessExpiry': temporaryAccessExpiry != null
          ? Timestamp.fromDate(temporaryAccessExpiry!)
          : null,
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
      'metadata': metadata.toMap(),
    };
  }

  /// Convierte a Map simple (para JSON o testing)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'isExempt': isExempt,
      'isActive': isActive,
      'membershipNumber': membershipNumber,
      'parentMemberId': parentMemberId,
      'birthDate': birthDate?.toIso8601String(),
      'membershipExpiry': membershipExpiry?.toIso8601String(),
      'sponsorMemberId': sponsorMemberId,
      'temporaryAccessExpiry': temporaryAccessExpiry?.toIso8601String(),
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
      'metadata': metadata.toMap(),
    };
  }

  /// Crea una copia con algunos campos modificados
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isExempt,
    bool? isActive,
    String? membershipNumber,
    String? parentMemberId,
    DateTime? birthDate,
    DateTime? membershipExpiry,
    String? sponsorMemberId,
    DateTime? temporaryAccessExpiry,
    UserPreferences? preferences,
    UserStats? stats,
    UserMetadata? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isExempt: isExempt ?? this.isExempt,
      isActive: isActive ?? this.isActive,
      membershipNumber: membershipNumber ?? this.membershipNumber,
      parentMemberId: parentMemberId ?? this.parentMemberId,
      birthDate: birthDate ?? this.birthDate,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      sponsorMemberId: sponsorMemberId ?? this.sponsorMemberId,
      temporaryAccessExpiry: temporaryAccessExpiry ?? this.temporaryAccessExpiry,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS UTILITARIOS PARA FIREBASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea un usuario básico (para registro inicial)
  factory UserModel.createBasic({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    String? phone,
    String? membershipNumber,
    DateTime? birthDate,
  }) {
    final now = DateTime.now();
    
    return UserModel(
      id: id,
      name: name.toUpperCase(),
      email: email.toLowerCase(),
      phone: phone,
      role: role,
      isExempt: false,
      isActive: true,
      membershipNumber: membershipNumber,
      parentMemberId: null,
      birthDate: birthDate,
      membershipExpiry: null,
      sponsorMemberId: null,
      temporaryAccessExpiry: null,
      preferences: const UserPreferences(
        notificationsEnabled: true,
        reminderHoursBeforeBooking: 24,
        defaultCourtView: 'PITE',
      ),
      stats: const UserStats(
        totalBookings: 0,
        cancelledBookings: 0,
        noShowBookings: 0,
        totalAmountPaid: 0.0,
        lastBookingDate: null,
      ),
      metadata: UserMetadata(
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
        lastLogin: now.millisecondsSinceEpoch,
      ),
    );
  }

  /// Actualiza el último login
  UserModel updateLastLogin() {
    return copyWith(
      metadata: metadata.copyWith(
        lastLogin: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Actualiza las estadísticas de reserva
  UserModel updateBookingStats({
    int? totalBookings,
    int? cancelledBookings,
    int? noShowBookings,
    double? amountPaid,
    String? lastBookingDate,
  }) {
    return copyWith(
      stats: stats.copyWith(
        totalBookings: totalBookings ?? stats.totalBookings,
        cancelledBookings: cancelledBookings ?? stats.cancelledBookings,
        noShowBookings: noShowBookings ?? stats.noShowBookings,
        totalAmountPaid: amountPaid != null 
            ? stats.totalAmountPaid + amountPaid 
            : stats.totalAmountPaid,
        lastBookingDate: lastBookingDate ?? stats.lastBookingDate,
      ),
      metadata: metadata.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Actualiza las preferencias del usuario
  UserModel updatePreferences(UserPreferences newPreferences) {
    return copyWith(
      preferences: newPreferences,
      metadata: metadata.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Activa/desactiva el usuario
  UserModel toggleActive() {
    return copyWith(
      isActive: !isActive,
      metadata: metadata.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Extiende el acceso temporal (para visitas)
  UserModel extendTemporaryAccess(DateTime newExpiry) {
    return copyWith(
      temporaryAccessExpiry: newExpiry,
      metadata: metadata.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Actualiza el rol del usuario
  UserModel updateRole(UserRole newRole) {
    return copyWith(
      role: newRole,
      metadata: metadata.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDACIONES ESPECÍFICAS PARA FIREBASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida que los datos son correctos antes de guardar en Firebase
  bool get isValidForFirestore {
    // Validaciones básicas
    if (name.isEmpty || email.isEmpty) return false;
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) return false;
    
    // Validaciones específicas por rol
    if (role == UserRole.hijoSocio && parentMemberId == null) return false;
    if (role == UserRole.hijoSocio && age != null && age! > 25) return false;
    if (role == UserRole.visita && temporaryAccessExpiry == null) return false;
    
    return true;
  }

  /// Obtiene warnings antes de guardar
  List<String> get firestoreWarnings {
    List<String> warnings = [];
    
    if (role == UserRole.hijoSocio && age != null && age! > 23) {
      warnings.add('Usuario cerca del límite de edad (25 años)');
    }
    
    if (role == UserRole.visita && temporaryAccessExpiry != null) {
      final daysLeft = temporaryAccessExpiry!.difference(DateTime.now()).inDays;
      if (daysLeft < 7) {
        warnings.add('Acceso temporal vence en $daysLeft días');
      }
    }
    
    if (membershipExpiry != null) {
      final daysLeft = membershipExpiry!.difference(DateTime.now()).inDays;
      if (daysLeft < 30) {
        warnings.add('Membresía vence en $daysLeft días');
      }
    }
    
    return warnings;
  }
}