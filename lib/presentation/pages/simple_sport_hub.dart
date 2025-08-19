// lib/presentation/pages/simple_sport_hub.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SimpleSportHub extends StatelessWidget {
  const SimpleSportHub({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🚨 DEBUG: Para confirmar que este archivo se está ejecutando
    print("🔥🔥🔥 EJECUTANDO SIMPLE_SPORT_HUB.DART - VERSIÓN ACTUALIZADA");
    print("🔥🔥🔥 ORDEN CORRECTO: 1️⃣Golf → 2️⃣Pádel → 3️⃣Tenis");
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B365D),
        elevation: 0,
        title: Row(
          children: [
            // Logo oficial del club en header
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/club_logo.png',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.sports_golf,
                      color: Color(0xFF1B365D),
                      size: 25,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Club de Golf Papudo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con logo y bienvenida
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B365D), Color(0xFF2E5984)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo principal
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/club_logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.sports_golf,
                            color: Color(0xFF1B365D),
                            size: 40,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Título
                  const Text(
                    'Selecciona tu deporte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                ],
              ),
            ),

            // 🔥🔥🔥 CARDS DE DEPORTES - ORDEN HARDCODEADO DIRECTAMENTE
            // NO USAR FUNCIONES NI LISTAS - ORDEN FIJO
            
            // 🏌️ GOLF - PRIMER DEPORTE (POSICIÓN 1)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    print("🏌️ TAP EN GOLF - PRIMER DEPORTE");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🏌️ Golf - Próximamente disponible'),
                        backgroundColor: Color(0xFF7CB342),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icono Golf
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7CB342).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.golf_course,
                            size: 30,
                            color: Color(0xFF7CB342),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Info Golf
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Golf',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7CB342),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Campo de golf de 18 hoyos, par 68',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Flecha Golf
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Color(0xFF7CB342),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 🏓 PÁDEL - SEGUNDO DEPORTE (POSICIÓN 2)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    print("🏓 TAP EN PÁDEL - SEGUNDO DEPORTE");
                    Navigator.pushNamed(context, '/reservations');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icono Pádel
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7AFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_handball, // Más parecido a pádel (raqueta con agujeros)
                            size: 30,
                            color: Color(0xFF2E7AFF),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Info Pádel
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pádel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7AFF),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tres canchas profesionales',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Flecha Pádel
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Color(0xFF2E7AFF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 🎾 TENIS - TERCER DEPORTE (POSICIÓN 3)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    print("🎾 TAP EN TENIS - TERCER DEPORTE");
                    Navigator.pushNamed(context, '/tennis-reservations');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icono Tenis
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2691E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_baseball,
                            size: 30,
                            color: Color(0xFFD2691E),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Info Tenis
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tenis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD2691E),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cuatro canchas de tierra batida',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Flecha Tenis
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Color(0xFFD2691E),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Footer con logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo pequeño en footer
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1B365D).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/club_logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.sports_golf,
                            color: Color(0xFF1B365D),
                            size: 20,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Club de Golf Papudo',
                        style: TextStyle(
                          color: Color(0xFF1B365D),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Sistema de Reservas',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
}