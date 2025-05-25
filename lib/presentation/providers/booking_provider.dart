// lib/presentation/providers/booking_provider.dart (versión mock)
import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import '../../data/mock/mock_data.dart';
import '../../core/constants/app_constants.dart';

class BookingProvider extends ChangeNotifier {
  // State variables
  DateTime _selectedDate = DateTime.now();
  String _selectedCourtId = 'court_1'; // PITE por defecto
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  DateTime get selectedDate => _selectedDate;
  String get selectedCourtId => _selectedCourtId;
  String get selectedCourtName => AppConstants.getCourtName(_selectedCourtId);
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor - cargar datos iniciales
  BookingProvider() {
    _loadBookings();
  }

  // Cambiar fecha seleccionada
  void selectDate(DateTime date) {
    if (_selectedDate != date) {
      _selectedDate = date;
      _loadBookings();
      notifyListeners();
    }
  }

  // Cambiar cancha seleccionada por nombre
  void selectCourt(String courtName) {
    final courtId = AppConstants.getCourtId(courtName);
    if (_selectedCourtId != courtId) {
      _selectedCourtId = courtId;
      _loadBookings();
      notifyListeners();
    }
  }

  // Cambiar cancha por ID
  void selectCourtById(String courtId) {
    if (_selectedCourtId != courtId) {
      _selectedCourtId = courtId;
      _loadBookings();
      notifyListeners();
    }
  }

  // Cargar datos mock usando tu estructura existente
  Future<void> _loadBookings() async {
    try {
      _setLoading(true);
      _clearError();

      // Simular delay de red
      await Future.delayed(Duration(milliseconds: 300));

      // Usar tu método existente
      final mockBookings = MockData.getBookingsForDateAndCourt(
        _selectedDate, 
        _selectedCourtId,
      );

      _bookings = mockBookings;
      _setLoading(false);
    } catch (e) {
      _setError('Error cargando reservas: $e');
      _setLoading(false);
    }
  }

  // Obtener reserva por horario específico
  Booking? getBookingForTime(String time) {
    try {
      return _bookings.firstWhere(
        (booking) => booking.dateTime.time == time,
      );
    } catch (e) {
      return null; // No encontrada
    }
  }

  // Verificar si un horario está disponible
  bool isTimeSlotAvailable(String time) {
    return getBookingForTime(time) == null;
  }

  // Obtener estado de un horario específico (null = disponible)
  BookingStatus? getTimeSlotStatus(String time) {
    final booking = getBookingForTime(time);
    return booking?.status; // null significa disponible
  }

  // Obtener jugadores activos para un horario (usando BookingPlayer)
  List<BookingPlayer> getPlayersForTime(String time) {
    final booking = getBookingForTime(time);
    return booking?.players
        .where((player) => player.status == PlayerStatus.confirmed)
        .toList() ?? [];
  }

  // Obtener estadísticas para el CompactStats widget
  Map<String, int> getStats() {
    final completeCount = _bookings
        .where((booking) => booking.status == BookingStatus.complete)
        .length;
    
    final incompleteCount = _bookings
        .where((booking) => booking.status == BookingStatus.incomplete)
        .length;
    
    final totalBookedSlots = _bookings.length;
    final availableCount = AppConstants.availableTimeSlots.length - totalBookedSlots;

    return {
      'complete': completeCount,
      'incomplete': incompleteCount,
      'available': availableCount >= 0 ? availableCount : 0,
    };
  }

  // Simular creación de reserva (usando BookingPlayer)
  Future<bool> createBooking({
    required String time,
    required List<BookingPlayer> players,
    String? calendlyUri,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Simular delay de creación
      await Future.delayed(Duration(seconds: 1));

      // En implementación real, aquí iría la llamada al servicio
      print('Mock: Creando reserva para $time con ${players.length} jugadores');
      
      // Recargar datos después de crear
      await _loadBookings();
      
      return true;
    } catch (e) {
      _setError('Error creando reserva: $e');
      _setLoading(false);
      return false;
    }
  }

  // Simular cancelación de jugador
  Future<bool> cancelPlayerFromBooking(String bookingId, String playerEmail) async {
    try {
      _setLoading(true);
      _clearError();

      // Simular delay
      await Future.delayed(Duration(milliseconds: 800));

      print('Mock: Cancelando jugador $playerEmail de reserva $bookingId');
      
      // Recargar datos
      await _loadBookings();
      
      return true;
    } catch (e) {
      _setError('Error cancelando jugador: $e');
      _setLoading(false);
      return false;
    }
  }

  // Recargar datos manualmente
  Future<void> refresh() async {
    await _loadBookings();
  }

  // Helpers privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Método para debugging
  void debugPrintBookings() {
    print('=== BOOKINGS DEBUG ===');
    print('Date: $_selectedDate');
    print('Court: $_selectedCourtId (${selectedCourtName})');
    print('Bookings count: ${_bookings.length}');
    for (final booking in _bookings) {
      print('  ${booking.dateTime.time} - ${booking.status} - ${booking.activePlayersCount} players');
    }
    print('===================');
  }
}