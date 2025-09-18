// lib/domain/repositories/court_repository.dart
import '../entities/court.dart';

/// Interfaz del repositorio de canchas
/// Define los métodos que debe implementar cualquier fuente de datos de canchas
abstract class CourtRepository {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONSULTA BÁSICA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene una cancha por su ID
  Future<Court?> getCourtById(String courtId);
  
  /// Obtiene una cancha por su número
  Future<Court?> getCourtByNumber(int courtNumber);
  
  /// Obtiene una cancha por su nombre
  Future<Court?> getCourtByName(String courtName);
  
  /// Obtiene todas las canchas
  Future<List<Court>> getAllCourts();
  
  /// Obtiene canchas activas (disponibles para reserva)
  Future<List<Court>> getActiveCourts();
  
  /// Obtiene canchas por estado
  Future<List<Court>> getCourtsByStatus(CourtStatus status);
  
  /// Obtiene canchas ordenadas por displayOrder
  Future<List<Court>> getCourtsOrderedForDisplay();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE DISPONIBILIDAD Y HORARIOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene horarios disponibles para una cancha en una fecha específica
  Future<List<String>> getAvailableTimeSlotsForCourt(String courtId, DateTime date);
  
  /// Verifica si una cancha está disponible para reservas
  Future<bool> isCourtAvailableForBooking(String courtId);
  
  /// Verifica si una cancha tiene restricciones en una fecha específica
  Future<bool> hasCourtExceptions(String courtId, DateTime date);
  
  /// Obtiene excepciones de una cancha para una fecha
  Future<List<CourtException>> getCourtExceptionsForDate(String courtId, DateTime date);
  
  /// Obtiene horarios personalizados de una cancha
  Future<List<String>?> getCourtCustomTimeSlots(String courtId);
  
  /// Verifica si una cancha está cerrada en una fecha específica
  Future<bool> isCourtClosedOnDate(String courtId, DateTime date);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MODIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Crea una nueva cancha
  Future<void> createCourt(Court court);
  
  /// Actualiza una cancha existente
  Future<void> updateCourt(Court court);
  
  /// Actualiza el estado de una cancha
  Future<void> updateCourtStatus(String courtId, CourtStatus status);
  
  /// Actualiza la disponibilidad para reservas
  Future<void> updateCourtAvailability(String courtId, bool isAvailable);
  
  /// Agrega una excepción a una cancha
  Future<void> addCourtException(String courtId, CourtException exception);
  
  /// Elimina una excepción de una cancha
  Future<void> removeCourtException(String courtId, String exceptionDate);
  
  /// Actualiza horarios personalizados de una cancha
  Future<void> updateCourtCustomTimeSlots(String courtId, List<String>? timeSlots);
  
  /// Actualiza el orden de visualización
  Future<void> updateDisplayOrder(String courtId, int newOrder);
  
  /// Elimina una cancha (soft delete)
  Future<void> deleteCourt(String courtId);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Verifica si un nombre de cancha ya está en uso
  Future<bool> isCourtNameInUse(String courtName, [String? excludeCourtId]);
  
  /// Verifica si un número de cancha ya está en uso
  Future<bool> isCourtNumberInUse(int courtNumber, [String? excludeCourtId]);
  
  /// Valida si una cancha puede ser eliminada
  Future<bool> canCourtBeDeleted(String courtId);
  
  /// Obtiene conflictos antes de eliminar una cancha
  Future<List<String>> getCourtDeletionConflicts(String courtId);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MANTENIMIENTO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Programa mantenimiento para una cancha
  Future<void> scheduleCourtMaintenance(
    String courtId, 
    DateTime startDate, 
    DateTime endDate, 
    String reason
  );
  
  /// Marca una cancha como en mantenimiento
  Future<void> setCourtInMaintenance(String courtId, String reason);
  
  /// Reactiva una cancha después de mantenimiento
  Future<void> reactivateCourtFromMaintenance(String courtId);
  
  /// Obtiene canchas en mantenimiento
  Future<List<Court>> getCourtsInMaintenance();
  
  /// Obtiene historial de mantenimiento de una cancha
  Future<List<CourtException>> getCourtMaintenanceHistory(String courtId);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene estadísticas de uso por cancha
  Future<Map<String, dynamic>> getCourtUsageStats(
    String courtId, 
    DateTime startDate, 
    DateTime endDate
  );
  
  /// Obtiene la cancha más popular
  Future<Court?> getMostPopularCourt(DateTime startDate, DateTime endDate);
  
  /// Obtiene la cancha menos utilizada
  Future<Court?> getLeastUsedCourt(DateTime startDate, DateTime endDate);
  
  /// Obtiene ingresos generados por cancha
  Future<Map<String, double>> getRevenueByCourtInPeriod(
    DateTime startDate, 
    DateTime endDate
  );
  
  /// Obtiene horarios pico por cancha
  Future<Map<String, List<String>>> getPeakTimesByCourtInPeriod(
    DateTime startDate, 
    DateTime endDate
  );
  
  /// Obtiene tasa de ocupación por cancha
  Future<Map<String, double>> getOccupancyRateByCourtInPeriod(
    DateTime startDate, 
    DateTime endDate
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONFIGURACIÓN Y TEMPORADAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene la temporada activa para una cancha
  Future<String?> getActiveSeasonForCourt(String courtId);
  
  /// Actualiza la temporada de una cancha
  Future<void> updateCourtSeason(String courtId, String? seasonId);
  
  /// Obtiene configuración de duración de reserva
  Future<int> getBookingDurationForCourt(String courtId);
  
  /// Actualiza duración de reserva para una cancha
  Future<void> updateCourtBookingDuration(String courtId, int durationMinutes);
  
  /// Obtiene número de jugadores requeridos
  Future<int> getRequiredPlayersForCourt(String courtId);
  
  /// Actualiza número de jugadores requeridos
  Future<void> updateCourtRequiredPlayers(String courtId, int requiredPlayers);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE STREAM (TIEMPO REAL)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Stream de cambios en una cancha específica
  Stream<Court?> watchCourt(String courtId);
  
  /// Stream de todas las canchas
  Stream<List<Court>> watchAllCourts();
  
  /// Stream de canchas activas
  Stream<List<Court>> watchActiveCourts();
  
  /// Stream de canchas por estado
  Stream<List<Court>> watchCourtsByStatus(CourtStatus status);
  
  /// Stream de canchas ordenadas para visualización
  Stream<List<Court>> watchCourtsOrderedForDisplay();
}