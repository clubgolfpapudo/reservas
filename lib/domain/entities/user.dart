// lib/domain/entities/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? birthDate;
  final bool isActive;
  final bool isExempt;
  final UserRole role;
  final String membershipNumber;
  final DateTime? membershipExpiry;
  final String sponsorMemberId;
  final String parentMemberId;
  final String temporaryAccessExpiry;
  final UserPreferences preferences;
  final UserStats stats;
  final UserMetadata metadata;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.birthDate,
    required this.isActive,
    required this.isExempt,
    required this.role,
    required this.membershipNumber,
    this.membershipExpiry,
    required this.sponsorMemberId,
    required this.parentMemberId,
    required this.temporaryAccessExpiry,
    required this.preferences,
    required this.stats,
    required this.metadata,
  });

  // Getters útiles según documento
  bool get canMakeReservations => isActive && !_isMembershipExpired;
  bool get _isMembershipExpired => 
    membershipExpiry != null && membershipExpiry!.isBefore(DateTime.now());

  bool get mustPayForReservations => !isExempt && role != UserRole.admin;

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

  bool get isAdmin => role == UserRole.admin;
  bool get isSocio => role == UserRole.socioTitular || role == UserRole.socioAdhesion;
  bool get isChild => role == UserRole.hijoSocio;
  bool get isGuest => role == UserRole.visita;

  String get displayRole => role.displayName;

  // copyWith method
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? birthDate,
    bool? isActive,
    bool? isExempt,
    UserRole? role,
    String? membershipNumber,
    DateTime? membershipExpiry,
    String? sponsorMemberId,
    String? parentMemberId,
    String? temporaryAccessExpiry,
    UserPreferences? preferences,
    UserStats? stats,
    UserMetadata? metadata,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      isActive: isActive ?? this.isActive,
      isExempt: isExempt ?? this.isExempt,
      role: role ?? this.role,
      membershipNumber: membershipNumber ?? this.membershipNumber,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      sponsorMemberId: sponsorMemberId ?? this.sponsorMemberId,
      parentMemberId: parentMemberId ?? this.parentMemberId,
      temporaryAccessExpiry: temporaryAccessExpiry ?? this.temporaryAccessExpiry,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
    );
  }
}

class UserPreferences {
  final String defaultCourt;
  final bool notificationsEnabled;
  final int reminderHoursBeforeBooking;

  const UserPreferences({
    required this.defaultCourt,
    required this.notificationsEnabled,
    required this.reminderHoursBeforeBooking,
  });

  // copyWith method
  UserPreferences copyWith({
    String? defaultCourt,
    bool? notificationsEnabled,
    int? reminderHoursBeforeBooking,
  }) {
    return UserPreferences(
      defaultCourt: defaultCourt ?? this.defaultCourt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHoursBeforeBooking: reminderHoursBeforeBooking ?? this.reminderHoursBeforeBooking,
    );
  }
}

class UserStats {
  final int totalBookings;
  final int cancelledBookings;
  final int noShowBookings;
  final int totalAmountPaid;
  final DateTime? lastBookingDate;

  const UserStats({
    required this.totalBookings,
    required this.cancelledBookings,
    required this.noShowBookings,
    required this.totalAmountPaid,
    this.lastBookingDate,
  });

  // Getters útiles
  int get completedBookings => totalBookings - cancelledBookings - noShowBookings;
  double get cancellationRate => 
    totalBookings > 0 ? (cancelledBookings / totalBookings) * 100 : 0;
  double get noShowRate => 
    totalBookings > 0 ? (noShowBookings / totalBookings) * 100 : 0;

  // copyWith method
  UserStats copyWith({
    int? totalBookings,
    int? cancelledBookings,
    int? noShowBookings,
    int? totalAmountPaid,
    DateTime? lastBookingDate,
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

class UserMetadata {
  final int createdAt;
  final int updatedAt;
  final int? lastLogin;

  const UserMetadata({
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  DateTime get createdAtDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);
  DateTime get updatedAtDateTime => DateTime.fromMillisecondsSinceEpoch(updatedAt);
  DateTime? get lastLoginDateTime => 
    lastLogin != null ? DateTime.fromMillisecondsSinceEpoch(lastLogin!) : null;

  // copyWith method
  UserMetadata copyWith({
    int? createdAt,
    int? updatedAt,
    int? lastLogin,
  }) {
    return UserMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

enum UserRole {
  admin,
  socioTitular,
  socioAdhesion,
  hijoSocio,
  visita;

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.socioTitular:
        return 'socio_titular';
      case UserRole.socioAdhesion:
        return 'socio_adhesion';
      case UserRole.hijoSocio:
        return 'hijo_socio';
      case UserRole.visita:
        return 'visita';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.socioTitular:
        return 'Socio Titular';
      case UserRole.socioAdhesion:
        return 'Socio Adhesión';
      case UserRole.hijoSocio:
        return 'Hijo de Socio';
      case UserRole.visita:
        return 'Visita';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isSocio => this == UserRole.socioTitular || this == UserRole.socioAdhesion;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.visita,
    );
  }
}