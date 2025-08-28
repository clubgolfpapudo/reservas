// lib/core/services/golf_validation_service.dart
// VALIDACIÓN ESPECÍFICA GOLF - No reservas simultáneas Hoyo 1 y Hoyo 10

import '../models/reservation.dart';
import '../models/player.dart';

class GolfValidationService {
  
  // ✅ VALIDAR RESERVA GOLF - Restricción tees simultáneos
  static ValidationResult validateGolfReservation({
    required List<Player> players,
    required String courtId, // 'golf_tee_1' o 'golf_tee_10'
    required DateTime date,
    required TimeOfDay startTime,
    required List<Reservation> existingReservations,
  }) {
    
    // Validación por cada jugador
    for (final player in players) {
      final conflict = _checkSimultaneousTeeConflict(
        player,
        courtId,
        date,
        startTime,
        existingReservations,
      );
      
      if (conflict != null) {
        return ValidationResult(
          isValid: false,
          reason: conflict,
        );
      }
    }
    
    return ValidationResult(isValid: true);
  }
  
  // ✅ VERIFICAR CONFLICTO TEES SIMULTÁNEOS
  static String? _checkSimultaneousTeeConflict(
    Player player,
    String requestedTeeId,
    DateTime date,
    TimeOfDay startTime,
    List<Reservation> existingReservations,
  ) {
    
    // Buscar reservas del jugador en la misma fecha y hora
    final playerReservations = existingReservations.where((reservation) =>
      reservation.date.year == date.year &&
      reservation.date.month == date.month &&
      reservation.date.day == date.day &&
      reservation.startTime.hour == startTime.hour &&
      reservation.startTime.minute == startTime.minute &&
      reservation.players.any((p) => p.email == player.email)
    ).toList();
    
    if (playerReservations.isEmpty) {
      return null; // No hay conflicto
    }
    
    // Verificar si ya tiene reserva en el otro tee a la misma hora
    for (final existingReservation in playerReservations) {
      final existingTeeId = existingReservation.courtId;
      
      // Si intenta reservar en un tee diferente al que ya tiene reservado
      if (existingTeeId != requestedTeeId && _isGolfTee(existingTeeId)) {
        final existingTeeName = _getTeeDisplayName(existingTeeId);
        final requestedTeeName = _getTeeDisplayName(requestedTeeId);
        
        return 'El jugador ${player.name} ya tiene una reserva a las '
               '${_formatTime(startTime)} en $existingTeeName. '
               'No puede tener reservas simultáneas en $requestedTeeName.';
      }
      
      // Si intenta reservar en el mismo tee (conflicto normal)
      if (existingTeeId == requestedTeeId) {
        final teeName = _getTeeDisplayName(existingTeeId);
        return 'El jugador ${player.name} ya tiene una reserva a las '
               '${_formatTime(startTime)} en $teeName.';
      }
    }
    
    return null;
  }
  
  // ✅ VERIFICAR SI ES TEE DE GOLF
  static bool _isGolfTee(String courtId) {
    return courtId == 'golf_tee_1' || courtId == 'golf_tee_10';
  }
  
  // ✅ OBTENER NOMBRE DISPLAY TEE
  static String _getTeeDisplayName(String teeId) {
    switch (teeId) {
      case 'golf_tee_1':
        return 'Hoyo 1';
      case 'golf_tee_10':
        return 'Hoyo 10';
      default:
        return 'Campo Golf';
    }
  }
  
  // ✅ FORMATEAR HORA
  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // ✅ OBTENER TODAS LAS RESERVAS GOLF DEL JUGADOR EN FECHA
  static List<Reservation> getPlayerGolfReservationsForDate(
    String playerEmail,
    DateTime date,
    List<Reservation> allReservations,
  ) {
    return allReservations.where((reservation) =>
      reservation.date.year == date.year &&
      reservation.date.month == date.month &&
      reservation.date.day == date.day &&
      _isGolfTee(reservation.courtId) &&
      reservation.players.any((p) => p.email == playerEmail)
    ).toList();
  }
  
  // ✅ VERIFICAR SI JUGADOR PUEDE RESERVAR EN FECHA/HORA
  static bool canPlayerBookAtDateTime(
    String playerEmail,
    DateTime date,
    TimeOfDay time,
    String requestedTeeId,
    List<Reservation> existingReservations,
  ) {
    final playerReservations = existingReservations.where((reservation) =>
      reservation.date.year == date.year &&
      reservation.date.month == date.month &&
      reservation.date.day == date.day &&
      reservation.startTime.hour == time.hour &&
      reservation.startTime.minute == time.minute &&
      reservation.players.any((p) => p.email == playerEmail)
    ).toList();
    
    // Si no tiene reservas a esa hora, puede reservar
    if (playerReservations.isEmpty) return true;
    
    // Si ya tiene reserva en cualquier tee golf a esa hora, no puede
    return !playerReservations.any((r) => _isGolfTee(r.courtId));
  }
}

// ✅ CLASE RESULTADO VALIDACIÓN
class ValidationResult {
  final bool isValid;
  final String? reason;
  
  ValidationResult({
    required this.isValid,
    this.reason,
  });
}

// ✅ EJEMPLOS DE USO:
/*
// Validar reserva Golf
final validation = GolfValidationService.validateGolfReservation(
  players: [Player(name: 'Miguel Lagos', email: 'miguel@gmail.com')],
  courtId: 'golf_tee_1',
  date: DateTime(2025, 8, 28),
  startTime: TimeOfDay(hour: 8, minute: 12),
  existingReservations: allReservations,
);

if (!validation.isValid) {
  // Mostrar toast con validation.reason
  _showConflictToast('Miguel Lagos', validation.reason!);
}

// Verificar si jugador puede reservar
final canBook = GolfValidationService.canPlayerBookAtDateTime(
  'miguel@gmail.com',
  DateTime(2025, 8, 28),
  TimeOfDay(hour: 8, minute: 12),
  'golf_tee_10',
  allReservations,
);
*/