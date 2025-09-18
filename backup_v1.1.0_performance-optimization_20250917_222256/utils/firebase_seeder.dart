// ============================================================================
// ARCHIVO 2: lib/utils/firebase_seeder.dart (CREAR ESTE ARCHIVO)
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> seedData() async {
    try {
      print('🌱 Iniciando seed de datos...');
      
      // Verificar si ya existen datos
      final courtsSnapshot = await _firestore.collection('courts').limit(1).get();
      if (courtsSnapshot.docs.isNotEmpty) {
        print('✅ Datos ya existen, omitiendo seed');
        return;
      }
      
      await _createCourts();
      await _createBookings();
      
      print('✅ Datos poblados exitosamente');
    } catch (e) {
      print('❌ Error poblando datos: $e');
    }
  }
  
  static Future<void> _createCourts() async {
    final courts = [
      // PÁDEL
      {
        'name': 'PITE',
        'description': 'Cancha PITE',
        'number': 1,
        'displayOrder': 1,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'LILEN',
        'description': 'Cancha LILEN',
        'number': 2,
        'displayOrder': 2,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'PLAIYA', 
        'description': 'Cancha PLAIYA',
        'number': 3,
        'displayOrder': 3,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // TENIS
      {
        'name': 'CANCHA_1',
        'description': 'Cancha de Tenis 1',
        'number': 4,
        'displayOrder': 4,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'CANCHA_2',
        'description': 'Cancha de Tenis 2',
        'number': 5,
        'displayOrder': 5,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'CANCHA_3',
        'description': 'Cancha de Tenis 3',
        'number': 6,
        'displayOrder': 6,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'CANCHA_4',
        'description': 'Cancha de Tenis 4',
        'number': 7,
        'displayOrder': 7,
        'status': 'active',
        'isAvailableForBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    // Crear todas las canchas
    await _firestore.collection('courts').doc('padel_court_1').set(courts[0]);
    await _firestore.collection('courts').doc('padel_court_2').set(courts[1]);
    await _firestore.collection('courts').doc('padel_court_3').set(courts[2]);
    await _firestore.collection('courts').doc('tennis_court_1').set(courts[3]);
    await _firestore.collection('courts').doc('tennis_court_2').set(courts[4]);
    await _firestore.collection('courts').doc('tennis_court_3').set(courts[5]);
    await _firestore.collection('courts').doc('tennis_court_4').set(courts[6]);
    
    print('✅ Canchas creadas');
  }
  
  static Future<void> _createBookings() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final bookings = [
      // PITE - Reservas completas
      {
        'courtId': 'padel_court_1',
        'date': dateStr,
        'timeSlot': '09:00',
        'players': [
          {'name': 'MARIA LOPEZ', 'phone': '+56912345678', 'isConfirmed': true},
          {'name': 'JAVIER REAS', 'phone': '+56912345679', 'isConfirmed': true},
          {'name': 'ALVARO BECKER', 'phone': '+56912345680', 'isConfirmed': true},
          {'name': 'LUCIA GOMEZ', 'phone': '+56912345681', 'isConfirmed': true}
        ],
        'status': 'complete',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'courtId': 'padel_court_1',
        'date': dateStr,
        'timeSlot': '18:00',
        'players': [
          {'name': 'ROBERTO SILVA', 'phone': '+56912345682', 'isConfirmed': true},
          {'name': 'CARMEN LOPEZ', 'phone': '+56912345683', 'isConfirmed': true},
          {'name': 'ANDRES MORALES', 'phone': '+56912345684', 'isConfirmed': true},
          {'name': 'PATRICIA VEGA', 'phone': '+56912345685', 'isConfirmed': true}
        ],
        'status': 'complete',
        'createdAt': FieldValue.serverTimestamp(),
      },
      // LILEN - Reserva incompleta
      {
        'courtId': 'padel_court_2',
        'date': dateStr,
        'timeSlot': '12:00',
        'players': [
          {'name': 'CARLOS MARTINEZ', 'phone': '+56912345686', 'isConfirmed': true},
          {'name': 'ANA SILVA', 'phone': '+56912345687', 'isConfirmed': true}
        ],
        'status': 'incomplete',
        'createdAt': FieldValue.serverTimestamp(),
      },
      // PLAIYA - Reserva completa
      {
        'courtId': 'padel_court_3',
        'date': dateStr,
        'timeSlot': '16:30',
        'players': [
          {'name': 'DIEGO HERRERA', 'phone': '+56912345688', 'isConfirmed': true},
          {'name': 'VALENTINA TORRES', 'phone': '+56912345689', 'isConfirmed': true},
          {'name': 'MATIAS FERNANDEZ', 'phone': '+56912345690', 'isConfirmed': true},
          {'name': 'ISIDORA CASTRO', 'phone': '+56912345691', 'isConfirmed': true}
        ],
        'status': 'complete',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    for (var bookingData in bookings) {
      await _firestore.collection('bookings').add(bookingData);
    }
    
    print('✅ Reservas creadas');
  }
}