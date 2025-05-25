// lib/domain/entities/court.dart
class Court {
  final String id;
  final int number;
  final String name;
  final CourtStatus status;
  final CourtMetadata metadata;

  const Court({
    required this.id,
    required this.number,
    required this.name,
    required this.status,
    required this.metadata,
  });

  // Getters útiles
  bool get isActive => status == CourtStatus.active;
  bool get isInMaintenance => status == CourtStatus.maintenance;
  bool get isInactive => status == CourtStatus.inactive;

  String get displayName => name;
  String get fullDisplayName => '$name (Cancha $number)';

  // copyWith
  Court copyWith({
    String? id,
    int? number,
    String? name,
    CourtStatus? status,
    CourtMetadata? metadata,
  }) {
    return Court(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CourtMetadata {
  final int createdAt;
  final int updatedAt;

  const CourtMetadata({
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get createdAtDateTime => 
    DateTime.fromMillisecondsSinceEpoch(createdAt);
  DateTime get updatedAtDateTime => 
    DateTime.fromMillisecondsSinceEpoch(updatedAt);

  // copyWith
  CourtMetadata copyWith({
    int? createdAt,
    int? updatedAt,
  }) {
    return CourtMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum CourtStatus {
  active,
  maintenance,
  inactive;

  String get displayName {
    switch (this) {
      case CourtStatus.active:
        return 'Activa';
      case CourtStatus.maintenance:
        return 'Mantenimiento';
      case CourtStatus.inactive:
        return 'Inactiva';
    }
  }

  bool get canBeBooked => this == CourtStatus.active;
}