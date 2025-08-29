// lib/presentation/pages/simple_sport_hub.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/admin/presentation/widgets/admin_menu_button.dart';

class SimpleSportHub extends StatefulWidget {
  const SimpleSportHub({Key? key}) : super(key: key);

  @override
  State<SimpleSportHub> createState() => _SimpleSportHubState();
}

class _SimpleSportHubState extends State<SimpleSportHub> {
  
  @override
  void initState() {
    super.initState();
    
    // 🔐 Verificar estado admin después de inicializar
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAdminStatus();
    });
  }

  // 🔐 Verificar estado de administrador
  void _checkAdminStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    print('🔍 DEBUG: Email actual: ${authProvider.currentUserEmail}');
    print('🔍 DEBUG: Es autenticado: ${authProvider.isUserValidated}');
    
    if (authProvider.isUserValidated) {
      adminProvider.checkAdminStatus(authProvider.currentUserEmail);
      print('🔍 DEBUG: Es admin: ${adminProvider.isAdmin}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 DEBUG: Para confirmar que este archivo se está ejecutando
    print("🔥🔥🔥 EJECUTANDO SIMPLE_SPORT_HUB.DART - VERSIÓN CON ADMIN");
    print("🔥🔥🔥 ORDEN CORRECTO: 1️⃣Golf → 2️⃣Pádel → 3️⃣Tenis");
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AppBar personalizado con menú admin
            _buildCustomAppBar(),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header con logo y bienvenida
                  _buildWelcomeHeader(),
                  
                  const SizedBox(height: 30),
                  
                  // Cards de deportes
                  _buildSportsCards(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B365D), Color(0xFF2E5984)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(
            children: [
              // Contenido principal del AppBar
              Row(
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
                  const Expanded(
                    child: Text(
                      'Club de Golf Papudo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // 🔐 BOTÓN ADMIN
                  const AdminMenuButton(
                    showBadge: true,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    fontSize: 12,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 🍔 NUEVO: MENÚ HAMBURGUESA
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _showMainMenu(context),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
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
          // Solo el mensaje de bienvenida personalizado
          Consumer2<AuthProvider, AdminProvider>(
            builder: (context, authProvider, adminProvider, child) {
              String welcomeMessage;
              
              if (authProvider.isUserValidated) {
                if (adminProvider.isAdmin) {
                  welcomeMessage = 'Hola Admin, ${authProvider.currentUserName ?? "Usuario"}';
                } else {
                  welcomeMessage = 'Hola, ${authProvider.currentUserName ?? "Usuario"}';
                }
              } else {
                welcomeMessage = 'Selecciona tu deporte favorito';
              }
              
              return Text(
                welcomeMessage,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,  // ← Aumenté un poco el tamaño ya que es el único texto
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSportsCards() {
    return Column(
      children: [
        // 🏌️ GOLF - PRIMER DEPORTE (POSICIÓN 1)
        _buildSportCard(
          title: 'Golf',
          description: 'Campo de golf de 18 hoyos, par 68',
          icon: Icons.golf_course,
          color: const Color(0xFF7CB342),
          onTap: () {
            print("🏌️ TAP EN GOLF - PRIMER DEPORTE");
            Navigator.pushNamed(context, '/golf-reservations');
          },
        ),
        
        const SizedBox(height: 16),
        
        // 🏓 PÁDEL - SEGUNDO DEPORTE (POSICIÓN 2)
        _buildSportCard(
          title: 'Pádel',
          description: 'Tres canchas profesionales',
          icon: Icons.sports_handball,
          color: const Color(0xFF2E7AFF),
          onTap: () {
            print("🏓 TAP EN PÁDEL - SEGUNDO DEPORTE");
            Navigator.pushNamed(context, '/paddle-reservations');
          },
        ),
        
        const SizedBox(height: 16),
        
        // 🎾 TENIS - TERCER DEPORTE (POSICIÓN 3)
        _buildSportCard(
          title: 'Tenis',
          description: 'Cuatro canchas de arcilla',
          icon: Icons.sports_tennis,
          color: const Color(0xFFD2691E),
          onTap: () {
            print("🎾 TAP EN TENIS - TERCER DEPORTE");
            Navigator.pushNamed(context, '/tennis-reservations');
          },
        ),
      ],
    );
  }

  Widget _buildSportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📱 Footer de navegación (igual que el anterior)
  Widget _buildFooterNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // o BouncingScrollPhysics si prefieres scroll interno
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: _buildFooterButtons(),
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildFooterButtons(),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFooterButtons() {
    return [
      _buildFooterButton(
        title: 'Mis Reservas',
        icon: Icons.calendar_today,
        onTap: () => _showComingSoonModal('Mis Reservas'),
      ),
      _buildFooterButton(
        title: 'Mi Perfil',
        icon: Icons.person,
        onTap: () => _showComingSoonModal('Mi Perfil'),
      ),
      _buildFooterButton(
        title: 'Historial',
        icon: Icons.history,
        onTap: () => _showComingSoonModal('Historial'),
      ),
      _buildFooterButton(
        title: 'Noticias',
        icon: Icons.article,
        onTap: () => _showComingSoonModal('Noticias'),
      ),
      _buildFooterButton(
        title: 'Avisos',
        icon: Icons.notifications,
        onTap: () => _showComingSoonModal('Avisos'),
      ),
    ];
  }

  Widget _buildFooterButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE9ECEF),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF666666),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 📱 Modal para funciones del footer
  void _showComingSoonModal(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            feature,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          content: const Text(
            'Próximamente disponible',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2E7AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showMainMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ Permite que el modal use más altura si es necesario
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: MediaQuery.of(context).viewInsets, // ✅ Respeta teclado si está activo
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Opciones del menú
                  _buildMenuOption(Icons.calendar_today, 'Mis Reservas'),
                  _buildMenuOption(Icons.person, 'Mi Perfil'),
                  _buildMenuOption(Icons.history, 'Historial'),
                  _buildMenuOption(Icons.article, 'Noticias'),
                  _buildMenuOption(Icons.notifications, 'Avisos'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B365D)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        _showComingSoonModal(title);
      },
    );
  }
}