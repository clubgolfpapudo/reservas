// lib/presentation/pages/reservations_page.dart
import 'package:flutter/material.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  DateTime selectedDate = DateTime.now();
  
  // 🎾 DATOS SIMULADOS - Reservas de ejemplo
  final List<Map<String, dynamic>> mockReservations = [
    {
      'id': '1',
      'courtName': 'Cancha 1',
      'courtNumber': 1,
      'date': DateTime.now(),
      'startTime': '08:00',
      'endTime': '09:30',
      'playerName': 'Juan Pérez',
      'playerPhone': '+56912345678',
      'status': 'confirmed',
      'price': 15000,
    },
    {
      'id': '2',
      'courtName': 'Cancha 1',
      'courtNumber': 1,
      'date': DateTime.now(),
      'startTime': '10:00',
      'endTime': '11:30',
      'playerName': 'María García',
      'playerPhone': '+56987654321',
      'status': 'confirmed',
      'price': 15000,
    },
    {
      'id': '3',
      'courtName': 'Cancha 2',
      'courtNumber': 2,
      'date': DateTime.now(),
      'startTime': '14:00',
      'endTime': '15:30',
      'playerName': 'Carlos López',
      'playerPhone': '+56911111111',
      'status': 'pending',
      'price': 15000,
    },
    {
      'id': '4',
      'courtName': 'Cancha 2',
      'courtNumber': 2,
      'date': DateTime.now(),
      'startTime': '16:00',
      'endTime': '17:30',
      'playerName': 'Ana Martínez',
      'playerPhone': '+56922222222',
      'status': 'confirmed',
      'price': 18000,
    },
    {
      'id': '5',
      'courtName': 'Cancha 3',
      'courtNumber': 3,
      'date': DateTime.now(),
      'startTime': '09:00',
      'endTime': '10:30',
      'playerName': 'Diego Ruiz',
      'playerPhone': '+56933333333',
      'status': 'confirmed',
      'price': 15000,
    },
  ];

  // Horarios disponibles del club
  final List<String> availableTimeSlots = [
    '08:00', '09:30', '11:00', '12:30', '14:00', '15:30', '17:00', '18:30', '20:00'
  ];

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
              // TODO: Navegar a crear nueva reserva
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nueva reserva - Próximamente')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con selector de fecha
          _buildDateSelector(),
          
          // Lista de reservas
          Expanded(
            child: _buildReservationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha seleccionada',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.edit),
                label: const Text('Cambiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDateSummary(),
        ],
      ),
    );
  }

  Widget _buildDateSummary() {
    final todayReservations = _getReservationsForDate(selectedDate);
    final totalReservations = todayReservations.length;
    final totalRevenue = todayReservations.fold<int>(
      0, (sum, reservation) => sum + (reservation['price'] as int)
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            icon: Icons.sports_tennis,
            label: 'Reservas',
            value: '$totalReservations',
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 16),
          _buildSummaryItem(
            icon: Icons.attach_money,
            label: 'Ingresos',
            value: '\$${_formatMoney(totalRevenue)}',
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
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReservationsList() {
    final reservationsForDate = _getReservationsForDate(selectedDate);
    
    if (reservationsForDate.isEmpty) {
      return _buildEmptyState();
    }

    // Agrupar reservas por cancha
    final reservationsByCourt = <int, List<Map<String, dynamic>>>{};
    for (final reservation in reservationsForDate) {
      final courtNumber = reservation['courtNumber'] as int;
      reservationsByCourt[courtNumber] ??= [];
      reservationsByCourt[courtNumber]!.add(reservation);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservationsByCourt.length,
      itemBuilder: (context, index) {
        final courtNumber = reservationsByCourt.keys.elementAt(index);
        final courtReservations = reservationsByCourt[courtNumber]!;
        
        return _buildCourtCard(courtNumber, courtReservations);
      },
    );
  }

  Widget _buildCourtCard(int courtNumber, List<Map<String, dynamic>> reservations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la cancha
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_tennis,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cancha $courtNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reservations.length} reservas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de reservas de esta cancha
          ...reservations.map((reservation) => _buildReservationItem(reservation)).toList(),
        ],
      ),
    );
  }

  Widget _buildReservationItem(Map<String, dynamic> reservation) {
    final status = reservation['status'] as String;
    final statusColor = status == 'confirmed' ? Colors.green : Colors.orange;
    final statusText = status == 'confirmed' ? 'Confirmada' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Horario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  reservation['startTime'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reservation['endTime'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Información del jugador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation['playerName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reservation['playerPhone'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Estado y precio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_formatMoney(reservation['price'])}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reservas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay reservas programadas para ${_formatDate(selectedDate)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a crear nueva reserva
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nueva reserva - Próximamente')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Nueva Reserva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares
  List<Map<String, dynamic>> _getReservationsForDate(DateTime date) {
    return mockReservations.where((reservation) {
      final reservationDate = reservation['date'] as DateTime;
      return reservationDate.year == date.year &&
             reservationDate.month == date.month &&
             reservationDate.day == date.day;
    }).toList();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    final weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekday, ${date.day} de $month';
  }

  String _formatMoney(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}