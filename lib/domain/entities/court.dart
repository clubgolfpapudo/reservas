// ============================================================================
// lib/domain/entities/court.dart - ACTUALIZAR COMPLETAMENTE
// ============================================================================

import 'package:equatable/equatable.dart';

class Court extends Equatable {
  final String? id;
  final String name;
  final String description;
  final int number;
  final int displayOrder;
  final String status;
  final bool isAvailableForBooking;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Court({
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

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    number,
    displayOrder,
    status,
    isAvailableForBooking,
    createdAt,
    updatedAt,
  ];

  bool get isActive => status == 'active';
  
  Court copyWith({
    String? id,
    String? name,
    String? description,
    int? number,
    int? displayOrder,
    String? status,
    bool? isAvailableForBooking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Court(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      number: number ?? this.number,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
      isAvailableForBooking: isAvailableForBooking ?? this.isAvailableForBooking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================================================
// lib/core/constants/app_constants.dart - VERIFICAR QUE TENGAS ESTO
// ============================================================================

class AppConstants {
  // Horarios disponibles
  static const List<String> timeSlots = [
    '09:00',
    '10:30', 
    '12:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '19:30',
  ];
  
  // Mapeo de IDs de canchas a nombres
  static const Map<String, String> courtNames = {
    'court_1': 'PITE',
    'court_2': 'LILEN', 
    'court_3': 'PLAIYA',
  };
  
  // Duraciones de animación
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  
  // Colores
  static const String primaryBlue = '#2E7AFF';
  static const String lightBlue = '#E8F4F9';
  static const String orange = '#FF7530';
}