// lib/main.dart - COMPATIBLE CON AUTHPROVIDER REAL
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Core
import 'core/theme/corporate_theme.dart';
import 'core/constants/app_constants.dart';

// Providers
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/providers/user_provider.dart';

// Pages
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/home/home_page.dart';  // ← RUTA CORREGIDA
import 'presentation/pages/reservations_page.dart';
import 'presentation/pages/tennis_reservations_page.dart';

// Firebase
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación (solo portrait para móviles)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar status bar con colores corporativos
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: CorporateTheme.backgroundLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar localización en español
  await initializeDateFormatting('es_ES', null);
  
  runApp(const CGPReservasApp());
}

class CGPReservasApp extends StatelessWidget {
  const CGPReservasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.clubName,
        debugShowCheckedModeBanner: false,
        
        // ✅ TEMA CORPORATIVO INTEGRADO
        theme: CorporateTheme.corporateTheme,
        
        // Configuración de localización
        locale: const Locale('es', 'ES'),
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        
        // Rutas de la aplicación
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/padel': (context) => const ReservationsPage(),
          '/tenis': (context) => const TennisReservationsPage(),
          // '/golf': (context) => const GolfReservationsPage(), // Para futura implementación
        },
        
        // Builder para manejar errores globales
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Evitar escalado automático de texto
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

// ✅ WRAPPER DE AUTENTICACIÓN - USANDO MÉTODOS REALES DE AUTHPROVIDER
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Verificar auto-login al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar splash screen mientras carga
        if (authProvider.isLoading) {
          return const CorporateSplashScreen();
        }
        
        // ✅ USANDO MÉTODO REAL: isUserValidated
        if (authProvider.isUserValidated) {
          return const HomePage();
        }
        
        // Si no está validado, mostrar login
        return const LoginPage();
      },
    );
  }
}

// ✅ SPLASH SCREEN CORPORATIVO
class CorporateSplashScreen extends StatefulWidget {
  const CorporateSplashScreen({super.key});

  @override
  State<CorporateSplashScreen> createState() => _CorporateSplashScreenState();
}

class _CorporateSplashScreenState extends State<CorporateSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: CorporateTheme.primaryGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo del club
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: CorporateTheme.elevatedShadow,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/club_logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: CorporateTheme.goldGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.golf_course,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Nombre del club
                      Text(
                        AppConstants.clubName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Año de fundación
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'FUNDADO EN ${AppConstants.clubYear}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtítulo
                      Text(
                        AppConstants.systemTitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Indicador de carga
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            CorporateTheme.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}