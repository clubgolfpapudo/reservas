// lib/presentation/pages/sport_selection_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/common/sport_selector.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/corporate_theme.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/admin/presentation/widgets/admin_menu_button.dart';
import 'reservations_page.dart';
import 'tennis_reservations_page.dart';

class SportSelectionPage extends StatefulWidget {
  const SportSelectionPage({super.key});

  @override
  State<SportSelectionPage> createState() => _SportSelectionPageState();
}

class _SportSelectionPageState extends State<SportSelectionPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedSport;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
    
    // 🔐 CAMBIAR ESTA PARTE:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkAdminStatus();
    // });
    
    // POR ESTO:
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAdminStatus();
    });
  }

  // 🔐 Verificar estado de administrador
  // 🔐 Verificar estado de administrador
  void _checkAdminStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    print('🔍 DEBUG: Email actual: ${userProvider.currentUser?.email}'); // ← AGREGAR
    print('🔍 DEBUG: Es autenticado: ${userProvider.isAuthenticated}');   // ← AGREGAR
    
    if (userProvider.isAuthenticated) {
      adminProvider.checkAdminStatus(userProvider.currentUser?.email);
      print('🔍 DEBUG: Es admin: ${adminProvider.isAdmin}');              // ← AGREGAR
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ BUILD: SportSelectionPage con módulo admin EJECUTÁNDOSE'); // ← AGREGAR ESTA LÍNEA
    
    return Scaffold(
      body: Column(
        children: [
          // Contenido principal expandible
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CorporateTheme.backgroundLight,
                    Color(0xFFF0F2F5),
                  ],
                ),
              ),
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: CustomScrollView(
                          slivers: [
                            // Header corporativo con menú admin integrado
                            _buildCorporateHeader(),
                            
                            // Contenido principal
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Selector de deportes
                                    _buildSportSelector(),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Estadísticas rápidas
                                    _buildQuickStats(),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Información adicional
                                    _buildAdditionalInfo(),
                                    
                                    // Espacio adicional para el footer
                                    const SizedBox(height: 20),
                                  ],
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
          ),
          
          // 📱 Footer de navegación
          _buildFooterNavigation(),
        ],
      ),
      
      // FAB para acceso rápido
      floatingActionButton: _buildQuickAccessFAB(),
    );
  }

  Widget _buildCorporateHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: CorporateTheme.primaryNavyBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: CorporateTheme.primaryGradient,
          ),
          child: Stack(
            children: [
              // Patrón de fondo sutil
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/pattern_bg.png'),
                        repeat: ImageRepeat.repeat,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 🔐 MENÚ ADMIN (esquina inferior izquierda) - INTEGRADO CON MÓDULO
              const Positioned(
                bottom: 15,
                left: 20,
                child: AdminMenuButton(
                  onTap: null, // Usa navegación por defecto
                  showBadge: true,
                ),
              ),
              
              // Contenido del header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo y título
                    Row(
                      children: [
                        // Logo del club
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: CorporateTheme.corporateShadow,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/club_logo.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: CorporateTheme.goldGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.golf_course,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Información del club
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.clubName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'FUNDADO EN ${AppConstants.clubYear}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Botón de perfil
                        _buildProfileButton(),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Mensaje de bienvenida con estado admin
                    Consumer2<UserProvider, AdminProvider>(
                      builder: (context, userProvider, adminProvider, child) {
                        String welcomeMessage;
                        
                        if (userProvider.isAuthenticated) {
                          if (adminProvider.isAdmin) {
                            welcomeMessage = 'Bienvenido Admin, ${userProvider.displayName}';
                          } else {
                            welcomeMessage = 'Bienvenido, ${userProvider.displayName}';
                          }
                        } else {
                          welcomeMessage = 'Selecciona tu deporte favorito';
                        }
                        
                        return Text(
                          welcomeMessage,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'Reservas y Servicios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      
      // Acciones del AppBar
      actions: [
        IconButton(
          onPressed: () => _showQuickHelp(),
          icon: const Icon(Icons.help_outline),
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return IconButton(
          onPressed: () => _showProfileMenu(),
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  // 📱 Footer de navegación (igual que antes)
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
        icon: Icons.calendar_today,
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

  Widget _buildSportSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CorporateTheme.elevatedShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Título del selector
            Padding(
              padding: const EdgeInsets.all(16),
              // child: Text(
              //   'Selecciona tu deporte',
              //   style: TextStyle(
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //     color: CorporateTheme.primaryNavyBlue,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
            ),
            
            // SportSelector como cards
            SportSelector(
              selectedSport: _selectedSport,
              onSportSelected: _handleSportSelection,
              showAsCards: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CorporateTheme.corporateShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: CorporateTheme.primaryNavyBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas del día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CorporateTheme.primaryNavyBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stats por deporte (simuladas por ahora)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Golf',
                  '85%',
                  'Ocupación',
                  Icons.golf_course,
                  Color(AppConstants.golfPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tenis',
                  '73%',
                  'Ocupación',
                  Icons.sports_tennis,
                  Color(AppConstants.tennisPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pádel',
                  '91%',
                  'Ocupación',
                  Icons.sports_handball,
                  Color(AppConstants.padelPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String sport, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sport,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CorporateTheme.goldAccent.withOpacity(0.05),
            CorporateTheme.primaryNavyBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CorporateTheme.goldAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: CorporateTheme.primaryNavyBlue,
            size: 28,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Sistema Unificado Multi-Deporte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CorporateTheme.primaryNavyBlue,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Acceda a todas las instalaciones deportivas del club desde una sola aplicación. '
            'Reserve canchas, consulte horarios y gestione sus actividades deportivas.',
            style: TextStyle(
              fontSize: 14,
              color: CorporateTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Botón de contacto
          OutlinedButton.icon(
            onPressed: () => _showContactInfo(),
            icon: Icon(
              Icons.phone,
              size: 18,
              color: CorporateTheme.primaryNavyBlue,
            ),
            label: Text(
              'Contactar Administración',
              style: TextStyle(
                color: CorporateTheme.primaryNavyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: CorporateTheme.primaryNavyBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessFAB() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isAuthenticated) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: () => _showQuickAccess(),
          backgroundColor: CorporateTheme.primaryNavyBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.speed),
          label: const Text('Acceso Rápido'),
        );
      },
    );
  }

  // ===== MÉTODOS DE NAVEGACIÓN Y HANDLERS =====

  void _handleSportSelection(String sportId) {
    setState(() {
      _selectedSport = sportId;
    });

    // Navegar después de un pequeño delay para mostrar la selección
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateToSport(sportId);
    });
  }

  void _navigateToSport(String sportId) {
    Widget targetPage;
    
    switch (sportId) {
      case 'golf':
        // TODO: Implementar página de Golf
        _showComingSoon('Golf');
        return;
        
      case 'tenis':
        targetPage = const TennisReservationsPage();
        break;
        
      case 'padel':
        targetPage = const ReservationsPage();
        break;
        
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showComingSoon(String sport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.construction,
              color: CorporateTheme.goldAccent,
            ),
            const SizedBox(width: 8),
            const Text('Próximamente'),
          ],
        ),
        content: Text(
          'El sistema de reservas para $sport estará disponible muy pronto. '
          'Mientras tanto, puede utilizar los otros deportes disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(color: CorporateTheme.primaryNavyBlue),
            ),
          ),
        ],
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
                backgroundColor: CorporateTheme.primaryNavyBlue,
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

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
            
            const SizedBox(height: 20),
            
            Consumer2<UserProvider, AdminProvider>(
              builder: (context, userProvider, adminProvider, child) {
                return Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: CorporateTheme.primaryNavyBlue,
                          child: Text(
                            userProvider.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Badge de admin
                        if (adminProvider.isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: CorporateTheme.goldAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      userProvider.displayName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    Text(
                      userProvider.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    // Mostrar nivel de admin si aplica
                    if (adminProvider.isAdmin)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CorporateTheme.goldAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CorporateTheme.goldAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Administrador',
                          style: TextStyle(
                            fontSize: 12,
                            color: CorporateTheme.goldAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Botón de panel admin si es admin
                    if (adminProvider.isAdmin)
                      ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: const Text('Panel de Administración'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/admin-dashboard');
                        },
                      ),
                    
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Cerrar Sesión'),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<AuthProvider>().signOut();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda Rápida'),
        content: const Text(
          'Selecciona el deporte que deseas reservar. Cada deporte tiene sus propias '
          'canchas y horarios disponibles.\n\n'
          '• Golf: Campo completo y práctica\n'
          '• Tenis: 4 canchas de tierra batida\n'
          '• Pádel: 3 canchas profesionales',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacto'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Teléfono: +56 33 XXX XXXX'),
            SizedBox(height: 8),
            Text('📧 Email: reservas@clubgolfpapudo.cl'),
            SizedBox(height: 8),
            Text('🕒 Horario: Lunes a Domingo 8:00 - 20:00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showQuickAccess() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Acceso Rápido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Navegación compacta
            SportSelector(
              selectedSport: null,
              onSportSelected: _navigateToSport,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}