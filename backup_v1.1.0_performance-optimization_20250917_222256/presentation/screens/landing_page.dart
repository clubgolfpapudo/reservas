// lib/presentation/screens/landing_page.dart
// CAMBIO CRÍTICO: Activar Golf de "coming soon" a funcional

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Existing header code...
      
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green[50]!, Colors.white],
            ),
          ),
          child: Column(
            children: [
              // Existing header section...
              
              // ✅ SECCIÓN DEPORTES - Golf ahora funcional
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'Selecciona tu Deporte',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Reserva tu cancha de manera fácil y rápida',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      
                      // Sports Cards
                      Expanded(
                        child: ListView(
                          children: [
                            // ✅ GOLF CARD - AHORA FUNCIONAL
                            SportCard(
                              sportType: SportType.golf,
                              title: 'Golf',
                              description: 'Campo de golf de 18 hoyos, par 68',
                              icon: Icons.golf_course,
                              isComingSoon: false, // ← CAMBIO CRÍTICO: false
                              gradient: LinearGradient(
                                colors: [Color(0xFF7CB342), Color(0xFF689F38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => _navigateToSport(context, SportType.golf),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // ✅ PÁDEL CARD - Mantener existente
                            SportCard(
                              sportType: SportType.padel,
                              title: 'Pádel',
                              description: '3 canchas disponibles con iluminación',
                              icon: Icons.sports_handball,
                              isComingSoon: false,
                              gradient: LinearGradient(
                                colors: [Color(0xFF2E7AFF), Color(0xFF1E5AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => _navigateToSport(context, SportType.padel),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // ✅ TENIS CARD - Mantener existente  
                            SportCard(
                              sportType: SportType.tennis,
                              title: 'Tenis',
                              description: '4 canchas de tierra batida profesional',
                              icon: Icons.sports_tennis,
                              isComingSoon: false,
                              gradient: LinearGradient(
                                colors: [Color(0xFFD2691E), Color(0xFFB8860B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () => _navigateToSport(context, SportType.tennis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ✅ NAVEGACIÓN GOLF - Agregar case para golf
  void _navigateToSport(BuildContext context, SportType sportType) {
    switch (sportType) {
      case SportType.golf:
        // ✅ NAVEGACIÓN A GOLF
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationScreen(sportType: SportType.golf),
          ),
        );
        break;
      case SportType.padel:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationScreen(sportType: SportType.padel),
          ),
        );
        break;
      case SportType.tennis:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationScreen(sportType: SportType.tennis),
          ),
        );
        break;
    }
  }
}

// ✅ SPORT CARD - Asegurar compatibilidad Golf
class SportCard extends StatelessWidget {
  final SportType sportType;
  final String title;
  final String description;
  final IconData icon;
  final bool isComingSoon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  
  const SportCard({
    Key? key,
    required this.sportType,
    required this.title,
    required this.description,
    required this.icon,
    this.isComingSoon = false,
    required this.gradient,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isComingSoon ? null : onTap,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(width: 20),
                
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título con badge "Próximamente" si corresponde
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isComingSoon) ...[
                            SizedBox(width: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Próximamente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Descripción
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Flecha o icono próximamente
                Icon(
                  isComingSoon ? Icons.schedule : Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}