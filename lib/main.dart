// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Core
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Providers
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/booking_provider.dart';

// Router
import 'presentation/router/app_router.dart';

// Widgets
import 'presentation/widgets/common/app_loading_indicator.dart';

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

  try {
    print("=== INICIANDO FIREBASE ===");
    // Inicializar Firebase
    await Firebase.initializeApp(
      // Aquí irían las opciones de Firebase si tienes un archivo de configuración
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    print("=== FIREBASE INICIALIZADO ===");

    // Configurar Firestore para caché offline  
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print("=== FIRESTORE CONFIGURADO ===");

    print("=== INICIANDO DEPENDENCIAS ===");
    // Inicializar inyección de dependencias
    await initializeDependencies();
    print("=== DEPENDENCIAS INICIALIZADAS ===");

    // Validar que todas las dependencias estén registradas
    validateDependencies();
    print("=== DEPENDENCIAS VALIDADAS ===");

    print("=== EJECUTANDO APP PRINCIPAL ===");
    // Ejecutar la aplicación
    runApp(const MyApp());
  } catch (e) {
    print("=== ERROR EN MAIN: $e ===");
    print("=== STACK TRACE: ${StackTrace.current} ===");
    // Si hay error en la inicialización, mostrar app de error
    runApp(ErrorApp(error: e.toString()));
  }
}

/// Aplicación principal
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // App Provider - Estado global
        ChangeNotifierProvider<AppProvider>(
          create: (_) => sl<AppProvider>(),
        ),
        
        // User Provider - Gestión de usuarios
        ChangeNotifierProvider<UserProvider>(
          create: (_) => sl<UserProvider>(),
        ),
        
        // Booking Provider - Gestión de reservas
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => sl<BookingProvider>(),
        ),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp.router(
            // Configuración básica
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            
            // Tema
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            
            // Router
            routerConfig: AppRouter.router,
            
            // Builder para manejar inicialización
            builder: (context, child) {
              return AppInitializer(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}

/// Widget que maneja la inicialización de la aplicación
class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final appProvider = context.read<AppProvider>();
      final userProvider = context.read<UserProvider>();

      // Inicializar app provider
      await appProvider.initializeApp();

      // Verificar estado de autenticación
      await userProvider.checkAuthStatus();

      // Marcar como inicializado
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hay error de inicialización
    if (_initializationError != null) {
      return MaterialApp(
        home: ErrorScreen(
          error: _initializationError!,
          onRetry: () {
            setState(() {
              _initializationError = null;
              _isInitialized = false;
            });
            _initializeApp();
          },
        ),
      );
    }

    // Si no está inicializado, mostrar splash
    if (!_isInitialized) {
      return MaterialApp(
        home: const SplashScreen(),
        theme: AppTheme.lightTheme,
      );
    }

    // App inicializada correctamente
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Verificar modo mantenimiento
        if (appProvider.maintenanceMode) {
          return MaterialApp(
            home: const MaintenanceScreen(),
            theme: AppTheme.lightTheme,
          );
        }

        // Verificar conectividad
        if (!appProvider.isConnected) {
          return Stack(
            children: [
              widget.child,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  color: Colors.red,
                  child: Row(
                    children: const [
                      Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sin conexión a internet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return widget.child;
      },
    );
  }
}

/// Pantalla de splash durante la inicialización
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 60,
                color: AppColors.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Nombre de la app
            Text(
              AppConstants.appName,
              style: AppTextStyles.headline1.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            
            const SizedBox(height: 10),
            
            Text(
              AppConstants.clubName,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Indicador de carga
            const AppLoadingIndicator(
              color: Colors.white,
              showMessage: false,
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Inicializando...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de error durante la inicialización
class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorScreen({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Error de Inicialización',
                style: AppTextStyles.headline2.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'No se pudo inicializar la aplicación correctamente.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de mantenimiento
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.build,
                size: 80,
                color: AppColors.warning,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Mantenimiento',
                style: AppTextStyles.headline1.copyWith(
                  color: AppColors.warning,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'La aplicación está temporalmente en mantenimiento. '
                'Por favor, intenta nuevamente en unos minutos.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              const AppLoadingIndicator(
                color: AppColors.warning,
                message: 'Verificando estado...',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App de error para problemas críticos de inicialización
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error Crítico',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'La aplicación no pudo iniciarse correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}