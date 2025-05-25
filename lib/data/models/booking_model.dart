// lib/data/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.courtId,
    required super.court,
    required super.dateTime,
    required super.players,
    required super.activePlayersCount,
    required super.status,
    required super.calendlyUri,
    required super.metadata,
  });

  // Factory constructor desde Firestore
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BookingModel(
      id: doc.id,
      courtId: data['courtId'] ?? '',
      court: data['court'] ?? 0,
      dateTime: BookingDateTimeModel.fromMap(data['dateTime'] ?? {}),
      players: (data['players'] as List<dynamic>? ?? [])
          .map((playerData) => BookingPlayerModel.fromMap(playerData))
          .toList(),
      activePlayersCount: data['activePlayersCount'] ?? 0,
      status: BookingStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => BookingStatus.incomplete,
      ),
      calendlyUri: data['calendlyUri'] ?? '',
      metadata: BookingMetadataModel.fromMap(data['metadata'] ?? {}),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'courtId': courtId,
      'court': court,
      'dateTime': {
        'day': dateTime.day,
        'month': dateTime.month,
        'date': dateTime.date,
        'time': dateTime.time,
        'timestamp': dateTime.timestamp,
      },
      'players': players.map((player) => {
        'id': player.id,
        'name': player.name,
        'email': player.email,
        'isMainBooker': player.isMainBooker,
        'status': player.status.name,
      }).toList(),
      'activePlayersCount': activePlayersCount,
      'status': status.name,
      'calendlyUri': calendlyUri,
      'metadata': {
        'createdAt': metadata.createdAt,
        'updatedAt': metadata.updatedAt,
        'createdBy': metadata.createdBy,
      },
    };
  }
}

class BookingDateTimeModel extends BookingDateTime {
  const BookingDateTimeModel({
    required super.day,
    required super.month,
    required super.date,
    required super.time,
    required super.timestamp,
  });

  factory BookingDateTimeModel.fromMap(Map<String, dynamic> data) {
    return BookingDateTimeModel(
      day: data['day'] ?? 0,
      month: data['month'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      timestamp: data['timestamp'] ?? 0,
    );
  }
}

class BookingPlayerModel extends BookingPlayer {
  const BookingPlayerModel({
    super.id,
    required super.name,
    required super.email,
    required super.isMainBooker,
    required super.status,
  });

  factory BookingPlayerModel.fromMap(Map<String, dynamic> data) {
    return BookingPlayerModel(
      id: data['id'],
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isMainBooker: data['isMainBooker'] ?? false,
      status: PlayerStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => PlayerStatus.cancelled,
      ),
    );
  }
}

class BookingMetadataModel extends BookingMetadata {
  const BookingMetadataModel({
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
  });

  factory BookingMetadataModel.fromMap(Map<String, dynamic> data) {
    return BookingMetadataModel(
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
      createdBy: data['createdBy'] ?? '',
    );
  }
}