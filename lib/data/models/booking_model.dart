// ============================================================================
// lib/data/models/booking_model.dart - CREAR/REEMPLAZAR
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking.dart';

class BookingModel {
  final String? id;
  final String courtNumber;
  final String date;
  final String timeSlot;
  final List<BookingPlayerModel> players;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookingModel({
    this.id,
    required this.courtNumber,
    required this.date,
    required this.timeSlot,
    required this.players,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================================
  // CONVERSIÓN DESDE FIRESTORE
  // ============================================================================
  
  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BookingModel(
      id: id,
      courtNumber: data['courtId'] ?? '',
      date: data['dateTime']?['date'] ?? data['date'] ?? '',
      timeSlot: data['dateTime']?['time'] ?? data['time'] ?? '', // ← Para Google Sheets usa dateTime.time
      players: (data['players'] as List<dynamic>?)
          ?.map((player) => BookingPlayerModel.fromMap(player as Map<String, dynamic>))
          .toList() ?? [],
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ============================================================================
  // CONVERSIÓN A FIRESTORE
  // ============================================================================
  
  Map<String, dynamic> toFirestore() {
    return {
      'courtNumber': courtNumber,
      'date': date,
      'timeSlot': timeSlot,
      'players': players.map((player) => player.toMap()).toList(),
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================================
  // CONVERSIÓN ENTITY ↔ MODEL
  // ============================================================================
  
  factory BookingModel.fromEntity(Booking booking) {
    return BookingModel(
      id: booking.id,
      courtNumber: booking.courtNumber,
      date: booking.date,
      timeSlot: booking.timeSlot,
      players: booking.players.map((player) => BookingPlayerModel.fromPlayer(player)).toList(),
      status: booking.status?.name,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
    );
  }

  Booking toEntity() {
    // Calcular status basado en número de jugadores, no en el campo de Firebase
    BookingStatus? bookingStatus;
    final playersList = players.map((player) => player.toPlayer()).toList();
    
    if (playersList.isEmpty) {
      bookingStatus = null;  // Sin status si no hay jugadores
    } else if (playersList.length == 4) {
      bookingStatus = BookingStatus.complete;
    } else {
      bookingStatus = BookingStatus.incomplete;
    }

    return Booking(
      id: id,
      courtNumber: courtNumber,
      date: date,
      timeSlot: timeSlot,
      players: playersList,
      status: bookingStatus,  // Status calculado dinámicamente
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ============================================================================
// BOOKING PLAYER MODEL
// ============================================================================

class BookingPlayerModel {
  final String name;
  final String? phone;
  final String? email;
  final bool isConfirmed;

  BookingPlayerModel({
    required this.name,
    this.phone,
    this.email,
    this.isConfirmed = true,
  });

  factory BookingPlayerModel.fromMap(Map<String, dynamic> map) {
    return BookingPlayerModel(
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      isConfirmed: map['status'] == 'confirmed', // ← Convierte 'status' a boolean
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'isConfirmed': isConfirmed,
    };
  }

  factory BookingPlayerModel.fromPlayer(BookingPlayer player) {
    return BookingPlayerModel(
      name: player.name,
      phone: player.phone,
      email: player.email,
      isConfirmed: player.isConfirmed,
    );
  }

  BookingPlayer toPlayer() {
    return BookingPlayer(
      name: name,
      phone: phone,
      email: email,
      isConfirmed: isConfirmed,
    );
  }
}