// ============================================================================
// lib/data/services/firestore_service.dart - COMPLETO
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';
import '../models/booking_model.dart';
import '../models/court_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  // ============================================================================
  // COURTS
  // ============================================================================
 
  static Stream<List<Court>> getCourts() {
    return _firestore
        .collection('courts')
        .orderBy('number')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourtModel.fromFirestore(doc.data(), doc.id).toEntity())
            .toList());
  }
 
  // ============================================================================
  // BOOKINGS
  // ============================================================================
 
  static Stream<List<Booking>> getBookingsByDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
   
    return _firestore
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc.data(), doc.id).toEntity())
              .where((booking) => booking.date == dateStr)
              .toList();
          
          print('🔍 Total documentos en BD: ${snapshot.docs.length}');
          print('🔍 Reservas filtradas para $dateStr: ${bookings.length}');
          
          return bookings;
        });
  }
 
  static Future<String> createBooking(Booking booking) async {
    try {
      final bookingModel = BookingModel.fromEntity(booking);
      final docRef = await _firestore
          .collection('bookings')
          .add(bookingModel.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creando reserva: $e');
    }
  }

  // ============================================================================
  // MÉTODOS ADICIONALES PARA SISTEMA DE EMAILS
  // ============================================================================

  /// Obtener una reserva específica por ID
  static Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists && doc.data() != null) {
        return BookingModel.fromFirestore(doc.data()!, doc.id).toEntity();
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo reserva: $e');
      return null;
    }
  }

  /// Actualiza una reserva existente en Firestore
  static Future<void> updateBooking(Booking booking) async {
    try {
      if (booking.id == null) {
        throw Exception('El ID de la reserva es nulo. No se puede actualizar.');
      }
     
    // Obtiene el mapa de datos de la reserva y elimina el ID
    final dataToUpdate = booking.toFirestore();
    dataToUpdate.remove('id'); 
     
    await _firestore.collection('bookings').doc(booking.id).update(dataToUpdate);
     
    print('✅ Reserva actualizada: ${booking.id}');
    } catch (e) {
      throw Exception('Error actualizando reserva: $e');
    }
  }

  /// Actualiza solo la lista de jugadores de una reserva en Firestore
  static Future<void> updateBookingPlayers(String bookingId, List<BookingPlayer> players) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'players': players.map((p) => p.toFirestore()).toList(),
      });
      print('✅ Jugadores de la reserva $bookingId actualizados.');
    } catch (e) {
      throw Exception('Error al actualizar la lista de jugadores: $e');
    }
  }

  /// Eliminar una reserva por ID
  static Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      print('✅ Reserva eliminada: $bookingId');
    } catch (e) {
      print('❌ Error eliminando reserva: $e');
      throw Exception('Error eliminando reserva: $e');
    }
  }

  Future<List<Booking>> getUserBookingsForDate(String userEmail, String date) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('date', isEqualTo: date)
          .get();
      
      final userBookings = <Booking>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final booking = Booking(
          id: doc.id,
          courtId: data['courtId'] ?? '',
          date: data['date'] ?? '',
          timeSlot: data['timeSlot'] ?? '',
          players: (data['players'] as List<dynamic>?)
              ?.map((playerData) => BookingPlayer.fromMap(playerData))
              .toList() ?? [],
          status: data['status'] != null ? BookingStatus.values.firstWhere(
            (status) => status.toString() == 'BookingStatus.${data['status']}',
            orElse: () => BookingStatus.complete,
          ) : null,
          createdAt: data['createdAt']?.toDate(),
          updatedAt: data['updatedAt']?.toDate(),
        );
                
        // Verificar si el usuario está en la reserva (como organizador o jugador)
        final isUserInBooking = booking.players.any((player) => 
          (player.email?.toLowerCase() ?? '') == userEmail.toLowerCase()
        );
        
        if (isUserInBooking) {
          userBookings.add(booking);
        }
      }
      
      return userBookings;
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }
}