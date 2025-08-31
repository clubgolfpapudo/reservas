// ============================================================================
// lib/data/models/booking_model.dart - CORREGIDO
// ============================================================================

import 'package:cgp_reservas/domain/entities/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

class BookingModel {
  final String? id;
  final String courtId;
  final String date;
  final String timeSlot;
  final List<BookingPlayerModel> players;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookingModel({
    this.id,
    required this.courtId,
    required this.date,
    required this.timeSlot,
    required this.players,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================================
  // CONVERSIÓN DESDE FIRESTORE - 🔥 CORREGIDO
  // ============================================================================
  
  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    print('🔍 FIRESTORE RAW DATA: $data');
    
    // 🔥 CORREGIDO: Mapear nombres correctos de campos
    final courtId = data['courtId'] ?? data['courtNumber'] ?? '';
    final date = data['date'] ?? data['dateTime']?['date'] ?? '';
    final timeSlot = data['timeSlot'] ?? data['time'] ?? data['dateTime']?['time'] ?? '';
    
    print('🔍 MAPPED VALUES: courtId="$courtId", date="$date", timeSlot="$timeSlot"');
    
    return BookingModel(
      id: id,
      courtId: courtId,
      date: date,
      timeSlot: timeSlot,
      players: (data['players'] as List<dynamic>?)
          ?.map((player) => BookingPlayerModel.fromMap(player as Map<String, dynamic>))
          .toList() ?? [],
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ============================================================================
  // CONVERSIÓN A FIRESTORE - SIN CAMBIOS
  // ============================================================================
  
  Map<String, dynamic> toFirestore() {
    return {
      'courtId': courtId,  // ← Guarda como courtId
      'date': date,               // ← Guarda como date
      'timeSlot': timeSlot,       // ← Guarda como timeSlot
      'players': players.map((player) => player.toMap()).toList(),
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================================
  // CONVERSIÓN ENTITY ↔ MODEL - SIN CAMBIOS
  // ============================================================================
  
  factory BookingModel.fromEntity(Booking booking) {
    return BookingModel(
      id: booking.id,
      courtId: booking.courtId,
      date: booking.date,
      timeSlot: booking.timeSlot,
      players: booking.players.map((player) => BookingPlayerModel.fromPlayer(player)).toList(),
      status: booking.status?.name,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
    );
  }

  Booking toEntity() {
    BookingStatus? bookingStatus;
    final playersList = players.map((player) => player.toPlayer()).toList();

    if (playersList.isEmpty) {
      bookingStatus = null;
    } else if (playersList.length == 4) {
      bookingStatus = BookingStatus.complete;
    } else {
      bookingStatus = BookingStatus.incomplete;
    }

    // ✅ CÓDIGO CORREGIDO
    // Asegurarse de que el 'id' no sea nulo
    return Booking(
      id: id ?? '', // Si el id es nulo, usa una cadena vacía para evitar errores
      courtId: courtId,
      date: date,
      timeSlot: timeSlot,
      players: playersList,
      status: bookingStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ============================================================================
// BOOKING PLAYER MODEL - SIN CAMBIOS
// ============================================================================

class BookingPlayerModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final bool isConfirmed;

  const BookingPlayerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.isConfirmed = true,
  });

  @override
  List<Object?> get props => [id, name, phone, email, isConfirmed];

  factory BookingPlayerModel.fromMap(Map<String, dynamic> map) {
    return BookingPlayerModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isConfirmed: map['isConfirmed'] as bool? ?? map['status'] == 'confirmed' ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'isConfirmed': isConfirmed,
    };
  }

  factory BookingPlayerModel.fromPlayer(BookingPlayer player) {
    return BookingPlayerModel(
      id: player.id,
      name: player.name,
      phone: player.phone,
      email: player.email,
      isConfirmed: player.isConfirmed,
    );
  }

  BookingPlayer toPlayer() {
    return BookingPlayer(
      id: id,
      name: name,
      phone: phone,
      email: email,
      isConfirmed: isConfirmed,
    );
  }
}