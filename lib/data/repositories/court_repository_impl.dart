// lib/data/repositories/court_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/court_repository.dart';
import '../models/court_model.dart';
import '../../core/constants/app_constants.dart';
import '../models/court_model.dart';
import '../../core/theme/app_theme.dart';

class CourtRepositoryImpl implements CourtRepository {
  final FirebaseFirestore _firestore;
  final String _collection = FirebaseConstants.courtsCollection;

  CourtRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONSULTA BÁSICA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Court?> getCourtById(String courtId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(courtId).get();
      if (doc.exists) {
        return CourtModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener cancha por ID: $e');
    }
  }

  @override
  Future<Court?> getCourtByNumber(int courtNumber) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('number', isEqualTo: courtNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return CourtModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener cancha por número: $e');
    }
  }

  @override
  Future<Court?> getCourtByName(String courtName) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: courtName.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return CourtModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener cancha por nombre: $e');
    }
  }

  @override
  Future<List<Court>> getAllCourts() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .orderBy('displayOrder')
          .get();

      return query.docs
          .map((doc) => CourtModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener todas las canchas: $e');
    }
  }

  @override
  Future<List<Court>> getActiveCourts() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: CourtStatus.active.value)
          .where('isAvailableForBooking', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return query.docs
          .map((doc) => CourtModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener canchas activas: $e');
    }
  }

  @override
  Future<List<Court>> getCourtsByStatus(CourtStatus status) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status.value)
          .orderBy('displayOrder')
          .get();

      return query.docs
          .map((doc) => CourtModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener canchas por estado: $e');
    }
  }

  @override
  Future<List<Court>> getCourtsOrderedForDisplay() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('status', whereIn: [CourtStatus.active.value, CourtStatus.maintenance.value])
          .orderBy('displayOrder')
          .get();

      return query.docs
          .map((doc) => CourtModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener canchas ordenadas: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE DISPONIBILIDAD Y HORARIOS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<String>> getAvailableTimeSlotsForCourt(String courtId, DateTime date) async {
    try {
      final court = await getCourtById(courtId);
      if (court == null) return [];

      // Verificar si la cancha está cerrada ese día
      if (await isCourtClosedOnDate(courtId, date)) {
        return [];
      }

      // Verificar excepciones específicas para esa fecha
      final exceptions = await getCourtExceptionsForDate(courtId, date);
      if (exceptions.isNotEmpty) {
        final exception = exceptions.first;
        if (exception.isFullyClosed) {
          return [];
        }
        return exception.availableTimeSlots;
      }

      // Usar horarios personalizados si existen
      if (court.customTimeSlots != null && court.customTimeSlots!.isNotEmpty) {
        return court.customTimeSlots!;
      }

      // Usar horarios estándar
      return AppConstants.allTimeSlots;
    } catch (e) {
      throw Exception('Error al obtener horarios disponibles: $e');
    }
  }

  @override
  Future<bool> isCourtAvailableForBooking(String courtId) async {
    try {
      final court = await getCourtById(courtId);
      return court?.isAvailableForBooking ?? false;
    } catch (e) {
      throw Exception('Error al verificar disponibilidad de cancha: $e');
    }
  }

  @override
  Future<bool> hasCourtExceptions(String courtId, DateTime date) async {
    try {
      final exceptions = await getCourtExceptionsForDate(courtId, date);
      return exceptions.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar excepciones: $e');
    }
  }

  @override
  Future<List<CourtException>> getCourtExceptionsForDate(String courtId, DateTime date) async {
    try {
      final court = await getCourtById(courtId);
      if (court == null) return [];

      final dateStr = _formatDate(date);
      return court.exceptions
          .where((exception) => exception.date == dateStr)
          .toList();
    } catch (e) {
      throw Exception('Error al obtener excepciones de cancha: $e');
    }
  }

  @override
  Future<List<String>?> getCourtCustomTimeSlots(String courtId) async {
    try {
      final court = await getCourtById(courtId);
      return court?.customTimeSlots;
    } catch (e) {
      throw Exception('Error al obtener horarios personalizados: $e');
    }
  }

  @override
  Future<bool> isCourtClosedOnDate(String courtId, DateTime date) async {
    try {
      final exceptions = await getCourtExceptionsForDate(courtId, date);
      return exceptions.any((exception) => exception.isFullyClosed);
    } catch (e) {
      throw Exception('Error al verificar si cancha está cerrada: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MODIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> createCourt(Court court) async {
    try {
      final courtModel = court is CourtModel ? court : CourtModel(
        id: court.id,
        number: court.number,
        name: court.name,
        description: court.description,
        status: court.status,
        isAvailableForBooking: court.isAvailableForBooking,
        seasonId: court.seasonId,
        customTimeSlots: court.customTimeSlots,
        exceptions: court.exceptions,
        bookingDurationMinutes: court.bookingDurationMinutes,
        requiredPlayers: court.requiredPlayers,
        displayOrder: court.displayOrder,
        color: court.color,
        metadata: court.metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(court.id)
          .set(courtModel.toFirestore());
    } catch (e) {
      throw Exception('Error al crear cancha: $e');
    }
  }

  @override
  Future<void> updateCourt(Court court) async {
    try {
      final courtModel = court is CourtModel ? court : CourtModel(
        id: court.id,
        number: court.number,
        name: court.name,
        description: court.description,
        status: court.status,
        isAvailableForBooking: court.isAvailableForBooking,
        seasonId: court.seasonId,
        customTimeSlots: court.customTimeSlots,
        exceptions: court.exceptions,
        bookingDurationMinutes: court.bookingDurationMinutes,
        requiredPlayers: court.requiredPlayers,
        displayOrder: court.displayOrder,
        color: court.color,
        metadata: court.metadata,
      );

      await _firestore
          .collection(_collection)
          .doc(court.id)
          .update(courtModel.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar cancha: $e');
    }
  }

  @override
  Future<void> updateCourtStatus(String courtId, CourtStatus status) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'status': status.value,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar estado de cancha: $e');
    }
  }

  @override
  Future<void> updateCourtAvailability(String courtId, bool isAvailable) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'isAvailableForBooking': isAvailable,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar disponibilidad: $e');
    }
  }

  @override
  Future<void> addCourtException(String courtId, CourtException exception) async {
    try {
      final court = await getCourtById(courtId);
      if (court == null) throw Exception('Cancha no encontrada');

      final updatedExceptions = List<CourtException>.from(court.exceptions)
        ..add(exception);

      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'exceptions': updatedExceptions.map((e) => e.toMap()).toList(),
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al agregar excepción: $e');
    }
  }

  @override
  Future<void> removeCourtException(String courtId, String exceptionDate) async {
    try {
      final court = await getCourtById(courtId);
      if (court == null) throw Exception('Cancha no encontrada');

      final updatedExceptions = court.exceptions
          .where((exception) => exception.date != exceptionDate)
          .toList();

      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'exceptions': updatedExceptions.map((e) => e.toMap()).toList(),
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al eliminar excepción: $e');
    }
  }

  @override
  Future<void> updateCourtCustomTimeSlots(String courtId, List<String>? timeSlots) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'customTimeSlots': timeSlots,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar horarios personalizados: $e');
    }
  }

  @override
  Future<void> updateDisplayOrder(String courtId, int newOrder) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'displayOrder': newOrder,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar orden de visualización: $e');
    }
  }

  @override
  Future<void> deleteCourt(String courtId) async {
    try {
      // Soft delete - cambiar estado a inactivo
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'status': CourtStatus.inactive.value,
            'isAvailableForBooking': false,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al eliminar cancha: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<bool> isCourtNameInUse(String courtName, [String? excludeCourtId]) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('name', isEqualTo: courtName.toUpperCase());

      if (excludeCourtId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeCourtId);
      }

      final result = await query.limit(1).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar nombre de cancha: $e');
    }
  }

  @override
  Future<bool> isCourtNumberInUse(int courtNumber, [String? excludeCourtId]) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('number', isEqualTo: courtNumber);

      if (excludeCourtId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeCourtId);
      }

      final result = await query.limit(1).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar número de cancha: $e');
    }
  }

  @override
  Future<bool> canCourtBeDeleted(String courtId) async {
    try {
      // Verificar si hay reservas futuras para esta cancha
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      final bookingsQuery = await _firestore
          .collection(FirebaseConstants.bookingsCollection)
          .where('courtId', isEqualTo: courtId)
          .where('dateTime.timestamp', isGreaterThanOrEqualTo: tomorrow.millisecondsSinceEpoch)
          .where('visibleInCalendar', isEqualTo: true)
          .limit(1)
          .get();

      return bookingsQuery.docs.isEmpty;
    } catch (e) {
      throw Exception('Error al verificar si cancha puede eliminarse: $e');
    }
  }

  @override
  Future<List<String>> getCourtDeletionConflicts(String courtId) async {
    try {
      final conflicts = <String>[];
      
      // Verificar reservas futuras
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      final bookingsQuery = await _firestore
          .collection(FirebaseConstants.bookingsCollection)
          .where('courtId', isEqualTo: courtId)
          .where('dateTime.timestamp', isGreaterThanOrEqualTo: tomorrow.millisecondsSinceEpoch)
          .where('visibleInCalendar', isEqualTo: true)
          .get();

      if (bookingsQuery.docs.isNotEmpty) {
        conflicts.add('Tiene ${bookingsQuery.docs.length} reservas futuras');
      }

      return conflicts;
    } catch (e) {
      throw Exception('Error al obtener conflictos de eliminación: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MANTENIMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> scheduleCourtMaintenance(
    String courtId, 
    DateTime startDate, 
    DateTime endDate, 
    String reason
  ) async {
    try {
      final exception = CourtException(
        date: _formatDate(startDate),
        reason: reason,
        availableTimeSlots: [],
        isFullyClosed: true,
      );

      await addCourtException(courtId, exception);
      
      // Si el mantenimiento es hoy, cambiar estado
      if (startDate.isAtSameMomentAs(DateTime.now()) ||
          startDate.isBefore(DateTime.now())) {
        await updateCourtStatus(courtId, CourtStatus.maintenance);
      }
    } catch (e) {
      throw Exception('Error al programar mantenimiento: $e');
    }
  }

  @override
  Future<void> setCourtInMaintenance(String courtId, String reason) async {
    try {
      await updateCourtStatus(courtId, CourtStatus.maintenance);
      
      // Agregar excepción para hoy
      final today = DateTime.now();
      final exception = CourtException(
        date: _formatDate(today),
        reason: reason,
        availableTimeSlots: [],
        isFullyClosed: true,
      );
      
      await addCourtException(courtId, exception);
    } catch (e) {
      throw Exception('Error al marcar cancha en mantenimiento: $e');
    }
  }

  @override
  Future<void> reactivateCourtFromMaintenance(String courtId) async {
    try {
      await updateCourtStatus(courtId, CourtStatus.active);
      await updateCourtAvailability(courtId, true);
      
      // Eliminar excepción de hoy si existe
      final today = _formatDate(DateTime.now());
      await removeCourtException(courtId, today);
    } catch (e) {
      throw Exception('Error al reactivar cancha: $e');
    }
  }

  @override
  Future<List<Court>> getCourtsInMaintenance() async {
    try {
      return await getCourtsByStatus(CourtStatus.maintenance);
    } catch (e) {
      throw Exception('Error al obtener canchas en mantenimiento: $e');
    }
  }

  @override
  Future<List<CourtException>> getCourtMaintenanceHistory(String courtId) async {
    try {
      final court = await getCourtById(courtId);
      if (court == null) return [];

      return court.exceptions
          .where((exception) => exception.reason.toLowerCase().contains('mantenimiento'))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial de mantenimiento: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getCourtUsageStats(
    String courtId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final bookingsQuery = await _firestore
          .collection(FirebaseConstants.bookingsCollection)
          .where('courtId', isEqualTo: courtId)
          .where('dateTime.timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('dateTime.timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .where('visibleInCalendar', isEqualTo: true)
          .get();

      final totalBookings = bookingsQuery.docs.length;
      final completeBookings = bookingsQuery.docs
          .where((doc) => doc.data()['status'] == 'complete')
          .length;

      final daysBetween = endDate.difference(startDate).inDays + 1;
      final maxPossibleBookings = daysBetween * AppConstants.allTimeSlots.length;
      final occupancyRate = (totalBookings / maxPossibleBookings) * 100;

      return {
        'totalBookings': totalBookings,
        'completeBookings': completeBookings,
        'incompleteBookings': totalBookings - completeBookings,
        'occupancyRate': occupancyRate,
        'averageBookingsPerDay': totalBookings / daysBetween,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de uso: $e');
    }
  }

  @override
  Future<Court?> getMostPopularCourt(DateTime startDate, DateTime endDate) async {
    try {
      final courts = await getAllCourts();
      Court? mostPopular;
      int maxBookings = 0;

      for (final court in courts) {
        final stats = await getCourtUsageStats(court.id, startDate, endDate);
        final bookings = stats['totalBookings'] as int;
        
        if (bookings > maxBookings) {
          maxBookings = bookings;
          mostPopular = court;
        }
      }

      return mostPopular;
    } catch (e) {
      throw Exception('Error al obtener cancha más popular: $e');
    }
  }

  @override
  Future<Court?> getLeastUsedCourt(DateTime startDate, DateTime endDate) async {
    try {
      final courts = await getActiveCourts();
      Court? leastUsed;
      int minBookings = double.maxFinite.toInt();

      for (final court in courts) {
        final stats = await getCourtUsageStats(court.id, startDate, endDate);
        final bookings = stats['totalBookings'] as int;
        
        if (bookings < minBookings) {
          minBookings = bookings;
          leastUsed = court;
        }
      }

      return leastUsed;
    } catch (e) {
      throw Exception('Error al obtener cancha menos utilizada: $e');
    }
  }

  @override
  Future<Map<String, double>> getRevenueByCourtInPeriod(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final courts = await getAllCourts();
      final Map<String, double> revenue = {};

      for (final court in courts) {
        final bookingsQuery = await _firestore
            .collection(FirebaseConstants.bookingsCollection)
            .where('courtId', isEqualTo: court.id)
            .where('dateTime.timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
            .where('dateTime.timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
            .where('status', isEqualTo: 'complete')
            .get();

        double courtRevenue = 0.0;
        for (final doc in bookingsQuery.docs) {
          // Calcular ingresos basado en jugadores y sus categorías
          // Por simplicidad, usamos tarifa promedio
          final players = (doc.data()['players'] as List).length;
          courtRevenue += players * 10000.0; // Tarifa promedio
        }
        
        revenue[court.name] = courtRevenue;
      }

      return revenue;
    } catch (e) {
      throw Exception('Error al obtener ingresos por cancha: $e');
    }
  }

  @override
  Future<Map<String, List<String>>> getPeakTimesByCourtInPeriod(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final courts = await getAllCourts();
      final Map<String, List<String>> peakTimes = {};

      for (final court in courts) {
        final bookingsQuery = await _firestore
            .collection(FirebaseConstants.bookingsCollection)
            .where('courtId', isEqualTo: court.id)
            .where('dateTime.timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
            .where('dateTime.timestamp', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
            .where('visibleInCalendar', isEqualTo: true)
            .get();

        final Map<String, int> timeSlotCount = {};
        
        for (final doc in bookingsQuery.docs) {
          final time = doc.data()['dateTime']['time'] as String;
          timeSlotCount[time] = (timeSlotCount[time] ?? 0) + 1;
        }

        // Obtener los 3 horarios más populares
        final sortedTimes = timeSlotCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        peakTimes[court.name] = sortedTimes
            .take(3)
            .map((entry) => entry.key)
            .toList();
      }

      return peakTimes;
    } catch (e) {
      throw Exception('Error al obtener horarios pico: $e');
    }
  }

  @override
  Future<Map<String, double>> getOccupancyRateByCourtInPeriod(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final courts = await getAllCourts();
      final Map<String, double> occupancyRates = {};

      for (final court in courts) {
        final stats = await getCourtUsageStats(court.id, startDate, endDate);
        occupancyRates[court.name] = stats['occupancyRate'] as double;
      }

      return occupancyRates;
    } catch (e) {
      throw Exception('Error al obtener tasas de ocupación: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONFIGURACIÓN Y TEMPORADAS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<String?> getActiveSeasonForCourt(String courtId) async {
    try {
      final court = await getCourtById(courtId);
      return court?.seasonId;
    } catch (e) {
      throw Exception('Error al obtener temporada activa: $e');
    }
  }

  @override
  Future<void> updateCourtSeason(String courtId, String? seasonId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'seasonId': seasonId,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar temporada: $e');
    }
  }

  @override
  Future<int> getBookingDurationForCourt(String courtId) async {
    try {
      final court = await getCourtById(courtId);
      return court?.bookingDurationMinutes ?? AppConstants.bookingDurationMinutes;
    } catch (e) {
      throw Exception('Error al obtener duración de reserva: $e');
    }
  }

  @override
  Future<void> updateCourtBookingDuration(String courtId, int durationMinutes) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'bookingDurationMinutes': durationMinutes,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar duración de reserva: $e');
    }
  }

  @override
  Future<int> getRequiredPlayersForCourt(String courtId) async {
    try {
      final court = await getCourtById(courtId);
      return court?.requiredPlayers ?? AppConstants.requiredPlayersPerBooking;
    } catch (e) {
      throw Exception('Error al obtener jugadores requeridos: $e');
    }
  }

  @override
  Future<void> updateCourtRequiredPlayers(String courtId, int requiredPlayers) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(courtId)
          .update({
            'requiredPlayers': requiredPlayers,
            'metadata.updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error al actualizar jugadores requeridos: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE STREAM (TIEMPO REAL)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Court?> watchCourt(String courtId) {
    return _firestore
        .collection(_collection)
        .doc(courtId)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => CourtModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<Court>> watchCourtsByStatus(CourtStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.value)
        .orderBy('displayOrder')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => CourtModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<Court>> watchCourtsOrderedForDisplay() {
    return _firestore
        .collection(_collection)
        .where('status', whereIn: [CourtStatus.active.value, CourtStatus.maintenance.value])
        .orderBy('displayOrder')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => CourtModel.fromFirestore(doc))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS AUXILIARES
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
// Reemplaza desde la línea 890 en adelante por esto:
  
  @override
  Stream<List<Court>> watchAllCourts() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => CourtModel.fromFirestore(doc))
            .cast<Court>()
            .toList());
  }

  @override
  Stream<List<Court>> watchActiveCourts() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => CourtModel.fromFirestore(doc))
            .cast<Court>()
            .toList());
  }
}