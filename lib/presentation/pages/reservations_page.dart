// lib/presentation/pages/reservations_page.dart
import 'package:flutter/material.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';
import '../../data/mock/mock_data.dart';
import '../widgets/time_slot_block.dart';
import '../widgets/court_tab_button.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  DateTime selectedDate = DateTime.now();
  String selectedCourt = 'PITE'; // Cancha por defecto
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        title: const Text(
          'Reservas de Padel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateReservationDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información de fecha y selector de cancha
          _buildDateAndCourtHeader(),
          
          // Lista de horarios con reservas
          Expanded(
            child: _buildTimeSlotsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndCourtHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Encabezado con fecha según diseño del documento
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Reservas ",
                  style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
                ),
                Icon(
                  Icons.sports_tennis,
                  size: 32,
                  color: Colors.blue.shade600,
                ),
                Text(
                  " ${selectedDate.day} de ${_getMonthName(selectedDate.month)}",
                  style: TextStyle(
                    fontSize: 32.0, 
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selector de cancha según diseño del documento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CourtTabButton(
                court: "PITE", 
                isSelected: selectedCourt == "PITE",
                onTap: () => _onCourtSelected("PITE"),
              ),
              CourtTabButton(
                court: "LILEN", 
                isSelected: selectedCourt == "LILEN",
                onTap: () => _onCourtSelected("LILEN"),
              ),
              CourtTabButton(
                court: "PLAIYA", 
                isSelected: selectedCourt == "PLAIYA",
                onTap: () => _onCourtSelected("PLAIYA"),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Resumen de reservas del día
          _buildDaySummary(),
        ],
      ),
    );
  }

  Widget _buildDaySummary() {
    final selectedCourtData = MockData.getCourtByName(selectedCourt);
    final todayBookings = _getBookingsForSelectedDateAndCourt();
    
    final completeBookings = todayBookings.where((b) => b.status == BookingStatus.complete).length;
    final incompleteBookings = todayBookings.where((b) => b.status == BookingStatus.incomplete).length;
    final availableSlots = MockData.availableTimeSlots.length - todayBookings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.check_circle,
            label: 'Completas',
            value: '$completeBookings',
            color: const Color(0xFF2E7AFF), // Azul según documento
          ),
          _buildSummaryItem(
            icon: Icons.warning,
            label: 'Incompletas',
            value: '$incompleteBookings',
            color: const Color(0xFFFF7530), // Naranja según documento
          ),
          _buildSummaryItem(
            icon: Icons.schedule,
            label: 'Disponibles',
            value: '$availableSlots',
            color: Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsList() {
    final bookings = _getBookingsForSelectedDateAndCourt();
    final bookingsByTime = <String, Booking>{};
    
    // Mapear reservas por horario
    for (final booking in bookings) {
      bookingsByTime[booking.dateTime.time] = booking;
    }

    if (MockData.availableTimeSlots.isEmpty) {
      return const Center(
        child: Text('No hay horarios configurados'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MockData.availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = MockData.availableTimeSlots[index];
        final booking = bookingsByTime[timeSlot];
        
        if (booking != null) {
          // Hay una reserva en este horario
          return TimeSlotBlock(
            time: timeSlot,
            status: booking.status,
            players: booking.confirmedPlayers,
            onReservePressed: () {}, // No aplicable para reservas existentes
            onTap: () => _showBookingDetails(booking),
          );
        } else {
          // Horario disponible
          return TimeSlotBlock(
            time: timeSlot,
            status: null, // null indica disponible
            players: const [],
            onReservePressed: () => _initiateBookingProcess(timeSlot),
            onTap: () => _initiateBookingProcess(timeSlot),
          );
        }
      },
    );
  }

  // Métodos auxiliares
  List<Booking> _getBookingsForSelectedDateAndCourt() {
    final selectedCourtData = MockData.getCourtByName(selectedCourt);
    if (selectedCourtData == null) return [];
    
    return MockData.getBookingsForDateAndCourt(selectedDate, selectedCourtData.id);
  }

  void _onCourtSelected(String courtName) {
    setState(() {
      selectedCourt = courtName;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  void _showCreateReservationDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 Próximamente: Crear nueva reserva'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reserva ${booking.dateTime.time}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: ${booking.status.displayName}'),
            Text('Cancha: ${booking.court} - $selectedCourt'),
            const Divider(),
            const Text('Jugadores:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...booking.confirmedPlayers.map((player) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                children: [
                  Icon(
                    player.isMainBooker ? Icons.star : Icons.person,
                    size: 16,
                    color: player.isMainBooker ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(player.name)),
                ],
              ),
            )).toList(),
            if (booking.cancelledPlayers.isNotEmpty) ...[
              const Divider(),
              const Text('Cancelados:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...booking.cancelledPlayers.map((player) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              )).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _initiateBookingProcess(String timeSlot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎾 Reservar $selectedCourt a las $timeSlot - Próximamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}