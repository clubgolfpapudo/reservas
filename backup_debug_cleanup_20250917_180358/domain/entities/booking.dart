// ============================================================================
// lib/domain/entities/booking.dart - ACTUALIZAR COMPLETAMENTE
// ============================================================================

import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final String id;
  final String courtId;
  final String date;
  final String timeSlot;
  final List<BookingPlayer> players;
  final BookingStatus? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Booking({
    required this.id, // ✅ CORREGIDO: 'id' es ahora un parámetro requerido
    required this.courtId,
    required this.date,
    required this.timeSlot,
    required this.players,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    courtId,
    date,
    timeSlot,
    players,
    status,
    createdAt,
    updatedAt,
  ];

  Booking copyWith({
    String? id,
    String? courtId,
    String? date,
    String? timeSlot,
    List<BookingPlayer>? players,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      players: players ?? this.players,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'date': date,
      'timeSlot': timeSlot,
      'courtId': courtId,
      'players': players.map((p) => p.toFirestore()).toList(),
      'status': status,
    };
  }

  bool get isComplete => players.length == 4;
  bool get isIncomplete => players.isNotEmpty && players.length < 4;
  bool get isEmpty => players.isEmpty;

  // Calcular status dinámicamente basado en jugadores
  BookingStatus get calculatedStatus {
    final maxCapacity = _getMaxCapacityForCourt(courtId);
    return players.length >= maxCapacity 
        ? BookingStatus.complete 
        : BookingStatus.incomplete;
  }

  int _getMaxCapacityForCourt(String courtId) {
    if (courtId.startsWith('golf_')) return 4;
    if (courtId.startsWith('tennis_')) return 4;
    if (courtId.contains('pite') || courtId.contains('lilen') || courtId.contains('plaiya')) return 4;
    return 4; // default
  }
}

// ============================================================================
// BOOKING PLAYER
// ============================================================================

class BookingPlayer extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final bool isConfirmed;

  const BookingPlayer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.isConfirmed = true,
  });

  @override
  List<Object?> get props => [id, name, phone, email, isConfirmed];

  BookingPlayer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? isConfirmed,
  }) {
    return BookingPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  factory BookingPlayer.fromMap(Map<String, dynamic> map) {
    return BookingPlayer(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isConfirmed: map['isConfirmed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

// ============================================================================
// BOOKING STATUS
// ============================================================================

enum BookingStatus {
  complete,
  incomplete,
}