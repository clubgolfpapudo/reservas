// lib/data/services/email_service.dart - URL CORREGIDA
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/booking.dart';
import '../../core/constants/app_constants.dart';

class EmailService {
  // ðŸ”¥ CORREGIDO: URL correcta segÃºn documentaciÃ³n
  static const String FUNCTIONS_URL = 
    'https://us-central1-cgpreservas.cloudfunctions.net/sendBookingEmailHTTP';
  
  static const Map<String, String> HEADERS = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static const Duration TIMEOUT = Duration(seconds: 30);
  
  /// EnvÃ­a emails de confirmaciÃ³n para una reserva
  static Future<bool> sendBookingConfirmation(Booking booking) async {
    try {
      // EMAIL-VERBOSE: print('ðŸ“§ INICIANDO ENVÃO DE EMAILS');
      // EMAIL-VERBOSE: print('ðŸ“§ URL: $FUNCTIONS_URL');
      // EMAIL-VERBOSE: print('ðŸ“§ Reserva: ${booking.courtId} ${booking.date} ${booking.timeSlot}');
      // EMAIL-VERBOSE: print('ðŸ“§ Jugadores: ${booking.players.length}');
      
      // Preparar datos para el endpoint
      final requestData = {
        'booking': {
          'courtId': booking.courtId,
          'date': booking.date,
          'timeSlot': booking.timeSlot,
          'players': booking.players.map((player) => {
            'name': player.name,
            'email': player.email ?? 'sin-email@cgp.cl',
            'isConfirmed': player.isConfirmed,
          }).toList(),
          'courtInfo': {
            'name': AppConstants.getCourtName(booking.courtId),
            'color': AppConstants.getCourtColor(AppConstants.getCourtName(booking.courtId)),
          }
        }
      };
      
      // EMAIL-VERBOSE: print('ðŸ“§ Request data: ${jsonEncode(requestData)}');
      
      // Realizar llamada HTTP
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(requestData),
      ).timeout(TIMEOUT);
      
      // EMAIL-VERBOSE: print('ðŸ“§ Response status: ${response.statusCode}');
      // EMAIL-VERBOSE: print('ðŸ“§ Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // EMAIL-VERBOSE: print('âœ… Emails enviados exitosamente');
          return true;
        } else {
          print('âŒ Error en respuesta: ${responseData['error']}');
          return false;
        }
      } else {
        print('âŒ HTTP Error ${response.statusCode}: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('âŒ Exception enviando emails: $e');
      return false;
    }
  }
  
  /// EnvÃ­a notificaciones de cancelaciÃ³n
  static Future<bool> sendCancellationNotification({
    required Booking booking,
    required BookingPlayer cancelingPlayer,
  }) async {
    try {
      // EMAIL-VERBOSE: print('ðŸ“§ ENVIANDO NOTIFICACIONES DE CANCELACIÃ“N');
      
      // Filtrar jugadores (excluir quien cancela)
      final otherPlayers = booking.players
          .where((p) => p.email != cancelingPlayer.email)
          .toList();
      
      if (otherPlayers.isEmpty) {
        // EMAIL-VERBOSE: print('ðŸ“§ No hay otros jugadores para notificar');
        return true;
      }
      
      final requestData = {
        'type': 'cancellation',
        'booking': {
          'courtId': booking.courtId,
          'date': booking.date,
          'timeSlot': booking.timeSlot,
          'players': otherPlayers.map((player) => {
            'name': player.name,
            'email': player.email ?? 'sin-email@cgp.cl',
            'isConfirmed': player.isConfirmed,
          }).toList(),
          'courtInfo': {
            'name': AppConstants.getCourtName(booking.courtId),
            'color': AppConstants.getCourtColor(AppConstants.getCourtName(booking.courtId)),
          }
        },
        'cancelingPlayer': {
          'name': cancelingPlayer.name,
          'email': cancelingPlayer.email ?? 'sin-email@cgp.cl',
        }
      };
      
      // EMAIL-VERBOSE: print('ðŸ“§ Cancellation request: ${jsonEncode(requestData)}');
      
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(requestData),
      ).timeout(TIMEOUT);
      
      // EMAIL-VERBOSE: print('ðŸ“§ Cancellation response: ${response.statusCode} ${response.body}');
      
      return response.statusCode == 200;
      
    } catch (e) {
      print('âŒ Error enviando notificaciones de cancelaciÃ³n: $e');
      return false;
    }
  }

  /// EnvÃ­a notificaciones a los jugadores cuando un admin agrega a un jugador
  static Future<bool> sendPlayerAddedNotification({
    required Booking updatedBooking,
  }) async {
    try {
      // EMAIL-VERBOSE: print('ðŸ“§ ENVIANDO NOTIFICACIÃ“N DE JUGADOR AGREGADO POR ADMIN');
      
      // Preparar los datos para el endpoint de la funciÃ³n de la nube
      // El 'type' serÃ¡ 'player_added' para que la Cloud Function lo maneje
      final requestData = {
        'type': 'player_added',
        'booking': {
          'courtId': updatedBooking.courtId,
          'date': updatedBooking.date,
          'timeSlot': updatedBooking.timeSlot,
          'players': updatedBooking.players.map((player) => {
            'name': player.name,
            'email': player.email ?? 'sin-email@cgp.cl',
            'isConfirmed': player.isConfirmed,
          }).toList(),
          'courtInfo': {
            'name': AppConstants.getCourtName(updatedBooking.courtId),
            'color': AppConstants.getCourtColor(AppConstants.getCourtName(updatedBooking.courtId)),
          }
        }
      };

      // EMAIL-VERBOSE: print('ðŸ“§ Player Added request: ${jsonEncode(requestData)}');
      
      // Realizar la llamada HTTP a la funciÃ³n de la nube
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(requestData),
      ).timeout(TIMEOUT);
      
      // EMAIL-VERBOSE: print('ðŸ“§ Player Added response: ${response.statusCode} ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('âŒ Error enviando notificaciones de modificaciÃ³n por admin: $e');
      return false;
    }
  }

  /// EnvÃ­a notificaciones a los jugadores cuando un admin remueve a un jugador
  static Future<bool> sendPlayerRemovedNotification({
    required Booking updatedBooking,
    required BookingPlayer removedPlayer,
  }) async {
    try {
      // EMAIL-VERBOSE: print('ðŸ“§ ENVIANDO NOTIFICACIÃ“N DE JUGADOR REMOVIDO POR ADMIN');
      
      final requestData = {
        'type': 'player_removed',
        'booking': {
          'courtId': updatedBooking.courtId,
          'date': updatedBooking.date,
          'timeSlot': updatedBooking.timeSlot,
          'players': [{
            'name': removedPlayer.name,
            'email': removedPlayer.email ?? 'sin-email@cgp.cl',
            'isConfirmed': removedPlayer.isConfirmed,
          }],
          'courtInfo': {
            'name': AppConstants.getCourtName(updatedBooking.courtId),
            'color': AppConstants.getCourtColor(AppConstants.getCourtName(updatedBooking.courtId)),
          }
        }
      };

      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(requestData),
      ).timeout(TIMEOUT);
      
      // EMAIL-VERBOSE: print('ðŸ“§ Player Removed response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('âŒ Error enviando notificaciÃ³n de jugador removido: $e');
      return false;
    }
  }

  /// Test del endpoint (para debugging)
  static Future<bool> testEndpoint() async {
    try {
      // EMAIL-VERBOSE: print('ðŸ§ª TESTING EMAIL ENDPOINT');
      
      final testData = {
        'test': true,
        'message': 'VerificaciÃ³n de conectividad desde Flutter'
      };
      
      final response = await http.post(
        Uri.parse(FUNCTIONS_URL),
        headers: HEADERS,
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 10));
      
      // EMAIL-VERBOSE: print('ðŸ§ª Test response: ${response.statusCode}');
      // EMAIL-VERBOSE: print('ðŸ§ª Test body: ${response.body}');
      
      return response.statusCode == 200;
      
    } catch (e) {
      print('âŒ Error en test: $e');
      return false;
    }
  }
}
