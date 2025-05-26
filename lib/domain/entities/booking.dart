// ============================================================================
// lib/domain/entities/booking.dart - ACTUALIZAR COMPLETAMENTE
// ============================================================================

import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final String? id;
  final String courtNumber;  // ← AGREGADO
  final String date;         // ← AGREGADO  
  final String timeSlot;     // ← AGREGADO
  final List<BookingPlayer> players;
  final BookingStatus? status;
  final DateTime? createdAt; // ← AGREGADO
  final DateTime? updatedAt; // ← AGREGADO

  const Booking({
    this.id,
    required this.courtNumber,
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
    courtNumber,
    date,
    timeSlot,
    players,
    status,
    createdAt,
    updatedAt,
  ];

  // ============================================================================
  // MÉTODOS DE CONVENIENCIA
  // ============================================================================
  
  bool get isComplete => players.length == 4;
  bool get isIncomplete => players.isNotEmpty && players.length < 4;
  bool get isEmpty => players.isEmpty;
  
  Booking copyWith({
    String? id,
    String? courtNumber,
    String? date,
    String? timeSlot,
    List<BookingPlayer>? players,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      courtNumber: courtNumber ?? this.courtNumber,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      players: players ?? this.players,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// BOOKING PLAYER
// ============================================================================

class BookingPlayer extends Equatable {
  final String name;
  final String? phone;    // ← AGREGADO
  final String? email;
  final bool isConfirmed;

  const BookingPlayer({
    required this.name,
    this.phone,
    this.email,
    this.isConfirmed = true,
  });

  @override
  List<Object?> get props => [name, phone, email, isConfirmed];
  
  BookingPlayer copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isConfirmed,
  }) {
    return BookingPlayer(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

// ============================================================================
// BOOKING STATUS
// ============================================================================

enum BookingStatus {
  complete,
  incomplete,
}