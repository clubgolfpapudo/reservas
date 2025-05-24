// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Repositories
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/court_repository.dart';

// Repository Implementations
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/court_repository_impl.dart';

// Providers
import '../../presentation/providers/app_provider.dart';
import '../../presentation/providers/user_provider.dart';
import '../../presentation/providers/booking_provider.dart';

/// Contenedor de inyección de dependencias
final GetIt sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicación
Future<void> initializeDependencies() async {
  // ═══════════════════════════════════════════════════════════════════════════
  // EXTERNAL DEPENDENCIES
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Firebase Firestore
  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA SOURCES
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Por ahora no tenemos data sources separados, los repositorios se conectan
  // directamente a Firebase

  // ═══════════════════════════════════════════════════════════════════════════
  // REPOSITORIES
  // ═══════════════════════════════════════════════════════════════════════════
  
  // User Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(firestore: sl()),
  );

  // Booking Repository
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(firestore: sl()),
  );

  // Court Repository
  sl.registerLazySingleton<CourtRepository>(
    () => CourtRepositoryImpl(firestore: sl()),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // USE CASES
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Por ahora trabajamos directamente con repositorios desde los providers
  // En el futuro podríamos agregar use cases aquí

  // ═══════════════════════════════════════════════════════════════════════════
  // PROVIDERS (State Management)
  // ═══════════════════════════════════════════════════════════════════════════
  
  // App Provider - Estado global de la aplicación
  sl.registerLazySingleton<AppProvider>(
    () => AppProvider(),
  );

  // User Provider - Gestión de usuarios y autenticación
  sl.registerLazySingleton<UserProvider>(
    () => UserProvider(
      userRepository: sl(),
    ),
  );

  // Booking Provider - Gestión de reservas
  sl.registerLazySingleton<BookingProvider>(
    () => BookingProvider(
      bookingRepository: sl(),
      courtRepository: sl(),
    ),
  );
}

/// Resetea todas las dependencias (útil para testing)
Future<void> resetDependencies() async {
  await sl.reset();
}

/// Verifica que todas las dependencias estén registradas correctamente
void validateDependencies() {
  // Verificar repositorios
  assert(sl.isRegistered<UserRepository>(), 'UserRepository not registered');
  assert(sl.isRegistered<BookingRepository>(), 'BookingRepository not registered');
  assert(sl.isRegistered<CourtRepository>(), 'CourtRepository not registered');
  
  // Verificar providers
  assert(sl.isRegistered<AppProvider>(), 'AppProvider not registered');
  assert(sl.isRegistered<UserProvider>(), 'UserProvider not registered');
  assert(sl.isRegistered<BookingProvider>(), 'BookingProvider not registered');
  
  print('✅ Todas las dependencias están registradas correctamente');
}

// ═══════════════════════════════════════════════════════════════════════════════
// MÉTODOS DE ACCESO RÁPIDO
// ═══════════════════════════════════════════════════════════════════════════════

/// Acceso rápido a repositorios
class Repositories {
  static UserRepository get user => sl<UserRepository>();
  static BookingRepository get booking => sl<BookingRepository>();
  static CourtRepository get court => sl<CourtRepository>();
}

/// Acceso rápido a providers
class Providers {
  static AppProvider get app => sl<AppProvider>();
  static UserProvider get user => sl<UserProvider>();
  static BookingProvider get booking => sl<BookingProvider>();
}

/// Acceso rápido a servicios externos
class ExternalServices {
  static FirebaseFirestore get firestore => sl<FirebaseFirestore>();
}