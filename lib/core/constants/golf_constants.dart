// lib/core/constants/golf_constants.dart
// Golf-specific constants for Club de Golf Papudo
class GolfConstants {
  // Sport identification
  static const String SPORT_NAME = 'Golf';
  static const String SPORT_ID = 'golf';
  
  // Tee configuration
  static const List<String> teeNames = [
    'Tee 1',
    'Tee 10'
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
  static const String START_TIME = "8:00";
  static const String END_TIME_WINTER = "16:00";   
  static const String END_TIME_SUMMER = "17:00";   
  static const int SLOT_DURATION_MINUTES = 12;
  
  // Player configuration
  static const int maxPlayersPerBooking = 4;
  static const int MIN_PLAYERS_PER_BOOKING = 1;
  
  // Default time slots - every 12 minutes
  static const List<String> defaultTimeSlots = [
    "08:00", "08:12", "08:24", "08:36", "08:48",
    "09:00", "09:12", "09:24", "09:36", "09:48",
    "10:00", "10:12", "10:24", "10:36", "10:48",
    "11:00", "11:12", "11:24", "11:36", "11:48",
    "12:00", "12:12", "12:24", "12:36", "12:48",
    "13:00", "13:12", "13:24", "13:36", "13:48",
    "14:00", "14:12", "14:24", "14:36", "14:48",
    "15:00", "15:12", "15:24", "15:36", "15:48",
  ];
  
  // Firebase collections
  static const String BOOKINGS_COLLECTION = 'golf_bookings';
  static const String COURTS_COLLECTION = 'golf_tees';
}