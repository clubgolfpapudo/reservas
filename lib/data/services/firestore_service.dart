// ============================================================================
// ARCHIVO 4: lib/data/services/firestore_service.dart
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
}