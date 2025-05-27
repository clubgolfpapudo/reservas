// lib/main.dart - CONFIGURACIÓN REAL DE FIREBASE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Pages
import 'presentation/pages/reservations_page.dart';

// Providers
import 'presentation/providers/booking_provider.dart';

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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'CGP Reservas',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const ReservationsPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}