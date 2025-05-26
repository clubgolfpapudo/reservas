// ============================================================================
// lib/presentation/providers/booking_provider.dart - REEMPLAZAR COMPLETAMENTE
// ============================================================================

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
    await _loadCourts();
    await _loadBookings();
  }
  
  // ============================================================================
  // CARGA DE DATOS DESDE FIREBASE
  // ============================================================================
  
  Future<void> _loadCourts() async {
    try {
      _setLoading(true);
      print('📋 Cargando canchas desde Firestore...');
      
      // Cancelar suscripción anterior si existe
      _courtsSubscription?.cancel();
      
      // Stream en tiempo real de Firestore
      _courtsSubscription = FirestoreService.getCourts().listen(
        (courts) {
          print('✅ Canchas cargadas: ${courts.length}');
          for (var court in courts) {
            print('   - ${court.name} (${court.id})');
          }
          
          _courts = courts;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          print('❌ Error cargando canchas: $error');
          _setError('Error cargando canchas: $error');
        },
      );
    } catch (e) {
      print('❌ Error conectando con Firebase: $e');
      _setError('Error conectando con Firebase: $e');
    }
  }
  
  Future<void> _loadBookings() async {
    try {
      print('📋 Cargando reservas desde Firestore para fecha: $_selectedDate');
      
      // Cancelar suscripción anterior si existe
      _bookingsSubscription?.cancel();
      
      // Stream en tiempo real de Firestore
      _bookingsSubscription = FirestoreService.getBookingsByDate(_selectedDate).listen(
        (bookings) {
          print('✅ Reservas cargadas: ${bookings.length}');
          for (var booking in bookings) {
            print('   - ${booking.courtNumber} ${booking.timeSlot}: ${booking.players.length} jugadores');
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
      notifyListeners();
    }
  }
  
  void selectDate(DateTime date) {
    if (_selectedDate != date) {
      print('📅 Cambiando a fecha: $date');
      _selectedDate = date;
      _loadBookings(); // Recargar reservas para nueva fecha
      notifyListeners();
    }
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
    print('   - Loading: $_isLoading');
    print('   - Error: $_error');
  }
}