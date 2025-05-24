// lib/domain/repositories/booking_repository.dart
import '../entities/booking.dart';

/// Interfaz del repositorio de reservas
/// Define los métodos que debe implementar cualquier fuente de datos de reservas
abstract class BookingRepository {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONSULTA BÁSICA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene una reserva por su ID
  Future<Booking?> getBookingById(String bookingId);
  
  /// Obtiene todas las reservas de una fecha específica
  Future<List<Booking>> getBookingsByDate(DateTime date);
  
  /// Obtiene reservas de una fecha y cancha específica
  Future<List<Booking>> getBookingsByDateAndCourt(DateTime date, String courtId);
  
  /// Obtiene reservas de un usuario específico
  Future<List<Booking>> getBookingsByUser(String userId);
  
  /// Obtiene reservas de un usuario en un rango de fechas
  Future<List<Booking>> getUserBookingsInDateRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  );
  
  /// Obtiene reservas por estado
  Future<List<Booking>> getBookingsByStatus(BookingStatus status);
  
  /// Obtiene reservas incompletas (menos de 4 jugadores)
  Future<List<Booking>> getIncompleteBookings();
  
  /// Obtiene reservas próximas (siguientes X días)
  Future<List<Booking>> getUpcomingBookings([int daysAhead = 7]);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE DISPONIBILIDAD
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Verifica si un horario está disponible
  Future<bool> isTimeSlotAvailable(DateTime date, String time, String courtId);
  
  /// Obtiene horarios disponibles para una fecha y cancha
  Future<List<String>> getAvailableTimeSlots(DateTime date, String courtId);
  
  /// Obtiene todas las fechas con disponibilidad en los próximos X días
  Future<List<DateTime>> getAvailableDatesAhead([int daysAhead = 4]);
  
  /// Verifica si un usuario puede reservar en un horario específico
  Future<bool> canUserBookAtTime(
    String userId, 
    DateTime date, 
    String time
  );
  
  /// Obtiene conflictos de horario para un usuario
  Future<List<Booking>> getUserBookingConflicts(
    String userId, 
    DateTime date, 
    String time
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MODIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Crea una nueva reserva
  Future<String> createBooking(Booking booking);
  
  /// Actualiza una reserva existente
  Future<void> updateBooking(Booking booking);
  
  /// Agrega un jugador a una reserva incompleta
  Future<void> addPlayerToBooking(String bookingId, Player player);
  
  /// Cancela la participación de un jugador específico
  Future<void> cancelPlayerFromBooking(String bookingId, String playerEmail);
  
  /// Cancela una reserva completa
  Future<void> cancelBooking(String bookingId, String cancelledBy);
  
  /// Marca una reserva como completada
  Future<void> markBookingAsComplete(String bookingId);
  
  /// Actualiza el estado de una reserva
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  
  /// Actualiza el enlace de Calendly de una reserva
  Future<void> updateBookingCalendlyUri(String bookingId, String calendlyUri);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN Y REGLAS DE NEGOCIO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Valida si una reserva cumple las reglas de negocio
  Future<List<String>> validateBooking(Booking booking);
  
  /// Verifica restricciones de reserva por categoría de usuario
  Future<bool> checkUserBookingRestrictions(String userId, DateTime date, String time);
  
  /// Obtiene el número de reservas de un usuario en una fecha
  Future<int> getUserBookingCountForDate(String userId, DateTime date);
  
  /// Verifica si un usuario excede el límite de reservas diarias
  Future<bool> userExceedsDailyLimit(String userId, DateTime date);
  
  /// Obtiene jugadores duplicados en un horario
  Future<List<String>> getDuplicatePlayersInTimeSlot(
    DateTime date, 
    String time, 
    List<String> playerEmails
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE BÚSQUEDA Y FILTRADO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Busca reservas por nombre de jugador
  Future<List<Booking>> searchBookingsByPlayerName(String playerName);
  
  /// Busca reservas por email de jugador
  Future<List<Booking>> searchBookingsByPlayerEmail(String email);
  
  /// Obtiene reservas en un rango de fechas
  Future<List<Booking>> getBookingsInDateRange(
    DateTime startDate, 
    DateTime endDate
  );
  
  /// Obtiene reservas filtradas por múltiples criterios
  Future<List<Booking>> getFilteredBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? courtId,
    BookingStatus? status,
    String? playerEmail,
    bool? visibleInCalendar,
  });
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene estadísticas de reservas por fecha
  Future<Map<String, int>> getBookingStatsByDate(DateTime date);
  
  /// Obtiene estadísticas de uso por cancha
  Future<Map<String, int>> getCourtUsageStats(DateTime startDate, DateTime endDate);
  
  /// Obtiene horarios más populares
  Future<Map<String, int>> getPopularTimeSlots(DateTime startDate, DateTime endDate);
  
  /// Obtiene la tasa de cancelación
  Future<double> getCancellationRate(DateTime startDate, DateTime endDate);
  
  /// Obtiene ingresos por período
  Future<double> getRevenueForPeriod(DateTime startDate, DateTime endDate);
  
  /// Obtiene reservas por categoría de usuario
  Future<Map<String, int>> getBookingsByUserCategory(
    DateTime startDate, 
    DateTime endDate
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE STREAM (TIEMPO REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Stream de cambios en una reserva específica
  Stream<Booking?> watchBooking(String bookingId);
  
  /// Stream de reservas para una fecha específica
  Stream<List<Booking>> watchBookingsByDate(DateTime date);
  
  /// Stream de reservas para una fecha y cancha específica
  Stream<List<Booking>> watchBookingsByDateAndCourt(DateTime date, String courtId);
  
  /// Stream de reservas de un usuario
  Stream<List<Booking>> watchUserBookings(String userId);
  
  /// Stream de reservas próximas
  Stream<List<Booking>> watchUpcomingBookings([int daysAhead = 7]);
  
  /// Stream de reservas incompletas
  Stream<List<Booking>> watchIncompleteBookings();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE LIMPIEZA Y MANTENIMIENTO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Elimina reservas antiguas (más de X días)
  Future<void> deleteOldBookings([int daysOld = 365]);
  
  /// Marca como "no show" reservas pasadas sin confirmación
  Future<void> markNoShowBookings();
  
  /// Actualiza reservas que han expirado
  Future<void> updateExpiredBookings();
  
  /// Sincroniza reservas con sistema externo (GAS/Calendly)
  Future<void> syncWithExternalSystem();
}