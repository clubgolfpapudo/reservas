// Tennis-specific constants for Club de Golf Papudo
class TennisConstants {
  // Sport identification
  static const String SPORT_NAME = 'Tenis';
  static const String SPORT_ID = 'tennis';

  // Court configuration
  static const List<String> COURT_NAMES = [
    'Cancha 1',
    'Cancha 2', 
    'Cancha 3',
    'Cancha 4'
  ];

  static const List<String> COURT_IDS = [
    'tennis_court_1',
    'tennis_court_2',
    'tennis_court_3', 
    'tennis_court_4'
  ];

  // Scheduling
  static const String START_TIME = "8:30";
  static const String END_TIME_WINTER = "16:00";   // 6 time slots
  static const String END_TIME_SUMMER = "19:00";   // 8 time slots
  static const int SLOT_DURATION_MINUTES = 90;
  
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

  // Player configuration
  static const int MAX_PLAYERS_PER_BOOKING = 4;
  static const int MIN_PLAYERS_PER_BOOKING = 2;

  // Default time slots for current season
  static List<String> get DEFAULT_TIME_SLOTS => getTimeSlots(isSummer: isSummer);
  
  // Firebase collection names (tennis-specific)
  static const String BOOKINGS_COLLECTION = 'tennis_bookings';
  static const String COURTS_COLLECTION = 'tennis_courts';
}