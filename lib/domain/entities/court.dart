// lib/domain/entities/court.dart
import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD PRINCIPAL: COURT
// ═══════════════════════════════════════════════════════════════════════════════

class Court extends Equatable {
  final String id;
  final int number;
  final String name;
  final String? description;
  final CourtStatus status;
  final bool isAvailableForBooking;
  final String? seasonId;
  final List<String>? customTimeSlots;
  final List<CourtException> exceptions;
  final int bookingDurationMinutes;
  final int requiredPlayers;
  final int displayOrder;
  final String? color;
  final CourtMetadata metadata;

  const Court({
    required this.id,
    required this.number,
    required this.name,
    this.description,
    required this.status,
    required this.isAvailableForBooking,
    this.seasonId,
    this.customTimeSlots,
    this.exceptions = const [],
    required this.bookingDurationMinutes,
    required this.requiredPlayers,
    required this.displayOrder,
    this.color,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        number,
        name,
        description,
        status,
        isAvailableForBooking,
        seasonId,
        customTimeSlots,
        exceptions,
        bookingDurationMinutes,
        requiredPlayers,
        displayOrder,
        color,
        metadata,
      ];

  Court copyWith({
    String? id,
    int? number,
    String? name,
    String? description,
    CourtStatus? status,
    bool? isAvailableForBooking,
    String? seasonId,
    List<String>? customTimeSlots,
    List<CourtException>? exceptions,
    int? bookingDurationMinutes,
    int? requiredPlayers,
    int? displayOrder,
    String? color,
    CourtMetadata? metadata,
  }) {
    return Court(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      isAvailableForBooking: isAvailableForBooking ?? this.isAvailableForBooking,
      seasonId: seasonId ?? this.seasonId,
      customTimeSlots: customTimeSlots ?? this.customTimeSlots,
      exceptions: exceptions ?? this.exceptions,
      bookingDurationMinutes: bookingDurationMinutes ?? this.bookingDurationMinutes,
      requiredPlayers: requiredPlayers ?? this.requiredPlayers,
      displayOrder: displayOrder ?? this.displayOrder,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: COURT EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════════

class CourtException extends Equatable {
  final String date;
  final String reason;
  final List<String> availableTimeSlots;
  final bool isFullyClosed;

  const CourtException({
    required this.date,
    required this.reason,
    required this.availableTimeSlots,
    required this.isFullyClosed,
  });

  factory CourtException.fromMap(Map<String, dynamic> map) {
    return CourtException(
      date: map['date'] ?? '',
      reason: map['reason'] ?? '',
      availableTimeSlots: (map['availableTimeSlots'] as List<dynamic>?)
              ?.cast<String>() ?? [],
      isFullyClosed: map['isFullyClosed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'reason': reason,
      'availableTimeSlots': availableTimeSlots,
      'isFullyClosed': isFullyClosed,
    };
  }

  @override
  List<Object> get props => [date, reason, availableTimeSlots, isFullyClosed];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: COURT METADATA
// ═══════════════════════════════════════════════════════════════════════════════

class CourtMetadata extends Equatable {
  final int createdAt;
  final int updatedAt;

  const CourtMetadata({
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourtMetadata.fromMap(Map<String, dynamic> map) {
    return CourtMetadata(
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object> get props => [createdAt, updatedAt];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum CourtStatus {
  active('active'),
  maintenance('maintenance'),
  inactive('inactive');

  const CourtStatus(this.value);
  final String value;

  static CourtStatus fromString(String value) {
    switch (value) {
      case 'active':
        return CourtStatus.active;
      case 'maintenance':
        return CourtStatus.maintenance;
      case 'inactive':
        return CourtStatus.inactive;
      default:
        return CourtStatus.active;
    }
  }
}