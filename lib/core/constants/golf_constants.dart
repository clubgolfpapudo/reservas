// lib/core/constants/golf_constants.dart
// Golf-specific constants for Club de Golf Papudo
class GolfConstants {
  // Sport identification
  static const String SPORT_NAME = 'Golf';
  static const String SPORT_ID = 'golf';

  // Tee configuration
  static const List<String> teeNames = [
    'Hoyo 1',
    'Hoyo 10'
  ];

  static const List<String> COURT_IDS = [
    'golf_tee_1',
    'golf_tee_10'
  ];

  // Colors for tees
  static const Map<String, int> teeColors = {
    'golf_tee_1': 0xFF4CAF50,  // Verde
    'golf_tee_10': 0xFF66BB6A, // Verde claro
  };

  // Scheduling - Golf specific (every 12 minutes)
  static const String START_TIME = "08:00";
  static const String END_TIME_WINTER = "16:00";
  static const String END_TIME_SUMMER = "17:00";
  static const int SLOT_DURATION_MINUTES = 12;

  // Player configuration
  static const int maxPlayersPerBooking = 4;
  static const int MIN_PLAYERS_PER_BOOKING = 1;

  // Booking horizon (48 hours vs 72 for tennis/paddle)
  static const int BOOKING_HORIZON_HOURS = 48;

  // Hoyo 10 suspension times
  static const String SUSPENSION_START = "10:12";
  static const String SUSPENSION_END = "12:48";

  // Generate time slots based on season
  static List<String> getTimeSlots({bool isSummer = false}) {
    final endTime = isSummer ? END_TIME_SUMMER : END_TIME_WINTER;
    final List<String> slots = [];

    DateTime current = DateTime.parse('2024-01-01 $START_TIME:00');
    final end = DateTime.parse('2024-01-01 $endTime:00');

    while (current.isBefore(end)) {
      final timeString = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
      slots.add(timeString);
      current = current.add(Duration(minutes: SLOT_DURATION_MINUTES));
    }

    return slots;
  }

  // Season detection (simplified)
  static bool get isSummer {
    final now = DateTime.now();
    final month = now.month;
    return month >= 10 || month <= 3; // October to March (Southern hemisphere summer)
  }

  // Check if Hoyo 10 is suspended at given time
  static bool isHoyo10Suspended(String timeSlot) {
    final time = DateTime.parse('2024-01-01 $timeSlot:00');
    final suspensionStart = DateTime.parse('2024-01-01 $SUSPENSION_START:00');
    final suspensionEnd = DateTime.parse('2024-01-01 $SUSPENSION_END:00');
    
    return time.isAtSameMomentAs(suspensionStart) || 
           time.isAtSameMomentAs(suspensionEnd) ||
           (time.isAfter(suspensionStart) && time.isBefore(suspensionEnd));
  }

  // Default time slots for current season
  static List<String> get DEFAULT_TIME_SLOTS => getTimeSlots(isSummer: isSummer);

  // Firebase collection names (golf-specific)
  static const String BOOKINGS_COLLECTION = 'golf_bookings';
  static const String COURTS_COLLECTION = 'golf_tees';
}