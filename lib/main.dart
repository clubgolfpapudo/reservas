             // ← Cierre del método build// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'presentation/pages/reservations_page.dart';

// Solo imports básicos que sabemos que existen
import 'presentation/providers/user_provider.dart';

void main() async {
  print("=== INICIANDO MAIN ===");
  
  // Asegurar que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  print("=== WIDGETS INITIALIZED ===");

  // Configurar orientación de pantalla (solo portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  print("=== ORIENTACION CONFIGURADA ===");

  // Configurar barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  print("=== UI OVERLAY CONFIGURADO ===");

  print("=== EJECUTANDO APP PRINCIPAL ===");
  // Ejecutar la aplicación
  runApp(const MyApp());
}

/// Aplicación principal
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Versión simple sin providers complejos por ahora
    return MaterialApp(
      title: 'CGP Reservas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Página principal de la aplicación
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        title: const Text(
          'CGP Reservas - Reparando Errores',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(  // ← Agregar esto
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Logo o icono de la app
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sports_tennis,
                  size: 60,
                  color: Colors.blue.shade600,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Título de bienvenida
              Text(
                '✅ ¡App Funcionando!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              
              Text(
                'Versión básica mientras reparamos errores',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Información de desarrollo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '🔧 Reparando Componentes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Esta versión básica funciona mientras reparamos:\n'
                      '• UserProvider imports\n'
                      '• CourtRepository errores\n'
                      '• Theme compatibility\n'
                      '• Injection container',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Estado de reparaciones
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Main.dart: FUNCIONANDO',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botones de acción
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Navegar a la página de reservas
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const ReservationsPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.sports_tennis),
                                  label: Text('Ver Reservas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                
                                ElevatedButton.icon(
                                  onPressed: _incrementCounter,
                                  icon: const Icon(Icons.add),
                                  label: Text('Test: +$_counter'), // ← Sin 'const' porque usa variable
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],  // ← AGREGAR ESTAS LÍNEAS DESDE AQUÍ
                        ),    // ← Cierre del Column
                      ),      // ← Cierre del Padding
                    ),        // ← Cierre del Center
                  ),          // ← Cierre del SingleChildScrollView
                );            // ← Cierre del Scaffold
              }               // ← Cierre del método build
            }                 // ← Cierre de la clase _HomePageState