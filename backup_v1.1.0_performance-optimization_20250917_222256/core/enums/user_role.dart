// lib/core/enums/user_role.dart
enum UserRole {
  socio,
  hijoSocio,
  visita,
  admin;
  
  String get value => name;
}

// lib/core/enums/player_status.dart  
enum PlayerStatus {
  confirmed,
  pending,
  cancelled;
}

// lib/core/enums/court_status.dart
enum CourtStatus {
  active,
  inactive,
  maintenance;
}