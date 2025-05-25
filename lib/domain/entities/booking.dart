// lib/domain/entities/booking.dart
import 'package:flutter/material.dart';

class Booking {
  final String id;
  final String courtId;
  final int court; // Para compatibilidad con Google Sheets
  final BookingDateTime dateTime;
  final List<BookingPlayer> players;
  final int activePlayersCount;
  final BookingStatus status;
  final String calendlyUri;
  final BookingMetadata metadata;

  const Booking({
    required this.id,
    required this.courtId,
    required this.court,
    required this.dateTime,
    required this.players,
    required this.activePlayersCount,
    required this.status,
    required this.calendlyUri,
    required this.metadata,
  });

  // Getters útiles según reglas de negocio
  bool get isComplete => activePlayersCount == 4;
  bool get isIncomplete => activePlayersCount > 0 && activePlayersCount < 4;
  bool get isEmpty => activePlayersCount == 0;
  
  BookingPlayer? get mainBooker {
    try {
      return players.firstWhere((p) => p.isMainBooker);
    } catch (e) {
      return null;
    }
  }
  
  List<BookingPlayer> get confirmedPlayers => 
    players.where((p) => p.status == PlayerStatus.confirmed).toList();
    
  List<BookingPlayer> get cancelledPlayers => 
    players.where((p) => p.status == PlayerStatus.cancelled).toList();

  // Método para obtener nombres de jugadores confirmados separados por *
  String get playersDisplayText {
    return confirmedPlayers
        .map((player) => player.name)
        .join(' * ');
  }

  // copyWith para actualizaciones
  Booking copyWith({
    String? id,
    String? courtId,
    int? court,
    BookingDateTime? dateTime,
    List<BookingPlayer>? players,
    int? activePlayersCount,
    BookingStatus? status,
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
      calendlyUri: calendlyUri ?? this.calendlyUri,
      metadata: metadata ?? this.metadata,
    );
  }
}

class BookingDateTime {
  final int day;           // Día numérico (para compatibilidad)
  final String month;      // Mes abreviado (para compatibilidad)
  final String date;       // Fecha normalizada YYYY-MM-DD
  final String time;       // Hora de inicio formato HH:MM
  final int timestamp;     // Timestamp para operaciones y ordenamiento

  const BookingDateTime({
    required this.day,
    required this.month,
    required this.date,
    required this.time,
    required this.timestamp,
  });

  DateTime get dateTimeObject => DateTime.fromMillisecondsSinceEpoch(timestamp);
  
  String get formattedDateTime => '$date $time';
  String get displayDate => '$day $month';
  String get displayTime => time;

  // copyWith
  BookingDateTime copyWith({
    int? day,
    String? month,
    String? date,
    String? time,
    int? timestamp,
  }) {
    return BookingDateTime(
      day: day ?? this.day,
      month: month ?? this.month,
      date: date ?? this.date,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class BookingPlayer {
  final String? id;        // ID de usuario en Firebase (nullable para invitados)
  final String name;       // Nombre completo
  final String email;      // Correo electrónico
  final bool isMainBooker; // Indica que es quien inició la reserva
  final PlayerStatus status; // Estado: confirmed o cancelled

  const BookingPlayer({
    this.id,
    required this.name,
    required this.email,
    required this.isMainBooker,
    required this.status,
  });

  bool get isRegisteredUser => id != null && id!.isNotEmpty;
  bool get isGuest => id == null || id!.isEmpty;
  bool get isConfirmed => status == PlayerStatus.confirmed;
  bool get isCancelled => status == PlayerStatus.cancelled;

  // copyWith
  BookingPlayer copyWith({
    String? id,
    String? name,
    String? email,
    bool? isMainBooker,
    PlayerStatus? status,
  }) {
    return BookingPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isMainBooker: isMainBooker ?? this.isMainBooker,
      status: status ?? this.status,
    );
  }
}

class BookingMetadata {
  final int createdAt;     // Fecha de creación (timestamp)
  final int updatedAt;     // Última actualización (timestamp)
  final String createdBy;  // Referencia a quien creó la reserva

  const BookingMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  DateTime get createdAtDateTime => 
    DateTime.fromMillisecondsSinceEpoch(createdAt);
  DateTime get updatedAtDateTime => 
    DateTime.fromMillisecondsSinceEpoch(updatedAt);

  // copyWith
  BookingMetadata copyWith({
    int? createdAt,
    int? updatedAt,
    String? createdBy,
  }) {
    return BookingMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// Enums según diseño del documento
enum BookingStatus {
  complete,    // 4 jugadores confirmados
  incomplete,  // <4 jugadores confirmados
  cancelled;   // Reserva cancelada

  String get displayName {
    switch (this) {
      case BookingStatus.complete:
        return 'Reservada';
      case BookingStatus.incomplete:
        return 'Incompleta';
      case BookingStatus.cancelled:
        return 'Cancelada';
    }
  }

  // Colores según documento de diseño
  Color get color {
    switch (this) {
      case BookingStatus.complete:
        return const Color(0xFF2E7AFF); // Azul
      case BookingStatus.incomplete:
        return const Color(0xFFFF7530); // Naranja
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case BookingStatus.complete:
        return const Color(0xFF2E7AFF); // Azul
      case BookingStatus.incomplete:
        return const Color(0xFFFF7530); // Naranja
      case BookingStatus.cancelled:
        return Colors.red.shade100;
    }
  }

  Color get textColor {
    switch (this) {
      case BookingStatus.complete:
        return Colors.white;
      case BookingStatus.incomplete:
        return Colors.white;
      case BookingStatus.cancelled:
        return Colors.red.shade800;
    }
  }
}

enum PlayerStatus {
  confirmed,
  cancelled;

  String get displayName {
    switch (this) {
      case PlayerStatus.confirmed:
        return 'Confirmado';
      case PlayerStatus.cancelled:
        return 'Cancelado';
    }
  }
}

// Estado para slots disponibles (cuando no hay reserva)
enum TimeSlotStatus {
  available;

  String get displayName => 'Disponible';
  
  Color get backgroundColor => const Color(0xFFE8F4F9); // Azul claro
  Color get textColor => Colors.black;
}