// lib/domain/entities/user.dart
import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD PRINCIPAL: USER
// ═══════════════════════════════════════════════════════════════════════════════

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final bool isExempt;
  final bool isActive;
  
  // Campos específicos del club
  final String? membershipNumber;     // Número de socio
  final String? parentMemberId;       // ID del socio titular (para hijos)
  final DateTime? birthDate;          // Fecha nacimiento (para validar edad límite)
  final DateTime? membershipExpiry;   // Vencimiento de membresía
  final String? sponsorMemberId;      // ID del socio que invita (para visitas - opcional)
  final DateTime? temporaryAccessExpiry; // Vencimiento acceso temporal (visitas)
  
  final UserPreferences preferences;
  final UserStats stats;
  final UserMetadata metadata;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isExempt,
    required this.isActive,
    this.membershipNumber,
    this.parentMemberId,
    this.birthDate,
    this.membershipExpiry,
    this.sponsorMemberId,
    this.temporaryAccessExpiry,
    required this.preferences,
    required this.stats,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        isExempt,
        isActive,
        membershipNumber,
        parentMemberId,
        birthDate,
        membershipExpiry,
        sponsorMemberId,
        temporaryAccessExpiry,
        preferences,
        stats,
        metadata,
      ];

  User copyWith({
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
    return User(
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
  // MÉTODOS DE VALIDACIÓN Y REGLAS DE NEGOCIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcula la edad actual del usuario
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Verifica si el usuario es elegible como hijo de socio (≤ 25 años)
  bool get isEligibleAsChild {
    if (role != UserRole.hijoSocio) return true;
    return age != null && age! <= 25;
  }

  /// Verifica si el usuario tiene acceso temporal válido
  bool get hasValidTemporaryAccess {
    if (role != UserRole.visita) return true;
    if (temporaryAccessExpiry == null) return false;
    return DateTime.now().isBefore(temporaryAccessExpiry!);
  }

  /// Verifica si la membresía está vigente
  bool get hasMembershipActive {
    if (role == UserRole.admin || role == UserRole.visita) return true;
    if (membershipExpiry == null) return true; // Sin vencimiento
    return DateTime.now().isBefore(membershipExpiry!);
  }

  /// Verifica si el usuario puede hacer reservas
  bool get canMakeReservations {
    return isActive && 
           hasMembershipActive && 
           isEligibleAsChild &&
           (role != UserRole.visita || hasValidTemporaryAccess);
  }

  /// Verifica si el usuario debe pagar por las reservas
  bool get mustPayForReservations {
    return role == UserRole.visita || role == UserRole.filial;
  }

  /// Verifica si el usuario puede reservar sin restricciones de horario
  bool get canReserveWithoutTimeRestrictions {
    return role == UserRole.admin || 
           role == UserRole.socioTitular || 
           role == UserRole.hijoSocio;
  }

  /// Obtiene las restricciones de horario para el usuario
  List<String> get allowedTimeSlots {
    if (canReserveWithoutTimeRestrictions) {
      return []; // Sin restricciones (todos los horarios)
    }
    
    // Restricciones para visitas y filial
    // Esto podría venir de configuración, pero por ahora hardcoded
    if (role == UserRole.visita) {
      return ['09:00', '10:30', '15:00', '16:30']; // Horarios limitados
    }
    
    if (role == UserRole.filial) {
      return ['09:00', '10:30', '12:00', '13:30']; // Horarios de mañana/mediodía
    }
    
    return [];
  }

  /// Obtiene los días permitidos para reservar
  List<int> get allowedWeekdays {
    if (canReserveWithoutTimeRestrictions) {
      return [1, 2, 3, 4, 5, 6, 7]; // Todos los días
    }
    
    // Restricciones para visitas y filial
    if (role == UserRole.visita) {
      return [1, 2, 3, 4, 5]; // Solo días de semana
    }
    
    if (role == UserRole.filial) {
      return [2, 3, 4]; // Solo martes, miércoles, jueves
    }
    
    return [1, 2, 3, 4, 5, 6, 7];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: USER PREFERENCES
// ═══════════════════════════════════════════════════════════════════════════════

class UserPreferences extends Equatable {
  final bool notificationsEnabled;
  final int reminderHoursBeforeBooking;
  final String defaultCourtView;

  const UserPreferences({
    required this.notificationsEnabled,
    required this.reminderHoursBeforeBooking,
    required this.defaultCourtView,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      reminderHoursBeforeBooking: map['reminderHoursBeforeBooking'] ?? 24,
      defaultCourtView: map['defaultCourtView'] ?? 'PITE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'reminderHoursBeforeBooking': reminderHoursBeforeBooking,
      'defaultCourtView': defaultCourtView,
    };
  }

  @override
  List<Object> get props => [
        notificationsEnabled,
        reminderHoursBeforeBooking,
        defaultCourtView,
      ];

  UserPreferences copyWith({
    bool? notificationsEnabled,
    int? reminderHoursBeforeBooking,
    String? defaultCourtView,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHoursBeforeBooking: reminderHoursBeforeBooking ?? this.reminderHoursBeforeBooking,
      defaultCourtView: defaultCourtView ?? this.defaultCourtView,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: USER STATS
// ═══════════════════════════════════════════════════════════════════════════════

class UserStats extends Equatable {
  final int totalBookings;
  final int cancelledBookings;
  final int noShowBookings;
  final double totalAmountPaid;        // Total pagado en reservas
  final String? lastBookingDate;

  const UserStats({
    required this.totalBookings,
    required this.cancelledBookings,
    required this.noShowBookings,
    required this.totalAmountPaid,
    this.lastBookingDate,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalBookings: map['totalBookings'] ?? 0,
      cancelledBookings: map['cancelledBookings'] ?? 0,
      noShowBookings: map['noShowBookings'] ?? 0,
      totalAmountPaid: (map['totalAmountPaid'] ?? 0.0).toDouble(),
      lastBookingDate: map['lastBookingDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBookings': totalBookings,
      'cancelledBookings': cancelledBookings,
      'noShowBookings': noShowBookings,
      'totalAmountPaid': totalAmountPaid,
      'lastBookingDate': lastBookingDate,
    };
  }

  @override
  List<Object?> get props => [
        totalBookings,
        cancelledBookings,
        noShowBookings,
        totalAmountPaid,
        lastBookingDate,
      ];

  UserStats copyWith({
    int? totalBookings,
    int? cancelledBookings,
    int? noShowBookings,
    double? totalAmountPaid,
    String? lastBookingDate,
  }) {
    return UserStats(
      totalBookings: totalBookings ?? this.totalBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      noShowBookings: noShowBookings ?? this.noShowBookings,
      totalAmountPaid: totalAmountPaid ?? this.totalAmountPaid,
      lastBookingDate: lastBookingDate ?? this.lastBookingDate,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: USER METADATA
// ═══════════════════════════════════════════════════════════════════════════════

class UserMetadata extends Equatable {
  final int createdAt;
  final int updatedAt;
  final int lastLogin;

  const UserMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
  });

  factory UserMetadata.fromMap(Map<String, dynamic> map) {
    return UserMetadata(
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      lastLogin: map['lastLogin'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLogin': lastLogin,
    };
  }

  @override
  List<Object> get props => [createdAt, updatedAt, lastLogin];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum UserRole {
  admin('admin'),
  socioTitular('socio_titular'),
  hijoSocio('hijo_socio'),
  visita('visita'),
  filial('filial');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'socio_titular':
        return UserRole.socioTitular;
      case 'hijo_socio':
        return UserRole.hijoSocio;
      case 'visita':
        return UserRole.visita;
      case 'filial':
        return UserRole.filial;
      default:
        return UserRole.socioTitular;
    }
  }

  // Helpers para UI
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.socioTitular:
        return 'Socio Titular';
      case UserRole.hijoSocio:
        return 'Hijo de Socio';
      case UserRole.visita:
        return 'Visita';
      case UserRole.filial:
        return 'Filial';
    }
  }

  // Verificaciones rápidas
  bool get isAdmin => this == UserRole.admin;
  bool get isSocio => this == UserRole.socioTitular;
  bool get isHijoSocio => this == UserRole.hijoSocio;
  bool get isVisita => this == UserRole.visita;
  bool get isFilial => this == UserRole.filial;
  
  // Privilegios base
  bool get canManageBookings => isAdmin;
  bool get canViewAllBookings => isAdmin || isSocio;
  bool get needsPayment => isVisita || isFilial;
  bool get hasTimeRestrictions => isVisita || isFilial;
}