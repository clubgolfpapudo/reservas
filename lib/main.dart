// ============================================================================
// lib/main.dart - LIMPIAR Y REEMPLAZAR COMPLETAMENTE
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Providers
import 'presentation/providers/booking_provider.dart';
import 'presentation/providers/user_provider.dart';

// Pages
import 'presentation/pages/reservations_page.dart'; // Cambiado a reservations_page

// Utils
import 'utils/firebase_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("🔥 Inicializando Firebase...");
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print("✅ Firebase inicializado correctamente");
  
  // Poblar datos iniciales (descomenta solo la primera vez)
  // await FirebaseSeeder.seedData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'CGP Reservas',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        home: const ReservationsPage(), // Directo a reservas
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}