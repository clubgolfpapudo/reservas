// lib/presentation/screens/reservation_screen.dart
// INTEGRACIÓN GOLF - Vista condicional 3 columnas vs carrusel

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/golf/golf_three_column_view.dart';
import '../widgets/booking/court_carousel.dart';
import '../../core/enums/sport_type.dart';
import '../../core/utils/booking_window_service.dart';

class ReservationScreen extends StatefulWidget {
  final SportType sportType;

  const ReservationScreen({
    Key? key,
    required this.sportType,
  }) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime _selectedDate = DateTime.now();
  PageController _dateController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeForSport();
  }

  // ✅ INICIALIZACIÓN ESPECÍFICA POR DEPORTE
  void _initializeForSport() {
    final provider = context.read<ReservationProvider>();
    
    switch (widget.sportType) {
      case SportType.golf:
        // Golf: No auto-seleccionar cancha (mostrar ambas)
        provider.loadGolfConfiguration();
        break;
      case SportType.padel:
        // Pádel: Auto-seleccionar PITE
        provider.selectCourt('padel_court_1');
        break;
      case SportType.tennis:
        // Tenis: Auto-seleccionar Cancha 1
        provider.selectCourt('tennis_court_1');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ HEADER DINÁMICO POR DEPORTE
      appBar: AppBar(
        title: Text(_getSportTitle()),
        backgroundColor: _getSportColor(),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _getSportGradient(),
          ),
        ),
        actions: [
          // Información ventana de reservas
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showBookingWindowInfo(),
          ),
          // ✅ NAVEGACIÓN FECHAS GOLF - Botones compactos en header
          if (widget.sportType == SportType.golf) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_ios, size: 18),
              onPressed: _canGoToPreviousDate() ? _goToPreviousDate : null,
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 18),
              onPressed: _canGoToNextDate() ? _goToNextDate : null,
            ),
          ],
        ],
      ),
      
      body: Column(
        children: [
          // ✅ SELECTOR DE FECHAS - Solo para Pádel/Tenis, Golf integrado en header
          if (widget.sportType != SportType.golf) _buildDateSelector(),
          
          // ✅ VISTA ESPECÍFICA POR DEPORTE
          Expanded(
            child: _buildSportSpecificView(),
          ),
        ],
      ),
      
      // ✅ FAB CONDICIONAL - Solo para Golf si hay selección
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ✅ VISTA ESPECÍFICA POR DEPORTE
  Widget _buildSportSpecificView() {
    switch (widget.sportType) {
      case SportType.golf:
        // ✅ GOLF: Vista 3 columnas (HORA | HOYO 1 | HOYO 10)
        return GolfThreeColumnView(
          selectedDate: _selectedDate,
          onSlotTap: _onGolfSlotTap,
        );
        
      case SportType.padel:
      case SportType.tennis:
        // ✅ PÁDEL/TENIS: Vista carrusel existente
        return CourtCarousel(
          sportType: widget.sportType,
          selectedDate: _selectedDate,
        );
    }
  }

  // ✅ SELECTOR FECHAS - Respeta ventana por deporte
  Widget _buildDateSelector() {
    final availableDates = BookingWindowService.getAvailableBookingDates(widget.sportType);
    
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: PageView.builder(
        controller: _dateController,
        onPageChanged: (index) {
          setState(() {
            _selectedDate = availableDates[index];
          });
        },
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = date.day == _selectedDate.day &&
                            date.month == _selectedDate.month;
          
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? _getSportColor() : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSportColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getDayName(date),
                  style: TextStyle(
                    color: isSelected ? Colors.white : _getSportColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : _getSportColor(),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getMonthName(date),
                  style: TextStyle(
                    color: isSelected ? Colors.white : _getSportColor(),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ FAB CONDICIONAL
  Widget? _buildFloatingActionButton() {
    // Solo mostrar para deportes con carrusel (no Golf)
    if (widget.sportType == SportType.golf) {
      return null; // Golf usa tap directo en slots
    }
    
    return Consumer<ReservationProvider>(
      builder: (context, provider, child) {
        return FloatingActionButton.extended(
          onPressed: provider.selectedCourtId != null
            ? () => _openReservationModal(provider.selectedCourtId!)
            : null,
          backgroundColor: _getSportColor(),
          icon: Icon(Icons.add),
          label: Text('Nueva Reserva'),
        );
      },
    );
  }

  // ✅ MANEJO TAP GOLF - Directo a modal
  void _onGolfSlotTap(String teeId, TimeOfDay time) {
    _openReservationModal(teeId, preselectedTime: time);
  }

  // ✅ ABRIR MODAL RESERVA
  void _openReservationModal(String courtId, {TimeOfDay? preselectedTime}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReservationFormModal(
        sportType: widget.sportType,
        courtId: courtId,
        selectedDate: _selectedDate,
        preselectedTime: preselectedTime,
      ),
    );
  }

  // ✅ INFO VENTANA RESERVAS
  void _showBookingWindowInfo() {
    final message = BookingWindowService.getBookingWindowMessage(widget.sportType);
    final info = BookingWindowService.getBookingWindowInfo(widget.sportType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getSportIcon(), color: _getSportColor()),
            SizedBox(width: 8),
            Text('Información ${_getSportTitle()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 12),
            if (widget.sportType == SportType.golf) ...[
              Text(
                'Horarios estacionales:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Invierno: hasta 16:00'),
              Text('• Verano: hasta 17:00'),
              SizedBox(height: 8),
              Text('Salidas cada 12 minutos desde 08:00'),
              SizedBox(height: 8),
              Text(
                '⚠️ No puedes tener reservas simultáneas en Hoyo 1 y Hoyo 10',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ✅ HELPERS DEPORTE-ESPECÍFICOS
  String _getSportTitle() {
    switch (widget.sportType) {
      case SportType.golf:
        return 'Golf';
      case SportType.padel:
        return 'Pádel';
      case SportType.tennis:
        return 'Tenis';
    }
  }

  Color _getSportColor() {
    switch (widget.sportType) {
      case SportType.golf:
        return Color(0xFF7CB342);
      case SportType.padel:
        return Color(0xFF2E7AFF);
      case SportType.tennis:
        return Color(0xFFD2691E);
    }
  }

  LinearGradient _getSportGradient() {
    switch (widget.sportType) {
      case SportType.golf:
        return LinearGradient(
          colors: [Color(0xFF7CB342), Color(0xFF689F38)],
        );
      case SportType.padel:
        return LinearGradient(
          colors: [Color(0xFF2E7AFF), Color(0xFF1E5AFF)],
        );
      case SportType.tennis:
        return LinearGradient(
          colors: [Color(0xFFD2691E), Color(0xFFB8860B)],
        );
    }
  }

  IconData _getSportIcon() {
    switch (widget.sportType) {
      case SportType.golf:
        return Icons.golf_course;
      case SportType.padel:
        return Icons.sports_handball;
      case SportType.tennis:
        return Icons.sports_tennis;
    }
  }

  // ✅ NAVEGACIÓN FECHAS GOLF - Métodos helper
  bool _canGoToPreviousDate() {
    if (widget.sportType != SportType.golf) return false;
    final availableDates = BookingWindowService.getAvailableBookingDates(widget.sportType);
    final currentIndex = availableDates.indexWhere((date) => 
      date.day == _selectedDate.day && date.month == _selectedDate.month);
    return currentIndex > 0;
  }
  
  bool _canGoToNextDate() {
    if (widget.sportType != SportType.golf) return false;
    final availableDates = BookingWindowService.getAvailableBookingDates(widget.sportType);
    final currentIndex = availableDates.indexWhere((date) => 
      date.day == _selectedDate.day && date.month == _selectedDate.month);
    return currentIndex < availableDates.length - 1;
  }
  
  void _goToPreviousDate() {
    final availableDates = BookingWindowService.getAvailableBookingDates(widget.sportType);
    final currentIndex = availableDates.indexWhere((date) => 
      date.day == _selectedDate.day && date.month == _selectedDate.month);
    if (currentIndex > 0) {
      setState(() {
        _selectedDate = availableDates[currentIndex - 1];
      });
    }
  }
  
  void _goToNextDate() {
    final availableDates = BookingWindowService.getAvailableBookingDates(widget.sportType);
    final currentIndex = availableDates.indexWhere((date) => 
      date.day == _selectedDate.day && date.month == _selectedDate.month);
    if (currentIndex < availableDates.length - 1) {
      setState(() {
        _selectedDate = availableDates[currentIndex + 1];
      });
    }
  }
}