// lib/presentation/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../pages/home/home_page.dart';
import '../providers/user_provider.dart';
import '../../core/constants/app_constants.dart';

/// Configuración del sistema de navegación de la aplicación
class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: RouteConstants.home,
    routes: [
      // Pantalla principal
      GoRoute(
        path: RouteConstants.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      
      // Pantalla de selección de fecha (placeholder)
      GoRoute(
        path: RouteConstants.dateSelection,
        name: 'dateSelection',
        builder: (context, state) => const DateSelectionPage(),
      ),
      
      // Pantalla de perfil (placeholder)
      GoRoute(
        path: RouteConstants.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      
      // WebView de reserva (placeholder)
      GoRoute(
        path: RouteConstants.bookingWebView,
        name: 'bookingWebView',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingWebViewPage(
            courtName: extra?['courtName'] ?? '',
            date: extra?['date'] ?? DateTime.now(),
            time: extra?['time'] ?? '',
          );
        },
      ),
    ],
    redirect: (context, state) {
      // Lógica de redirección si es necesaria
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Por ahora no implementamos autenticación obligatoria
      // En el futuro podríamos redirigir a login si no está autenticado
      
      return null; // No redirigir
    },
    errorBuilder: (context, state) => ErrorPage(error: state.error.toString()),
  );

  static GoRouter get router => _router;

  // Métodos de navegación helpers
  static void goHome(BuildContext context) {
    context.go(RouteConstants.home);
  }

  static void goToDateSelection(BuildContext context) {
    context.go(RouteConstants.dateSelection);
  }

  static void goToProfile(BuildContext context) {
    context.go(RouteConstants.profile);
  }

  static void goToBookingWebView(
    BuildContext context, {
    required String courtName,
    required DateTime date,
    required String time,
  }) {
    context.go(
      RouteConstants.bookingWebView,
      extra: {
        'courtName': courtName,
        'date': date,
        'time': time,
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PÁGINAS PLACEHOLDER (para implementar en el futuro)
// ═══════════════════════════════════════════════════════════════════════════════

/// Página de selección de fecha (placeholder)
class DateSelectionPage extends StatelessWidget {
  const DateSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Fecha'),
      ),
      body: const Center(
        child: Text(
          'Página de selección de fecha\n(Por implementar)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// Página de perfil (placeholder)
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (!userProvider.isAuthenticated) {
            return const Center(
              child: Text(
                'No hay usuario autenticado',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final user = userProvider.currentUser!;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información del Usuario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Nombre:', user.name),
                _buildInfoRow('Email:', user.email),
                _buildInfoRow('Teléfono:', user.phone ?? 'No especificado'),
                _buildInfoRow('Categoría:', user.role.displayName),
                _buildInfoRow('Número de Socio:', user.membershipNumber ?? 'N/A'),
                if (user.age != null)
                  _buildInfoRow('Edad:', '${user.age} años'),
                const SizedBox(height: 20),
                Text(
                  'Estadísticas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                _buildInfoRow('Total de reservas:', '${user.stats.totalBookings}'),
                _buildInfoRow('Reservas canceladas:', '${user.stats.cancelledBookings}'),
                if (user.mustPayForReservations)
                  _buildInfoRow('Total pagado:', '\$${user.stats.totalAmountPaid}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Página de WebView para reservas (placeholder)
class BookingWebViewPage extends StatelessWidget {
  final String courtName;
  final DateTime date;
  final String time;

  const BookingWebViewPage({
    Key? key,
    required this.courtName,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservar $courtName'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.web,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'WebView de Reserva',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text('Cancha: $courtName'),
            Text('Fecha: ${date.day}/${date.month}/${date.year}'),
            Text('Hora: $time'),
            const SizedBox(height: 20),
            const Text(
              'Aquí se cargaría el sistema\nde reservas existente (GAS/Calendly)',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simular proceso de reserva exitoso
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reserva simulada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Simular Reserva Exitosa'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de error
class ErrorPage extends StatelessWidget {
  final String error;

  const ErrorPage({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error de Navegación',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(RouteConstants.home),
              child: const Text('Ir al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}