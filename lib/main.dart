// lib/main.dart - CONFIGURACIÓN MULTI-DEPORTE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/pages/common/sport_selector_page.dart';
import 'presentation/pages/reservations_page.dart';
import 'core/services/user_service.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con tu configuración real
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDdXsf0ZxA8IS7GD9pDAnAwkJF0sq6YVRE",
      authDomain: "cgpreservas.firebaseapp.com",
      projectId: "cgpreservas",
      storageBucket: "cgpreservas.firebasestorage.app",
      messagingSenderId: "577498054078",
      appId: "1:577498054078:web:fb7b12b9e355065d3d0def",
    ),
  );
  print('🔥 Firebase inicializado correctamente para proyecto: cgpreservas');
  
  // 🔥 NUEVO: Inicializar usuario desde URL
  await UserService.initializeFromUrl();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'CGP Reservas - Multi-Deporte',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display',
        ),
        // Routing simple
        initialRoute: '/',
        routes: {
          '/': (context) => const SportSelectorPage(),
          '/padel': (context) => const ReservationsPage(),
          '/selector': (context) => const SportSelectorPage(),
        },
        // Manejar rutas no encontradas
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const SportSelectorPage(),
          );
        },
      ),
    );
  }
}