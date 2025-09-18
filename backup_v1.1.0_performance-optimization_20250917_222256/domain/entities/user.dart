class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final UserRole role;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.birthDate,
    this.role = UserRole.socio,
    this.isActive = true,
  });

  bool get canMakeReservations => isActive;
  bool get mustPayForReservations => false;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? birthDate,
    UserRole? role,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum UserRole {
  socio,
  admin,
  guest;
  
  String get displayName {
    switch (this) {
      case UserRole.socio: return 'Socio';
      case UserRole.admin: return 'Administrador'; 
      case UserRole.guest: return 'Invitado';
    }
  }
  
  bool get isAdmin => this == UserRole.admin;
}