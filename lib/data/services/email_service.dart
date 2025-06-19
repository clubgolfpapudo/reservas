// lib/data/services/email_service.dart - URL CORREGIDA
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/booking.dart';
import '../../core/constants/app_constants.dart';

class EmailService {
  // 🔥 CORREGIDO: URL correcta según documentación
  static const String FUNCTIONS_URL = 
    'https://us-central1-cgpreservas.cloudfunctions.net/sendBookingEmailHTTP';
  
  static const Map<String, String> HEADERS = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static const Duration TIMEOUT = Duration(seconds: 30);
  
  /// Envía emails de confirmación para una reserva
  static Future<bool> sendBookingConfirmation(Booking booking) async {
    try {
      print('📧 INICIANDO ENVÍO DE EMAILS');
      print('📧 URL: $FUNCTIONS_URL');
      print('📧 Reserva: ${booking.courtNumber} ${booking.date} ${booking.timeSlot}');
      print('📧 Jugadores: ${booking.players.length}');
      
      // Preparar datos para el endpoint
      final requestData = {
        'booking': {
          'courtNumber': booking.courtNumber,
          'date': booking.date,
          'timeSlot': booking.timeSlot,
          'players': booking.players.map((player) => {
            'name': player.name,
            'email': player.email ?? 'sin-email@cgp.cl',
            'isConfirmed': player.isConfirmed,
          }).toList(),
          'courtInfo': {
            'name': AppConstants.getCourtName(booking.courtNumber),
            'color': AppConstants.getCourtColor(AppConstants.getCourtName(booking.courtNumber)),
          }
        }
      };
      
      print('📧 Request data: ${jsonEncode(requestData)}');
      
      // Realizar llamada HTTP
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(requestData),
      ).timeout(TIMEOUT);
      
      print('📧 Response status: ${response.statusCode}');
      print('📧 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          print('✅ Emails enviados exitosamente');
          return true;
        } else {
          print('❌ Error en respuesta: ${responseData['error']}');
          return false;
        }
      } else {
        print('❌ HTTP Error ${response.statusCode}: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ Exception enviando emails: $e');
      return false;
    }
  }
  
  /// Envía notificaciones de cancelación
  static Future<bool> sendCancellationNotification({
    required Booking booking,
    required BookingPlayer cancelingPlayer,
  }) async {
    try {
      print('📧 ENVIANDO NOTIFICACIONES DE CANCELACIÓN');
      
      // Filtrar jugadores (excluir quien cancela)
      final otherPlayers = booking.players
          .where((p) => p.email != cancelingPlayer.email)
          .toList();
      
      if (otherPlayers.isEmpty) {
        print('📧 No hay otros jugadores para notificar');
        return true;
      }
      
      final requestData = {
        'type': 'cancellation',
        'booking': {
          'courtNumber': booking.courtNumber,
          'date': booking.date,
          'timeSlot': booking.timeSlot,
          'players': otherPlayers.map((player) => {
            'name': player.name,
            'email': player.email ?? 'sin-email@cgp.cl',
            'isConfirmed': player.isConfirmed,
          }).toList(),
          'courtInfo': {
            'name': AppConstants.getCourtName(booking.courtNumber),
            'color': AppConstants.getCourtColor(AppConstants.getCourtName(booking.courtNumber)),
          }
        },
        'cancelingPlayer': {
          'name': cancelingPlayer.name,
          'email': cancelingPlayer.email ?? 'sin-email@cgp.cl',
        }
      };
      
      print('📧 Cancellation request: ${jsonEncode(requestData)}');
      
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(requestData),
      ).timeout(TIMEOUT);
      
      print('📧 Cancellation response: ${response.statusCode} ${response.body}');
      
      return response.statusCode == 200;
      
    } catch (e) {
      print('❌ Error enviando notificaciones de cancelación: $e');
      return false;
    }
  }
  
  /// Test del endpoint (para debugging)
  static Future<bool> testEndpoint() async {
    try {
      print('🧪 TESTING EMAIL ENDPOINT');
      
      final testData = {
        'test': true,
        'message': 'Verificación de conectividad desde Flutter'
      };
      
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 10));
      
      print('🧪 Test response: ${response.statusCode}');
      print('🧪 Test body: ${response.body}');
      
      return response.statusCode == 200;
      
    } catch (e) {
      print('❌ Error en test: $e');
      return false;
    }
  }
}