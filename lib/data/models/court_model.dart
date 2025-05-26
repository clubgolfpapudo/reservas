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

  CourtModel({
    this.id,
    required this.name,
    required this.description,
    required this.number,
    required this.displayOrder,
    required this.status,
    required this.isAvailableForBooking,
  });

  factory CourtModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CourtModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      number: data['number'] ?? 0,
      displayOrder: data['displayOrder'] ?? 0,
      status: data['status'] ?? 'active',
      isAvailableForBooking: data['isAvailableForBooking'] ?? true,
    );
  }

  Court toEntity() {
    return Court(
      id: id,
      name: name,
      description: description,
      number: number,
      displayOrder: displayOrder,
      status: status,
      isAvailableForBooking: isAvailableForBooking,
    );
  }
}