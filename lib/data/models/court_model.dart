// lib/data/models/court_model.dart - ACTUALIZAR para usar tu estructura
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/court.dart';

class CourtModel {
  final String? id;
  final String name;
  final String description;
  final int number;
  final int displayOrder;
  final String status;
  final bool isAvailableForBooking;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourtModel({
    this.id,
    required this.name,
    required this.description,
    required this.number,
    required this.displayOrder,
    required this.status,
    required this.isAvailableForBooking,
    this.createdAt,
    this.updatedAt,
  });

  // Conversión desde Firestore
  factory CourtModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CourtModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      number: data['number'] ?? 1,
      displayOrder: data['displayOrder'] ?? 1,
      status: data['status'] ?? 'active',
      isAvailableForBooking: data['isAvailableForBooking'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Conversión a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'number': number,
      'displayOrder': displayOrder,
      'status': status,
      'isAvailableForBooking': isAvailableForBooking,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Conversión desde Entity
  factory CourtModel.fromEntity(Court court) {
    return CourtModel(
      id: court.id,
      name: court.name,
      description: court.description,
      number: court.number,
      displayOrder: court.displayOrder,
      status: court.status,
      isAvailableForBooking: court.isAvailableForBooking,
      createdAt: court.createdAt,
      updatedAt: court.updatedAt,
    );
  }

  // Conversión a Entity
  Court toEntity() {
    return Court(
      id: id,
      name: name,
      description: description,
      number: number,
      displayOrder: displayOrder,
      status: status,
      isAvailableForBooking: isAvailableForBooking,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}