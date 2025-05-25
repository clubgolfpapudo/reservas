// lib/data/mock/mock_data.dart
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/user.dart';

class MockData {
  // Datos mock de reservas según diseño del documento
  static List<Booking> get mockBookings {
    final now = DateTime.now();
    
    return [
      // Reserva COMPLETA (4 jugadores) - Cancha PITE
      Booking(
        id: 'booking_001',
        courtId: 'court_1',
        court: 1,
        dateTime: BookingDateTime(
          day: now.day,
          month: _getMonthAbbreviation(now.month),
          date: _formatDate(now),
          time: '09:00',
          timestamp: _getTimestampForTime(now, '09:00'),
        ),
        players: const [
          BookingPlayer(
            id: 'user_001',
            name: 'MARIA LOPEZ',
            email: 'cotelopez68@hotmail.com',
            isMainBooker: true,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_002',
            name: 'JAVIER REAS',
            email: 'beasjavier10@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_003',
            name: 'ALVARO BECKER',
            email: 'alvarobecker@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_004',
            name: 'LUCIA GOMEZ',
            email: 'luciagomez@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
        ],
        activePlayersCount: 4,
        status: BookingStatus.complete,
        calendlyUri: 'https://api.calendly.com/scheduled_events/example_001',
        metadata: BookingMetadata(
          createdAt: now.millisecondsSinceEpoch - 86400000,
          updatedAt: now.millisecondsSinceEpoch,
          createdBy: 'user_001',
        ),
      ),

      // Reserva INCOMPLETA (2 jugadores) - Cancha LILEN
      Booking(
        id: 'booking_002',
        courtId: 'court_2',
        court: 2,
        dateTime: BookingDateTime(
          day: now.day,
          month: _getMonthAbbreviation(now.month),
          date: _formatDate(now),
          time: '12:00',
          timestamp: _getTimestampForTime(now, '12:00'),
        ),
        players: const [
          BookingPlayer(
            id: 'user_005',
            name: 'CARLOS MARTINEZ',
            email: 'carlos.martinez@gmail.com',
            isMainBooker: true,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_006',
            name: 'ANA SILVA',
            email: 'ana.silva@hotmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_007',
            name: 'PEDRO GONZALEZ',
            email: 'pedro.gonzalez@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.cancelled,
          ),
          BookingPlayer(
            id: 'user_008',
            name: 'SOFIA RODRIGUEZ',
            email: 'sofia.rodriguez@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.cancelled,
          ),
        ],
        activePlayersCount: 2,
        status: BookingStatus.incomplete,
        calendlyUri: 'https://api.calendly.com/scheduled_events/example_002',
        metadata: BookingMetadata(
          createdAt: now.millisecondsSinceEpoch - 172800000,
          updatedAt: now.millisecondsSinceEpoch - 3600000,
          createdBy: 'user_005',
        ),
      ),

      // Reserva COMPLETA - Cancha PLAIYA
      Booking(
        id: 'booking_003',
        courtId: 'court_3',
        court: 3,
        dateTime: BookingDateTime(
          day: now.day,
          month: _getMonthAbbreviation(now.month),
          date: _formatDate(now),
          time: '16:30',
          timestamp: _getTimestampForTime(now, '16:30'),
        ),
        players: const [
          BookingPlayer(
            id: 'user_009',
            name: 'DIEGO HERRERA',
            email: 'diego.herrera@gmail.com',
            isMainBooker: true,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_010',
            name: 'VALENTINA TORRES',
            email: 'valentina.torres@hotmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_011',
            name: 'MATIAS FERNANDEZ',
            email: 'matias.fernandez@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_012',
            name: 'ISIDORA CASTRO',
            email: 'isidora.castro@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
        ],
        activePlayersCount: 4,
        status: BookingStatus.complete,
        calendlyUri: 'https://api.calendly.com/scheduled_events/example_003',
        metadata: BookingMetadata(
          createdAt: now.millisecondsSinceEpoch - 259200000,
          updatedAt: now.millisecondsSinceEpoch,
          createdBy: 'user_009',
        ),
      ),

      // Reserva COMPLETA - Cancha PITE (otro horario)
      Booking(
        id: 'booking_004',
        courtId: 'court_1',
        court: 1,
        dateTime: BookingDateTime(
          day: now.day,
          month: _getMonthAbbreviation(now.month),
          date: _formatDate(now),
          time: '18:00',
          timestamp: _getTimestampForTime(now, '18:00'),
        ),
        players: const [
          BookingPlayer(
            id: 'user_013',
            name: 'ROBERTO SILVA',
            email: 'roberto.silva@gmail.com',
            isMainBooker: true,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_014',
            name: 'CARMEN LOPEZ',
            email: 'carmen.lopez@hotmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_015',
            name: 'ANDRES MORALES',
            email: 'andres.morales@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
          BookingPlayer(
            id: 'user_016',
            name: 'PATRICIA VEGA',
            email: 'patricia.vega@gmail.com',
            isMainBooker: false,
            status: PlayerStatus.confirmed,
          ),
        ],
        activePlayersCount: 4,
        status: BookingStatus.complete,
        calendlyUri: 'https://api.calendly.com/scheduled_events/example_004',
        metadata: BookingMetadata(
          createdAt: now.millisecondsSinceEpoch - 86400000,
          updatedAt: now.millisecondsSinceEpoch,
          createdBy: 'user_013',
        ),
      ),
    ];
  }

  // Datos mock de canchas según documento
  static List<Court> get mockCourts {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return [
      Court(
        id: 'court_1',
        number: 1,
        name: 'PITE',
        status: CourtStatus.active,
        metadata: CourtMetadata(
          createdAt: now - 31536000000,
          updatedAt: now,
        ),
      ),
      Court(
        id: 'court_2',
        number: 2,
        name: 'LILEN',
        status: CourtStatus.active,
        metadata: CourtMetadata(
          createdAt: now - 31536000000,
          updatedAt: now,
        ),
      ),
      Court(
        id: 'court_3',
        number: 3,
        name: 'PLAIYA',
        status: CourtStatus.active,
        metadata: CourtMetadata(
          createdAt: now - 31536000000,
          updatedAt: now,
        ),
      ),
    ];
  }

  // Horarios disponibles según documento
  static List<String> get availableTimeSlots => [
    '09:00', '10:30', '12:00', '13:30', 
    '15:00', '16:30', '18:00', '19:30'
  ];

  // Métodos auxiliares
  static String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static int _getTimestampForTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
    return dateTime.millisecondsSinceEpoch;
  }

  // Método para obtener reservas por fecha y cancha
  static List<Booking> getBookingsForDateAndCourt(DateTime date, String courtId) {
    final formattedDate = _formatDate(date);
    
    return mockBookings.where((booking) {
      return booking.dateTime.date == formattedDate && booking.courtId == courtId;
    }).toList();
  }

  // Método para obtener cancha por ID
  static Court? getCourtById(String courtId) {
    try {
      return mockCourts.firstWhere((court) => court.id == courtId);
    } catch (e) {
      return null;
    }
  }

  // Método para obtener cancha por nombre
  static Court? getCourtByName(String name) {
    try {
      return mockCourts.firstWhere((court) => court.name == name);
    } catch (e) {
      return null;
    }
  }
}