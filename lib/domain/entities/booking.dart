// lib/domain/entities/booking.dart
import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD PRINCIPAL: BOOKING
// ═══════════════════════════════════════════════════════════════════════════════

class Booking extends Equatable {
  final String id;
  final String courtId;
  final int court;
  final BookingDateTime dateTime;
  final List<Player> players;
  final int activePlayersCount;
  final BookingStatus status;
  final bool visibleInCalendar;
  final String? calendlyUri;
  final BookingMetadata metadata;

  const Booking({
    required this.id,
    required this.courtId,
    required this.court,
    required this.dateTime,
    required this.players,
    required this.activePlayersCount,
    required this.status,
    required this.visibleInCalendar,
    this.calendlyUri,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        courtId,
        court,
        dateTime,
        players,
        activePlayersCount,
        status,
        visibleInCalendar,
        calendlyUri,
        metadata,
      ];

  Booking copyWith({
    String? id,
    String? courtId,
    int? court,
    BookingDateTime? dateTime,
    List<Player>? players,
    int? activePlayersCount,
    BookingStatus? status,
    bool? visibleInCalendar,
    String? calendlyUri,
    BookingMetadata? metadata,
  }) {
    return Booking(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      court: court ?? this.court,
      dateTime: dateTime ?? this.dateTime,
      players: players ?? this.players,
      activePlayersCount: activePlayersCount ?? this.activePlayersCount,
      status: status ?? this.status,
      visibleInCalendar: visibleInCalendar ?? this.visibleInCalendar,
      calendlyUri: calendlyUri ?? this.calendlyUri,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: BOOKING DATE TIME
// ═══════════════════════════════════════════════════════════════════════════════

class BookingDateTime extends Equatable {
  final int day;
  final String month;
  final int year;
  final String date;
  final String time;
  final int timestamp;
  final String weekday;

  const BookingDateTime({
    required this.day,
    required this.month,
    required this.year,
    required this.date,
    required this.time,
    required this.timestamp,
    required this.weekday,
  });

  factory BookingDateTime.fromMap(Map<String, dynamic> map) {
    return BookingDateTime(
      day: map['day'] ?? 0,
      month: map['month'] ?? '',
      year: map['year'] ?? 0,
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      weekday: map['weekday'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'date': date,
      'time': time,
      'timestamp': timestamp,
      'weekday': weekday,
    };
  }

  @override
  List<Object> get props => [day, month, year, date, time, timestamp, weekday];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: PLAYER
// ═══════════════════════════════════════════════════════════════════════════════

class Player extends Equatable {
  final String? id;
  final String name;
  final String email;
  final bool isMainBooker;
  final PlayerStatus status;
  final int statusChangedAt;
  final String statusChangedBy;

  const Player({
    this.id,
    required this.name,
    required this.email,
    required this.isMainBooker,
    required this.status,
    required this.statusChangedAt,
    required this.statusChangedBy,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isMainBooker: map['isMainBooker'] ?? false,
      status: PlayerStatus.fromString(map['status'] ?? 'confirmed'),
      statusChangedAt: map['statusChangedAt'] ?? 0,
      statusChangedBy: map['statusChangedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isMainBooker': isMainBooker,
      'status': status.value,
      'statusChangedAt': statusChangedAt,
      'statusChangedBy': statusChangedBy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        isMainBooker,
        status,
        statusChangedAt,
        statusChangedBy,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: BOOKING METADATA
// ═══════════════════════════════════════════════════════════════════════════════

class BookingMetadata extends Equatable {
  final int createdAt;
  final int updatedAt;
  final String createdBy;
  final String updatedBy;
  final String syncSource;
  final int lastSyncAt;

  const BookingMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.syncSource,
    required this.lastSyncAt,
  });

  factory BookingMetadata.fromMap(Map<String, dynamic> map) {
    return BookingMetadata(
      createdAt: map['createdAt'] ?? 0,
      updatedAt: map['updatedAt'] ?? 0,
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      syncSource: map['syncSource'] ?? '',
      lastSyncAt: map['lastSyncAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'syncSource': syncSource,
      'lastSyncAt': lastSyncAt,
    };
  }

  @override
  List<Object> get props => [
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        syncSource,
        lastSyncAt,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum BookingStatus {
  complete('complete'),
  incomplete('incomplete'),
  cancelled('cancelled');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    switch (value) {
      case 'complete':
        return BookingStatus.complete;
      case 'incomplete':
        return BookingStatus.incomplete;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.incomplete;
    }
  }
}

enum PlayerStatus {
  confirmed('confirmed'),
  cancelled('cancelled');

  const PlayerStatus(this.value);
  final String value;

  static PlayerStatus fromString(String value) {
    switch (value) {
      case 'confirmed':
        return PlayerStatus.confirmed;
      case 'cancelled':
        return PlayerStatus.cancelled;
      default:
        return PlayerStatus.confirmed;
    }
  }
}