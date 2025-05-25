// lib/data/models/user_model.dart  
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.birthDate,
    required super.isActive,
    required super.isExempt,
    required super.role,
    required super.membershipNumber,
    super.membershipExpiry,
    required super.sponsorMemberId,
    required super.parentMemberId,
    required super.temporaryAccessExpiry,
    required super.preferences,
    required super.stats,
    required super.metadata,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      birthDate: data['birthDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['birthDate'])
          : null,
      isActive: data['isActive'] ?? true,
      isExempt: data['isExempt'] ?? false,
      role: UserRole.fromString(data['role'] ?? 'visita'),
      membershipNumber: data['membershipNumber'] ?? '',
      membershipExpiry: data['membershipExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['membershipExpiry'])
          : null,
      sponsorMemberId: data['sponsorMemberId'] ?? '',
      parentMemberId: data['parentMemberId'] ?? '',
      temporaryAccessExpiry: data['temporaryAccessExpiry'] ?? '',
      preferences: UserPreferencesModel.fromMap(data['preferences'] ?? {}),
      stats: UserStatsModel.fromMap(data['stats'] ?? {}),
      metadata: UserMetadataModel.fromMap(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'isActive': isActive,
      'isExempt': isExempt,
      'role': role.value,
      'membershipNumber': membershipNumber,
      'membershipExpiry': membershipExpiry?.millisecondsSinceEpoch,
      'sponsorMemberId': sponsorMemberId,
      'parentMemberId': parentMemberId,
      'temporaryAccessExpiry': temporaryAccessExpiry,
      'preferences': {
        'defaultCourt': preferences.defaultCourt,
        'notificationsEnabled': preferences.notificationsEnabled,
        'reminderHoursBeforeBooking': preferences.reminderHoursBeforeBooking,
      },
      'stats': {
        'totalBookings': stats.totalBookings,
        'cancelledBookings': stats.cancelledBookings,
        'noShowBookings': stats.noShowBookings,
        'totalAmountPaid': stats.totalAmountPaid,
        'lastBookingDate': stats.lastBookingDate?.millisecondsSinceEpoch,
      },
      'metadata': {
        'createdAt': metadata.createdAt,
        'updatedAt': metadata.updatedAt,
        'lastLogin': metadata.lastLogin,
      },
    };
  }
}

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    required super.defaultCourt,
    required super.notificationsEnabled,
    required super.reminderHoursBeforeBooking,
  });

  factory UserPreferencesModel.fromMap(Map<String, dynamic> data) {
    return UserPreferencesModel(
      defaultCourt: data['defaultCourt'] ?? 'PITE',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      reminderHoursBeforeBooking: data['reminderHoursBeforeBooking'] ?? 24,
    );
  }
}

class UserStatsModel extends UserStats {
  const UserStatsModel({
    required super.totalBookings,
    required super.cancelledBookings,
    required super.noShowBookings,
    required super.totalAmountPaid,
    super.lastBookingDate,
  });

  factory UserStatsModel.fromMap(Map<String, dynamic> data) {
    return UserStatsModel(
      totalBookings: data['totalBookings'] ?? 0,
      cancelledBookings: data['cancelledBookings'] ?? 0,
      noShowBookings: data['noShowBookings'] ?? 0,
      totalAmountPaid: data['totalAmountPaid'] ?? 0,
      lastBookingDate: data['lastBookingDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastBookingDate'])
          : null,
    );
  }
}

class UserMetadataModel extends UserMetadata {
  const UserMetadataModel({
    required super.createdAt,
    required super.updatedAt,
    super.lastLogin,
  });

  factory UserMetadataModel.fromMap(Map<String, dynamic> data) {
    return UserMetadataModel(
      createdAt: data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: data['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      lastLogin: data['lastLogin'],
    );
  }
}