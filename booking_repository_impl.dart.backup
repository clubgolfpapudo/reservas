// lib/data/repositories/booking_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';
import '../../core/constants/app_constants.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseFirestore _firestore;
  final String _collection = FirebaseConstants.bookingsCollection;

  BookingRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONSULTA BÁSICA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener reserva: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsByDate(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.time')
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas por fecha: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsByDateAndCourt(DateTime date, String courtId) async {
    try {
      final dateStr = _formatDate(date);
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('courtId', isEqualTo: courtId)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.time')
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas por fecha y cancha: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsByUser(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('players', arrayContains: {'id': userId})
          .orderBy('dateTime.timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas por usuario: $e');
    }
  }

  @override
  Future<List<Booking>> getUserBookingsInDateRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      final query = await _firestore
          .collection(_collection)
          .where('players', arrayContains: {'id': userId})
          .where('dateTime.timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('dateTime.timestamp', isLessThanOrEqualTo: endTimestamp)
          .orderBy('dateTime.timestamp')
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas de usuario en rango: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsByStatus(BookingStatus status) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status.value)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas por estado: $e');
    }
  }

  @override
  Future<List<Booking>> getIncompleteBookings() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: BookingStatus.incomplete.value)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.timestamp')
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas incompletas: $e');
    }
  }

  @override
  Future<List<Booking>> getUpcomingBookings([int daysAhead = 7]) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.timestamp', isGreaterThanOrEqualTo: now.millisecondsSinceEpoch)
          .where('dateTime.timestamp', isLessThanOrEqualTo: futureDate.millisecondsSinceEpoch)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.timestamp')
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas próximas: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE DISPONIBILIDAD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isTimeSlotAvailable(DateTime date, String time, String courtId) async {
    try {
      final dateStr = _formatDate(date);
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('dateTime.time', isEqualTo: time)
          .where('courtId', isEqualTo: courtId)
          .where('visibleInCalendar', isEqualTo: true)
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }

  @override
  Future<List<String>> getAvailableTimeSlots(DateTime date, String courtId) async {
    try {
      final dateStr = _formatDate(date);
      
      // Obtener reservas existentes para esa fecha y cancha
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('courtId', isEqualTo: courtId)
          .where('visibleInCalendar', isEqualTo: true)
          .get();

      final bookedTimes = query.docs
          .map((doc) => doc.data()['dateTime']['time'] as String)
          .toSet();

      // Filtrar horarios disponibles
      final allTimes = AppConstants.getAllTimeSlots(date);
      return allTimes.where((time) => !bookedTimes.contains(time)).toList();
    } catch (e) {
      throw Exception('Error al obtener horarios disponibles: $e');
    }
  }

  @override
  Future<List<DateTime>> getAvailableDatesAhead([int daysAhead = 4]) async {
    try {
      final availableDates = <DateTime>[];
      final today = DateTime.now();
      
      for (int i = 0; i < daysAhead; i++) {
        final date = today.add(Duration(days: i));
        // Simplificado: agregar todas las fechas futuras
        // En implementación real, verificar disponibilidad por cancha
        availableDates.add(date);
      }
      
      return availableDates;
    } catch (e) {
      throw Exception('Error al obtener fechas disponibles: $e');
    }
  }

  @override
  Future<bool> canUserBookAtTime(String userId, DateTime date, String time) async {
    try {
      // Verificar si el usuario ya tiene una reserva en ese horario
      final conflicts = await getUserBookingConflicts(userId, date, time);
      return conflicts.isEmpty;
    } catch (e) {
      throw Exception('Error al verificar conflictos de usuario: $e');
    }
  }

  @override
  Future<List<Booking>> getUserBookingConflicts(
    String userId, 
    DateTime date, 
    String time
  ) async {
    try {
      final dateStr = _formatDate(date);
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('dateTime.time', isEqualTo: time)
          .where('players', arrayContains: {'id': userId, 'status': 'confirmed'})
          .where('visibleInCalendar', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al verificar conflictos: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MODIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<String> createBooking(Booking booking) async {
    try {
      final bookingModel = booking is BookingModel ? booking : BookingModel(
        id: booking.id,
        courtId: booking.courtId,
        court: booking.court,
        dateTime: booking.dateTime,
        players: booking.players,
        activePlayersCount: booking.activePlayersCount,
        status: booking.status,
        visibleInCalendar: booking.visibleInCalendar,
        calendlyUri: booking.calendlyUri,
        metadata: booking.metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(booking.id)
          .set(bookingModel.toFirestore());

      return booking.id;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    try {
      final bookingModel = booking is BookingModel ? booking : BookingModel(
        id: booking.id,
        courtId: booking.courtId,
        court: booking.court,
        dateTime: booking.dateTime,
        players: booking.players,
        activePlayersCount: booking.activePlayersCount,
        status: booking.status,
        visibleInCalendar: booking.visibleInCalendar,
        calendlyUri: booking.calendlyUri,
        metadata: booking.metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(booking.id)
          .update(bookingModel.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar reserva: $e');
    }
  }

  @override
  Future<void> addPlayerToBooking(String bookingId, Player player) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();
      if (!doc.exists) throw Exception('Reserva no encontrada');

      final booking = BookingModel.fromFirestore(doc);
      final updatedPlayers = List<Player>.from(booking.players)..add(player);
      
      await _firestore.collection(_collection).doc(bookingId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'activePlayersCount': updatedPlayers.where((p) => p.status == PlayerStatus.confirmed).length,
        'status': updatedPlayers.length == 4 ? BookingStatus.complete.value : BookingStatus.incomplete.value,
        'metadata.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar jugador: $e');
    }
  }

  @override
  Future<void> cancelPlayerFromBooking(String bookingId, String playerEmail) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();
      if (!doc.exists) throw Exception('Reserva no encontrada');

      final booking = BookingModel.fromFirestore(doc);
      final updatedPlayers = booking.players.map((player) {
        if (player.email == playerEmail) {
          return Player(
            id: player.id,
            name: player.name,
            email: player.email,
            isMainBooker: player.isMainBooker,
            status: PlayerStatus.cancelled,
            statusChangedAt: DateTime.now().millisecondsSinceEpoch,
            statusChangedBy: player.id ?? 'system',
          );
        }
        return player;
      }).toList();
      
      final activeCount = updatedPlayers.where((p) => p.status == PlayerStatus.confirmed).length;
      
      await _firestore.collection(_collection).doc(bookingId).update({
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'activePlayersCount': activeCount,
        'status': activeCount == 4 ? BookingStatus.complete.value : BookingStatus.incomplete.value,
        'metadata.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al cancelar jugador: $e');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String cancelledBy) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': BookingStatus.cancelled.value,
        'visibleInCalendar': false,
        'metadata.updatedAt': FieldValue.serverTimestamp(),
        'metadata.updatedBy': cancelledBy,
      });
    } catch (e) {
      throw Exception('Error al cancelar reserva: $e');
    }
  }

  @override
  Future<void> markBookingAsComplete(String bookingId) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': BookingStatus.complete.value,
        'metadata.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar reserva como completa: $e');
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'status': status.value,
        'metadata.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado de reserva: $e');
    }
  }

  @override
  Future<void> updateBookingCalendlyUri(String bookingId, String calendlyUri) async {
    try {
      await _firestore.collection(_collection).doc(bookingId).update({
        'calendlyUri': calendlyUri,
        'metadata.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar URI de Calendly: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN Y REGLAS DE NEGOCIO
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<String>> validateBooking(Booking booking) async {
    try {
      final List<String> errors = [];

      // Validar número de jugadores
      if (booking.players.length != AppConstants.requiredPlayersPerBooking) {
        errors.add('Se requieren exactamente ${AppConstants.requiredPlayersPerBooking} jugadores');
      }

      // Validar disponibilidad de horario
      final isAvailable = await isTimeSlotAvailable(
        DateTime.parse(booking.dateTime.date),
        booking.dateTime.time,
        booking.courtId,
      );
      if (!isAvailable) {
        errors.add('El horario no está disponible');
      }

      // Validar duplicados de email
      final emails = booking.players.map((p) => p.email).toList();
      final uniqueEmails = emails.toSet();
      if (emails.length != uniqueEmails.length) {
        errors.add('No se permiten jugadores duplicados');
      }

      return errors;
    } catch (e) {
      throw Exception('Error al validar reserva: $e');
    }
  }

  @override
  Future<bool> checkUserBookingRestrictions(String userId, DateTime date, String time) async {
    try {
      // Verificar límite diario
      final exceedsLimit = await userExceedsDailyLimit(userId, date);
      if (exceedsLimit) return false;

      // Verificar conflictos de horario
      final canBook = await canUserBookAtTime(userId, date, time);
      return canBook;
    } catch (e) {
      throw Exception('Error al verificar restricciones: $e');
    }
  }

  @override
  Future<int> getUserBookingCountForDate(String userId, DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('players', arrayContains: {'id': userId, 'status': 'confirmed'})
          .where('visibleInCalendar', isEqualTo: true)
          .get();

      return query.docs.length;
    } catch (e) {
      throw Exception('Error al contar reservas de usuario: $e');
    }
  }

  @override
  Future<bool> userExceedsDailyLimit(String userId, DateTime date) async {
    try {
      final count = await getUserBookingCountForDate(userId, date);
      return count >= AppConstants.maxBookingsPerUserPerDay;
    } catch (e) {
      throw Exception('Error al verificar límite diario: $e');
    }
  }

  @override
  Future<List<String>> getDuplicatePlayersInTimeSlot(
    DateTime date, 
    String time, 
    List<String> playerEmails
  ) async {
    try {
      final dateStr = _formatDate(date);
      final duplicates = <String>[];
      
      // Obtener reservas existentes en ese horario
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.date', isEqualTo: dateStr)
          .where('dateTime.time', isEqualTo: time)
          .where('visibleInCalendar', isEqualTo: true)
          .get();

      final existingEmails = <String>{};
      for (final doc in query.docs) {
        final booking = BookingModel.fromFirestore(doc);
        existingEmails.addAll(
          booking.players
              .where((p) => p.status == PlayerStatus.confirmed)
              .map((p) => p.email)
        );
      }

      // Verificar duplicados
      for (final email in playerEmails) {
        if (existingEmails.contains(email) && !AppConstants.isExemptEmail(email)) {
          duplicates.add(email);
        }
      }

      return duplicates;
    } catch (e) {
      throw Exception('Error al verificar jugadores duplicados: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE BÚSQUEDA Y FILTRADO
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<Booking>> searchBookingsByPlayerName(String playerName) async {
    try {
      final searchUpper = playerName.toUpperCase();
      
      // Firestore no permite búsquedas complejas en arrays, necesitamos obtener todos y filtrar
      final query = await _firestore
          .collection(_collection)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .where((booking) => booking.players
              .any((player) => player.name.toUpperCase().contains(searchUpper)))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar por nombre de jugador: $e');
    }
  }

  @override
  Future<List<Booking>> searchBookingsByPlayerEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('players', arrayContains: {'email': email.toLowerCase()})
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar por email de jugador: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsInDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final startTimestamp = startDate.millisecondsSinceEpoch;
      final endTimestamp = endDate.millisecondsSinceEpoch;
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('dateTime.timestamp', isLessThanOrEqualTo: endTimestamp)
          .where('visibleInCalendar', isEqualTo: true)
          .orderBy('dateTime.timestamp')
          .get();

      return query.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reservas en rango: $e');
    }
  }

  @override
  Future<List<Booking>> getFilteredBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? courtId,
    BookingStatus? status,
    String? playerEmail,
    bool? visibleInCalendar,
  }) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (startDate != null) {
        query = query.where('dateTime.timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        query = query.where('dateTime.timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      }
      
      if (courtId != null) {
        query = query.where('courtId', isEqualTo: courtId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }
      
      if (playerEmail != null) {
        query = query.where('players', arrayContains: {'email': playerEmail.toLowerCase()});
      }
      
      if (visibleInCalendar != null) {
        query = query.where('visibleInCalendar', isEqualTo: visibleInCalendar);
      }
      
      query = query.orderBy('dateTime.timestamp', descending: true);
      
      final result = await query.get();
      return result.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al filtrar reservas: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, int>> getBookingStatsByDate(DateTime date) async {
    try {
      final bookings = await getBookingsByDate(date);
      
      return {
        'total': bookings.length,
        'complete': bookings.where((b) => b.status == BookingStatus.complete).length,
        'incomplete': bookings.where((b) => b.status == BookingStatus.incomplete).length,
        'cancelled': bookings.where((b) => b.status == BookingStatus.cancelled).length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas por fecha: $e');
    }
  }

  @override
  Future<Map<String, int>> getCourtUsageStats(DateTime startDate, DateTime endDate) async {
    try {
      final bookings = await getBookingsInDateRange(startDate, endDate);
      final Map<String, int> usage = {};
      
      for (final booking in bookings) {
        final courtName = AppConstants.courtNames[booking.court - 1];
        usage[courtName] = (usage[courtName] ?? 0) + 1;
      }
      
      return usage;
    } catch (e) {
      throw Exception('Error al obtener estadísticas de uso: $e');
    }
  }

  @override
  Future<Map<String, int>> getPopularTimeSlots(DateTime startDate, DateTime endDate) async {
    try {
      final bookings = await getBookingsInDateRange(startDate, endDate);
      final Map<String, int> popularity = {};
      
      for (final booking in bookings) {
        final time = booking.dateTime.time;
        popularity[time] = (popularity[time] ?? 0) + 1;
      }
      
      return popularity;
    } catch (e) {
      throw Exception('Error al obtener horarios populares: $e');
    }
  }

  @override
  Future<double> getCancellationRate(DateTime startDate, DateTime endDate) async {
    try {
      final bookings = await getBookingsInDateRange(startDate, endDate);
      if (bookings.isEmpty) return 0.0;
      
      final cancelled = bookings.where((b) => b.status == BookingStatus.cancelled).length;
      return (cancelled / bookings.length) * 100;
    } catch (e) {
      throw Exception('Error al calcular tasa de cancelación: $e');
    }
  }

  @override
  Future<double> getRevenueForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final bookings = await getBookingsInDateRange(startDate, endDate);
      double revenue = 0.0;
      
      for (final booking in bookings) {
        for (final player in booking.players) {
          if (player.status == PlayerStatus.confirmed) {
            // Aquí necesitaríamos obtener el rol del usuario para calcular la tarifa
            // Por simplicidad, usamos una tarifa promedio
            revenue += 10000.0; // Tarifa promedio
          }
        }
      }
      
      return revenue;
    } catch (e) {
      throw Exception('Error al calcular ingresos: $e');
    }
  }

  @override
  Future<Map<String, int>> getBookingsByUserCategory(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final bookings = await getBookingsInDateRange(startDate, endDate);
      final Map<String, int> categories = {};
      
      // Esto requeriría acceso a UserRepository para obtener roles
      // Por ahora retornamos estructura vacía
      return categories;
    } catch (e) {
      throw Exception('Error al obtener reservas por categoría: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE STREAM (TIEMPO REAL)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Booking?> watchBooking(String bookingId) {
    return _firestore
        .collection(_collection)
        .doc(bookingId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return BookingModel.fromFirestore(doc);
          }
          return null;
        });
  }

  @override
  Stream<List<Booking>> watchBookingsByDate(DateTime date) {
    final dateStr = _formatDate(date);
    
    return _firestore
        .collection(_collection)
        .where('dateTime.date', isEqualTo: dateStr)
        .where('visibleInCalendar', isEqualTo: true)
        .orderBy('dateTime.time')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<Booking>> watchBookingsByDateAndCourt(DateTime date, String courtId) {
    final dateStr = _formatDate(date);
    
    return _firestore
        .collection(_collection)
        .where('dateTime.date', isEqualTo: dateStr)
        .where('courtId', isEqualTo: courtId)
        .where('visibleInCalendar', isEqualTo: true)
        .orderBy('dateTime.time')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<Booking>> watchUserBookings(String userId) {
    return _firestore
        .collection(_collection)
        .where('players', arrayContains: {'id': userId})
        .orderBy('dateTime.timestamp', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<Booking>> watchUpcomingBookings([int daysAhead = 7]) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));
    
    return _firestore
        .collection(_collection)
        .where('dateTime.timestamp', isGreaterThanOrEqualTo: now.millisecondsSinceEpoch)
        .where('dateTime.timestamp', isLessThanOrEqualTo: futureDate.millisecondsSinceEpoch)
        .where('visibleInCalendar', isEqualTo: true)
        .orderBy('dateTime.timestamp')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<Booking>> watchIncompleteBookings() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: BookingStatus.incomplete.value)
        .where('visibleInCalendar', isEqualTo: true)
        .orderBy('dateTime.timestamp')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE LIMPIEZA Y MANTENIMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> deleteOldBookings([int daysOld = 365]) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.timestamp', isLessThan: cutoffDate.millisecondsSinceEpoch)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Error al eliminar reservas antiguas: $e');
    }
  }

  @override
  Future<void> markNoShowBookings() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.timestamp', isLessThan: yesterday.millisecondsSinceEpoch)
          .where('status', isEqualTo: BookingStatus.complete.value)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        // Lógica para marcar como no-show basada en confirmaciones
        // Por ahora solo actualizamos metadatos
        batch.update(doc.reference, {
          'metadata.updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Error al marcar no-shows: $e');
    }
  }

  @override
  Future<void> updateExpiredBookings() async {
    try {
      final now = DateTime.now();
      
      final query = await _firestore
          .collection(_collection)
          .where('dateTime.timestamp', isLessThan: now.millisecondsSinceEpoch)
          .where('status', whereIn: [BookingStatus.complete.value, BookingStatus.incomplete.value])
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'metadata.updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Error al actualizar reservas expiradas: $e');
    }
  }

  @override
  Future<void> syncWithExternalSystem() async {
    try {
      // Implementar sincronización con GAS/Calendly
      // Por ahora es un placeholder
      print('Sincronizando con sistema externo...');
    } catch (e) {
      throw Exception('Error al sincronizar con sistema externo: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS AUXILIARES
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}