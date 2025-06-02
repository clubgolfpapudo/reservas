// ============================================================================
// lib/data/services/email_service.dart - URLs ACTUALIZADAS
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/booking.dart';
import 'ics_generator.dart';

class EmailService {
  // 🔥 NUEVAS URLs de Firebase Functions v2
  static const String _sendBookingUrl = 'https://sendbookingemail-65wy6ova5a-uc.a.run.app';
  static const String _sendCancellationUrl = 'https://sendcancellationemail-65wy6ova5a-uc.a.run.app';
  
  // ============================================================================
  // ENVÍO DE CONFIRMACIÓN A TODOS LOS JUGADORES
  // ============================================================================
  
  static Future<bool> sendBookingConfirmation(Booking booking) async {
    try {
      print('📧 Enviando confirmaciones para reserva: ${booking.id}');
      
      // Generar archivo .ics
      final icsContent = IcsGenerator.generateBookingIcs(booking);
      
      // Enviar email personalizado a cada jugador
      final results = <Future<bool>>[];
      
      for (int i = 0; i < booking.players.length; i++) {
        final player = booking.players[i];
        final isOrganizer = i == 0; // Primer jugador es organizador
        
        results.add(_sendPersonalizedEmail(
          booking: booking,
          player: player,
          isOrganizer: isOrganizer,
          icsContent: icsContent,
        ));
      }
      
      // Esperar que todos los emails se envíen
      final emailResults = await Future.wait(results);
      final allSuccess = emailResults.every((success) => success);
      
      if (allSuccess) {
        print('✅ Todos los emails enviados exitosamente');
      } else {
        print('⚠️ Algunos emails fallaron');
      }
      
      return allSuccess;
    } catch (e) {
      print('❌ Error enviando confirmaciones: $e');
      return false;
    }
  }
  
  // ============================================================================
  // EMAIL PERSONALIZADO POR JUGADOR
  // ============================================================================
  
  static Future<bool> _sendPersonalizedEmail({
    required Booking booking,
    required BookingPlayer player,
    required bool isOrganizer,
    required String icsContent,
  }) async {
    try {
      final emailData = {
        'to': player.email,
        'playerName': player.name,
        'isOrganizer': isOrganizer,
        'booking': {
          'id': booking.id,
          'date': booking.date,
          'timeSlot': booking.timeSlot,
          'courtNumber': booking.courtNumber,
          'players': booking.players.map((p) => {
            'name': p.name,
            'email': p.email,
          }).toList(),
        },
        'icsContent': icsContent,
      };
      
      final response = await http.post(
        Uri.parse(_sendBookingUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );
      
      if (response.statusCode == 200) {
        print('✅ Email enviado a ${player.name} (${player.email})');
        return true;
      } else {
        print('❌ Error enviando email a ${player.name}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error enviando email a ${player.name}: $e');
      return false;
    }
  }
  
  // ============================================================================
  // CANCELACIÓN DE RESERVA
  // ============================================================================
  
  static Future<bool> sendCancellationNotification({
    required Booking booking,
    required BookingPlayer cancelingPlayer,
  }) async {
    try {
      print('📧 Enviando notificaciones de cancelación...');
      
      // Enviar notificación a todos EXCEPTO al que canceló
      final otherPlayers = booking.players
          .where((player) => player.email != cancelingPlayer.email)
          .toList();
      
      final results = <Future<bool>>[];
      
      for (final player in otherPlayers) {
        results.add(_sendCancellationEmail(
          booking: booking,
          notifyPlayer: player,
          cancelingPlayer: cancelingPlayer,
        ));
      }
      
      final emailResults = await Future.wait(results);
      final allSuccess = emailResults.every((success) => success);
      
      return allSuccess;
    } catch (e) {
      print('❌ Error enviando cancelaciones: $e');
      return false;
    }
  }
  
  static Future<bool> _sendCancellationEmail({
    required Booking booking,
    required BookingPlayer notifyPlayer,
    required BookingPlayer cancelingPlayer,
  }) async {
    try {
      final emailData = {
        'to': notifyPlayer.email,
        'playerName': notifyPlayer.name,
        'cancelingPlayerName': cancelingPlayer.name,
        'booking': {
          'id': booking.id,
          'date': booking.date,
          'timeSlot': booking.timeSlot,
          'courtNumber': booking.courtNumber,
        },
      };
      
      final response = await http.post(
        Uri.parse(_sendCancellationUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error enviando cancelación a ${notifyPlayer.name}: $e');
      return false;
    }
  }
}