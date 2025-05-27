// lib/presentation/providers/booking_provider.dart - ACTUALIZAR
import 'package:flutter/material.dart';
import 'dart:async';

// Entities
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';

// Services  
import '../../data/services/firestore_service.dart';

// Constants
import '../../core/constants/app_constants.dart';

class BookingProvider extends ChangeNotifier {
  // ============================================================================
  // ESTADO PRIVADO
  // ============================================================================
  
  List<Court> _courts = [];
  List<Booking> _bookings = [];
  String _selectedCourtId = 'court_1';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  
  // NUEVO: Estado para navegación de fechas
  List<DateTime> _availableDates = [];
  int _currentDateIndex = 0;
  
  // Streams subscriptions para limpiar recursos
  StreamSubscription? _courtsSubscription;
  StreamSubscription? _bookingsSubscription;
  
  // ============================================================================
  // GETTERS PÚBLICOS
  // ============================================================================
  
  List<Court> get courts => _courts;
  List<Booking> get bookings => _bookings;
  String get selectedCourtId => _selectedCourtId;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // NUEVOS: Getters para navegación de fechas
  List<DateTime> get availableDates => _availableDates;
  int get currentDateIndex => _currentDateIndex;
  int get totalAvailableDays => _availableDates.length;
  
  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================
  
  Court? get selectedCourt {
    try {
      return _courts.firstWhere((court) => court.id == _selectedCourtId);
    } catch (e) {
      return null;
    }
  }
  
  String get selectedCourtName {
    return selectedCourt?.name ?? 'Cancha';
  }
  
  List<Booking> get currentBookings {
    final bookings = _bookings.where((booking) => booking.courtNumber == _selectedCourtId).toList();
    print('🚨🚨🚨 DEBUG RESERVAS 🚨🚨🚨');
    print('Court seleccionada: $_selectedCourtId');
    print('Fecha seleccionada: $_selectedDate');
    print('Total bookings encontradas: ${bookings.length}');
    if (bookings.isNotEmpty) {
      print('Primera reserva: ${bookings[0].timeSlot}');
    }
    return bookings;
  }
  
  // ============================================================================
  // ESTADÍSTICAS PARA UI COMPACTA
  // ============================================================================
  
  int get completeBookingsCount {
    return currentBookings
        .where((b) => b.status == BookingStatus.complete)
        .length;
  }
  
  int get incompleteBookingsCount {
    return currentBookings
        .where((b) => b.status == BookingStatus.incomplete)
        .length;
  }
  
  int get availableBookingsCount {
    const timeSlots = ['09:00', '10:30', '12:00', '13:30', '15:00', '16:30', '18:00', '19:30'];
    return timeSlots.length - currentBookings.length;
  }
  
  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  Booking? getBookingForTimeSlot(String timeSlot) {
    print('DEBUG: Buscando timeSlot: "$timeSlot"');
    print('DEBUG: currentBookings count: ${currentBookings.length}');
    print('DEBUG: currentBookings: ${currentBookings.map((b) => "${b.timeSlot} - ${b.courtNumber}").toList()}');
    
    try {
      final result = currentBookings.firstWhere(
        (booking) => booking.timeSlot == timeSlot,
      );
      print('DEBUG: ¡Encontrada! ${result.timeSlot} en cancha ${result.courtNumber}');
      return result;
    } catch (e) {
      print('DEBUG: No encontrada para timeSlot: "$timeSlot"');
      return null;
    }
  }

  bool isTimeSlotAvailable(String timeSlot) {
    return getBookingForTimeSlot(timeSlot) == null;
  }
  
  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================
  
  BookingProvider() {
    _initializeProvider();
  }
  
  Future<void> _initializeProvider() async {
    print('🔥 Inicializando BookingProvider con Firebase...');
    _generateAvailableDates();
    await _loadCourts();
    await _loadBookings();
  }
  
  // NUEVO: Generar fechas disponibles (regla 72 horas)
  void _generateAvailableDates() {
    _availableDates.clear();
    final now = DateTime.now();
    
    for (int i = 0; i < 4; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      _availableDates.add(date);
    }
    
    // Establecer fecha actual como la primera disponible
    _selectedDate = _availableDates[0];
    _currentDateIndex = 0;
    
    print('📅 Fechas disponibles generadas: ${_availableDates.length}');
    for (var date in _availableDates) {
      print('   - ${_formatDate(date)}');
    }
  }
  
  // Helper para formatear fechas
  String _formatDate(DateTime date) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} de ${months[date.month]}';
  }
  
  // ============================================================================
  // CARGA DE DATOS DESDE FIREBASE
  // ============================================================================
  
  Future<void> _loadCourts() async {
    try {
      _setLoading(true);
      print('📋 Cargando canchas...');
      
      // Mock data para canchas usando tu estructura completa
      final now = DateTime.now();
      _courts = [
        Court(
          id: 'court_1',
          name: 'PITE',
          description: 'Cancha de pádel PITE',
          number: 1,
          displayOrder: 1,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'court_2',
          name: 'LILEN',
          description: 'Cancha de pádel LILEN',
          number: 2,
          displayOrder: 2,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
        Court(
          id: 'court_3',
          name: 'PLAIYA',
          description: 'Cancha de pádel PLAIYA',
          number: 3,
          displayOrder: 3,
          status: 'active',
          isAvailableForBooking: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      
      print('✅ Canchas cargadas: ${_courts.length}');
      for (var court in _courts) {
        print('   - ${court.name} (${court.id}) - ${court.status}');
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando canchas: $e');
      _setError('Error cargando canchas: $e');
    }
  }
  
  Future<void> _loadBookings() async {
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      print('📋 Cargando reservas desde Firestore para fecha: $dateStr');
      print('🔍 Fecha seleccionada original: $_selectedDate');
      
      // Cancelar suscripción anterior si existe
      _bookingsSubscription?.cancel();
      
      // Stream en tiempo real de Firestore
      _bookingsSubscription = FirestoreService.getBookingsByDate(_selectedDate).listen(
        (bookings) {
          print('✅ Reservas cargadas: ${bookings.length}');
          print('📊 Detalles de reservas:');
          for (var booking in bookings) {
            print('   - ${booking.courtNumber} ${booking.timeSlot}: ${booking.players.length} jugadores (fecha: ${booking.date})');
          }
          
          _bookings = bookings;
          notifyListeners();
        },
        onError: (error) {
          print('❌ Error cargando reservas: $error');
          _setError('Error cargando reservas: $error');
        },
      );
    } catch (e) {
      print('❌ Error cargando reservas: $e');
      _setError('Error cargando reservas: $e');
    }
  }
  
  // ============================================================================
  // ACCIONES DEL USUARIO
  // ============================================================================
  
  void selectCourt(String courtId) {
    if (_selectedCourtId != courtId) {
      print('🏓 Cambiando a cancha: $courtId');
      _selectedCourtId = courtId;
      
      // Notificar inmediatamente para respuesta instantánea
      notifyListeners();
    }
  }
  
  void selectDate(DateTime date) {
    if (_selectedDate != date) {
      print('📅 Cambiando a fecha: $date');
      _selectedDate = date;
      
      // Actualizar índice actual
      _currentDateIndex = _availableDates.indexWhere((d) => 
        d.year == date.year && d.month == date.month && d.day == date.day);
      
      if (_currentDateIndex == -1) _currentDateIndex = 0;
      
      _loadBookings(); // Recargar reservas para nueva fecha
      notifyListeners();
    }
  }
  
  // NUEVOS: Métodos para navegación de fechas
  void selectDateByIndex(int index) {
    if (index >= 0 && index < _availableDates.length && index != _currentDateIndex) {
      _currentDateIndex = index;
      _selectedDate = _availableDates[index];
      print('📅 Cambiando a fecha por índice: $index - ${_formatDate(_selectedDate)}');
      _loadBookings();
      notifyListeners();
    }
  }
  
  void nextDate() {
    if (_currentDateIndex < _availableDates.length - 1) {
      selectDateByIndex(_currentDateIndex + 1);
    }
  }
  
  void previousDate() {
    if (_currentDateIndex > 0) {
      selectDateByIndex(_currentDateIndex - 1);
    }
  }
  
  bool get canGoToPreviousDate => _currentDateIndex > 0;
  bool get canGoToNextDate => _currentDateIndex < _availableDates.length - 1;

  // ============================================================================
  // FILTRADO DE HORARIOS POR REGLA 72 HORAS
  // ============================================================================
  
  /// Obtiene los horarios disponibles para mostrar según la fecha y hora actual
  List<String> getAvailableTimeSlotsForDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && 
                   date.month == now.month && 
                   date.day == now.day;
    
    // Calcular si es el último día de la ventana de 72 horas
    final daysDifference = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    final isLastDay = daysDifference == 3; // Día +3 de la regla 72 horas
    
    print('⏰ Calculando horarios disponibles:');
    print('   - Fecha seleccionada: $date');
    print('   - Es hoy: $isToday');
    print('   - Días de diferencia: $daysDifference');
    print('   - Es último día (72h): $isLastDay');
    print('   - Hora actual: ${now.hour}:${now.minute}');
    
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    // Lista de horarios directa (evita conflicto de imports)
    const allTimeSlots = ['09:00', '10:30', '12:00', '13:30', '15:00', '16:30', '18:00', '19:30'];
    
    final filteredSlots = allTimeSlots.where((timeSlot) {
      final parts = timeSlot.split(':');
      final slotHour = int.parse(parts[0]);
      final slotMinute = int.parse(parts[1]);
      final slotTimeInMinutes = slotHour * 60 + slotMinute;
      
      if (isToday) {
        // Hoy: mostrar solo horarios futuros (al menos 30 min)
        return slotTimeInMinutes > (currentTimeInMinutes);
      } else if (isLastDay) {
        // Último día (72h): mostrar solo hasta la hora actual
        return slotTimeInMinutes <= currentTimeInMinutes;
      } else {
        // Días intermedios: mostrar todos los horarios
        return true;
      }
    }).toList();
    
    print('   - Horarios filtrados: ${filteredSlots.length}');
    print('   - Horarios: $filteredSlots');
    
    return filteredSlots;
  }
  
  Future<void> refresh() async {
    print('🔄 Refrescando datos...');
    await _loadBookings();
  }
  
  // ============================================================================
  // OPERACIONES CRUD (Para futuro uso)
  // ============================================================================
  
  Future<void> createBooking(Booking booking) async {
    try {
      _setLoading(true);
      print('➕ Creando nueva reserva...');
      
      final bookingId = await FirestoreService.createBooking(booking);
      print('✅ Reserva creada con ID: $bookingId');
      
      _setLoading(false);
    } catch (e) {
      print('❌ Error creando reserva: $e');
      _setError('Error creando reserva: $e');
    }
  }

  // ============================================================================
  // GESTIÓN DE ESTADO INTERNO
  // ============================================================================
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ============================================================================
  // CLEANUP - Importante para evitar memory leaks
  // ============================================================================
  
  @override
  void dispose() {
    print('🧹 Limpiando BookingProvider...');
    _courtsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    super.dispose();
  }
  
  // ============================================================================
  // DEBUG - Método para verificar estado
  // ============================================================================
  
  void debugPrintState() {
    print('🐛 BookingProvider State:');
    print('   - Courts: ${_courts.length}');
    print('   - Bookings: ${_bookings.length}');
    print('   - Selected Court: $_selectedCourtId');
    print('   - Selected Date: $_selectedDate');
    print('   - Current Date Index: $_currentDateIndex');
    print('   - Available Dates: ${_availableDates.length}');
    print('   - Loading: $_isLoading');
    print('   - Error: $_error');
  }
}