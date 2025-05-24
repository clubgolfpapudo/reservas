// lib/presentation/providers/booking_provider.dart
import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/court_repository.dart';
import '../../core/constants/app_constants.dart';

/// Provider que maneja el estado de las reservas
class BookingProvider extends ChangeNotifier {
  final BookingRepository _bookingRepository;
  final CourtRepository _courtRepository;

  BookingProvider({
    required BookingRepository bookingRepository,
    required CourtRepository courtRepository,
  })  : _bookingRepository = bookingRepository,
        _courtRepository = courtRepository;

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADO DE LA APLICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fecha seleccionada
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Cancha seleccionada
  String _selectedCourtId = '';
  String get selectedCourtId => _selectedCourtId;

  // Reservas del día actual
  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  // Canchas disponibles
  List<Court> _courts = [];
  List<Court> get courts => _courts;

  // Horarios disponibles para la fecha y cancha seleccionada
  List<String> _availableTimeSlots = [];
  List<String> get availableTimeSlots => _availableTimeSlots;

  // Error actual
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Estado del proceso de reserva
  BookingFlowState _bookingFlowState = BookingFlowState.viewing;
  BookingFlowState get bookingFlowState => _bookingFlowState;

  // Datos de la reserva en proceso
  String? _selectedTimeSlot;
  String? get selectedTimeSlot => _selectedTimeSlot;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicializa el provider cargando datos iniciales
  Future<void> initialize() async {
    await _loadCourts();
    if (_courts.isNotEmpty) {
      await selectCourt(_courts.first.id);
    }
    await loadBookingsForDate(_selectedDate);
  }

  /// Carga todas las canchas disponibles
  Future<void> _loadCourts() async {
    try {
      _setLoading(true);
      _courts = await _courtRepository.getActiveCourts();
      
      // Seleccionar primera cancha por defecto
      if (_courts.isNotEmpty && _selectedCourtId.isEmpty) {
        _selectedCourtId = _courts.first.id;
      }
      
      _clearError();
    } catch (e) {
      _setError('Error al cargar canchas: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE SELECCIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Selecciona una fecha específica
  Future<void> selectDate(DateTime date) async {
    if (date.isAtSameMomentAs(_selectedDate)) return;
    
    _selectedDate = date;
    await loadBookingsForDate(date);
    await _loadAvailableTimeSlots();
    notifyListeners();
  }

  /// Selecciona una cancha específica
  Future<void> selectCourt(String courtId) async {
    if (courtId == _selectedCourtId) return;
    
    _selectedCourtId = courtId;
    await loadBookingsForDate(_selectedDate);
    await _loadAvailableTimeSlots();
    notifyListeners();
  }

  /// Selecciona un horario para reserva
  void selectTimeSlot(String timeSlot) {
    _selectedTimeSlot = timeSlot;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CARGA DE DATOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carga las reservas para una fecha específica
  Future<void> loadBookingsForDate(DateTime date) async {
    try {
      _setLoading(true);
      
      if (_selectedCourtId.isNotEmpty) {
        _bookings = await _bookingRepository.getBookingsByDateAndCourt(
          date, 
          _selectedCourtId
        );
      } else {
        _bookings = await _bookingRepository.getBookingsByDate(date);
      }
      
      _clearError();
    } catch (e) {
      _setError('Error al cargar reservas: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga los horarios disponibles para la fecha y cancha seleccionada
  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedCourtId.isEmpty) {
      _availableTimeSlots = [];
      return;
    }

    try {
      _availableTimeSlots = await _bookingRepository.getAvailableTimeSlots(
        _selectedDate,
        _selectedCourtId,
      );
    } catch (e) {
      _setError('Error al cargar horarios disponibles: $e');
      _availableTimeSlots = [];
    }
  }

  /// Recarga todos los datos
  Future<void> refresh() async {
    await _loadCourts();
    await loadBookingsForDate(_selectedDate);
    await _loadAvailableTimeSlots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE RESERVA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicia el proceso de reserva para un horario específico
  Future<void> startBookingProcess(String timeSlot) async {
    try {
      _selectedTimeSlot = timeSlot;
      _bookingFlowState = BookingFlowState.selecting;
      
      // Verificar disponibilidad antes de continuar
      final isAvailable = await _bookingRepository.isTimeSlotAvailable(
        _selectedDate,
        timeSlot,
        _selectedCourtId,
      );

      if (!isAvailable) {
        throw Exception('El horario ya no está disponible');
      }

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Error al iniciar reserva: $e');
    }
  }

  /// Confirma que el proceso de reserva se completó exitosamente
  void confirmBookingCompleted() {
    _bookingFlowState = BookingFlowState.completed;
    _selectedTimeSlot = null;
    notifyListeners();
    
    // Recargar datos después de un delay
    Future.delayed(const Duration(seconds: 2), () {
      refresh();
    });
  }

  /// Cancela el proceso de reserva actual
  void cancelBookingProcess() {
    _bookingFlowState = BookingFlowState.viewing;
    _selectedTimeSlot = null;
    _clearError();
    notifyListeners();
  }

  /// Actualiza el estado del flujo de reserva
  void updateBookingFlowState(BookingFlowState newState) {
    _bookingFlowState = newState;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE VALIDACIÓN Y UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si un horario está disponible
  bool isTimeSlotAvailable(String timeSlot) {
    return _availableTimeSlots.contains(timeSlot);
  }

  /// Obtiene la reserva para un horario específico
  Booking? getBookingForTimeSlot(String timeSlot) {
    try {
      return _bookings.firstWhere(
        (booking) => booking.dateTime.time == timeSlot,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el estado de un horario específico
  TimeSlotStatus getTimeSlotStatus(String timeSlot) {
    final booking = getBookingForTimeSlot(timeSlot);
    
    if (booking == null) {
      return TimeSlotStatus.available;
    }
    
    switch (booking.status) {
      case BookingStatus.complete:
        return TimeSlotStatus.reserved;
      case BookingStatus.incomplete:
        return TimeSlotStatus.incomplete;
      case BookingStatus.cancelled:
        return TimeSlotStatus.available;
    }
  }

  /// Obtiene el nombre de la cancha seleccionada
  String get selectedCourtName {
    if (_selectedCourtId.isEmpty || _courts.isEmpty) return '';
    
    try {
      final court = _courts.firstWhere((c) => c.id == _selectedCourtId);
      return court.name;
    } catch (e) {
      return '';
    }
  }

  /// Obtiene la cancha seleccionada
  Court? get selectedCourt {
    if (_selectedCourtId.isEmpty || _courts.isEmpty) return null;
    
    try {
      return _courts.firstWhere((c) => c.id == _selectedCourtId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene fechas disponibles para reservar (próximos X días)
  List<DateTime> get availableDates {
    final dates = <DateTime>[];
    final today = DateTime.now();
    
    for (int i = 0; i < AppConstants.maxDaysInAdvance; i++) {
      dates.add(DateTime(
        today.year,
        today.month,
        today.day + i,
      ));
    }
    
    return dates;
  }

  /// Verifica si una fecha es hoy
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Verifica si una fecha es mañana
  bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
           date.month == tomorrow.month &&
           date.day == tomorrow.day;
  }

  /// Obtiene el nombre formateado de una fecha
  String getFormattedDateName(DateTime date) {
    if (isToday(date)) return 'Hoy';
    if (isTomorrow(date)) return 'Mañana';
    
    final weekday = AppConstants.getWeekdayName(date.weekday);
    return '$weekday ${date.day}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS DE ESTADO
  // ═══════════════════════════════════════════════════════════════════════════

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE LIMPIEZA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS Y CLASES AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

/// Estados del flujo de reserva
enum BookingFlowState {
  viewing,        // Viendo reservas
  selecting,      // Seleccionando fecha/hora
  booking,        // En proceso de reserva (WebView)
  completed,      // Reserva completada
}

/// Estados de un time slot
enum TimeSlotStatus {
  available,      // Disponible para reservar
  reserved,       // Reservado (4 jugadores)
  incomplete,     // Incompleto (menos de 4 jugadores)
}

/// Extensión para obtener colores según el estado del time slot
extension TimeSlotStatusExtension on TimeSlotStatus {
  Color get backgroundColor {
    switch (this) {
      case TimeSlotStatus.available:
        return AppColors.available;
      case TimeSlotStatus.reserved:
        return AppColors.reserved;
      case TimeSlotStatus.incomplete:
        return AppColors.incomplete;
    }
  }
  
  Color get textColor {
    switch (this) {
      case TimeSlotStatus.available:
        return AppColors.availableText;
      case TimeSlotStatus.reserved:
        return AppColors.reservedText;
      case TimeSlotStatus.incomplete:
        return AppColors.incompleteText;
    }
  }
  
  String get statusText {
    switch (this) {
      case TimeSlotStatus.available:
        return 'DISPONIBLE';
      case TimeSlotStatus.reserved:
        return 'RESERVADA';
      case TimeSlotStatus.incomplete:
        return 'INCOMPLETA';
    }
  }
}