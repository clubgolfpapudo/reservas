// lib/features/admin/presentation/pages/admin_dashboard_page.dart
import 'package:cgp_reservas/presentation/pages/admin_reservations_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../../../core/constants/admin_constants.dart';
import '../../../../core/theme/corporate_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
    
    // Cargar datos del dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refreshDashboard();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Verificar acceso de administrador
        if (!adminProvider.isAdmin) {
          return _buildAccessDenied();
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CorporateTheme.backgroundLight,
                  Color(0xFFF8F9FA),
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
                          // Header del dashboard admin
                          _buildAdminHeader(adminProvider),
                          
                          // Contenido principal
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: AdminConstants.adminPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Funciones administrativas
                                  _buildAdminFunctions(adminProvider),
                                  
                                  const SizedBox(height: AdminConstants.adminSpacing * 2),
                                  
                                  // Métricas principales
                                  _buildMetricsSection(adminProvider),
                                  
                                  const SizedBox(height: AdminConstants.adminSpacing * 2),
                                  
                                  // Notificaciones recientes
                                  _buildNotificationsSection(adminProvider),
                                  
                                  const SizedBox(height: AdminConstants.adminSpacing * 2),
                                  
                                  // Actividad reciente
                                  _buildRecentActivity(),
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
          
          // FAB para acciones rápidas
          floatingActionButton: _buildQuickActionsFAB(adminProvider),
        );
      },
    );
  }

  Widget _buildAdminHeader(AdminProvider adminProvider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AdminConstants.adminPrimary,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AdminConstants.adminPrimary,
                AdminConstants.adminSecondary,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar del admin
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Información del admin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AdminConstants.adminWelcomeMessage,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            adminProvider.currentAdminEmail?.split('@').first.toUpperCase() ?? 'ADMIN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Indicador de notificaciones
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => _showNotificationsModal(adminProvider),
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (adminProvider.unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AdminConstants.adminError,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        title: Text(
          AdminConstants.adminPanelTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      
      // Acciones del header
      actions: [
        IconButton(
          onPressed: () => _showAdminSettings(),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas del Sistema',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AdminConstants.adminPrimary,
          ),
        ),
        
        const SizedBox(height: AdminConstants.adminSpacing),
        
        if (adminProvider.isLoadingMetrics)
          _buildMetricsLoading()
        else
          _buildMetricsGrid(adminProvider.metrics),
      ],
    );
  }

  Widget _buildMetricsLoading() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AdminConstants.adminSpacing,
        mainAxisSpacing: AdminConstants.adminSpacing,
        childAspectRatio: 1.3,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(List<AdminMetric> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AdminConstants.adminSpacing,
        mainAxisSpacing: AdminConstants.adminSpacing,
        childAspectRatio: 1.3,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        return _buildMetricCard(metrics[index]);
      },
    );
  }

  Widget _buildMetricCard(AdminMetric metric) {
    return Container(
      padding: AdminConstants.adminPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric.icon,
                  color: metric.color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (metric.percentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: metric.isPositive 
                        ? AdminConstants.adminSuccess.withOpacity(0.1)
                        : AdminConstants.adminError.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metric.isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: metric.isPositive 
                            ? AdminConstants.adminSuccess
                            : AdminConstants.adminError,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${metric.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: metric.isPositive 
                              ? AdminConstants.adminSuccess
                              : AdminConstants.adminError,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            metric.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: metric.color,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            metric.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 2),
          
          Text(
            metric.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFunctions(AdminProvider adminProvider) {
    final availableFunctions = adminProvider.getAvailableFunctions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funciones Administrativas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AdminConstants.adminPrimary,
          ),
        ),
        
        const SizedBox(height: AdminConstants.adminSpacing),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AdminConstants.adminSpacing,
            mainAxisSpacing: AdminConstants.adminSpacing,
            childAspectRatio: 1.5,
          ),
          itemCount: availableFunctions.length,
          itemBuilder: (context, index) {
            return _buildFunctionCard(availableFunctions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFunctionCard(AdminFunction function) {
    return InkWell(
      onTap: () => _navigateToFunction(function),
      borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
      child: Container(
        padding: AdminConstants.adminPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
          border: Border.all(
            color: AdminConstants.adminPrimary.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminConstants.adminPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                function.icon,
                color: AdminConstants.adminPrimary,
                size: 24,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              function.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            Expanded(
              child: Text(
                function.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AdminConstants.adminPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Notificaciones Recientes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AdminConstants.adminPrimary,
              ),
            ),
            const Spacer(),
            if (adminProvider.unreadNotifications > 0)
              TextButton(
                onPressed: () => adminProvider.markAllNotificationsAsRead(),
                child: const Text('Marcar todo como leído'),
              ),
          ],
        ),
        
        const SizedBox(height: AdminConstants.adminSpacing),
        
        if (adminProvider.isLoadingNotifications)
          const Center(child: CircularProgressIndicator())
        else if (adminProvider.notifications.isEmpty)
          _buildEmptyNotifications()
        else
          _buildNotificationsList(adminProvider),
      ],
    );
  }

  Widget _buildEmptyNotifications() {
    return Container(
      padding: AdminConstants.adminPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(AdminProvider adminProvider) {
    final notifications = adminProvider.notifications.take(5).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _buildNotificationItem(notifications[index], adminProvider);
        },
      ),
    );
  }

  Widget _buildNotificationItem(AdminNotification notification, AdminProvider adminProvider) {
    Color typeColor;
    IconData typeIcon;
    
    switch (notification.type) {
      case AdminNotificationType.success:
        typeColor = AdminConstants.adminSuccess;
        typeIcon = Icons.check_circle_outline;
        break;
      case AdminNotificationType.warning:
        typeColor = AdminConstants.adminWarning;
        typeIcon = Icons.warning_outlined;
        break;
      case AdminNotificationType.error:
        typeColor = AdminConstants.adminError;
        typeIcon = Icons.error_outline;
        break;
      case AdminNotificationType.urgent:
        typeColor = AdminConstants.adminError;
        typeIcon = Icons.priority_high;
        break;
      default:
        typeColor = AdminConstants.adminAccent;
        typeIcon = Icons.info_outline;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          typeIcon,
          color: typeColor,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(notification.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: notification.isRead 
          ? null 
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AdminConstants.adminAccent,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () {
        if (!notification.isRead) {
          adminProvider.markNotificationAsRead(notification.id);
        }
      },
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AdminConstants.adminPrimary,
          ),
        ),
        
        const SizedBox(height: AdminConstants.adminSpacing),
        
        Container(
          padding: AdminConstants.adminPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AdminConstants.adminCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                Icons.person_add,
                'Nuevo usuario registrado',
                'María González se registró en el sistema',
                '5 min ago',
                AdminConstants.adminSuccess,
              ),
              const Divider(),
              _buildActivityItem(
                Icons.calendar_today,
                'Reserva creada',
                'Juan Pérez reservó Cancha 1 de Tenis',
                '15 min ago',
                AdminConstants.adminAccent,
              ),
              const Divider(),
              _buildActivityItem(
                Icons.update,
                'Sistema actualizado',
                'Cache optimizado implementado exitosamente',
                '2 horas ago',
                AdminConstants.adminWarning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String description, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsFAB(AdminProvider adminProvider) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionsMenu(adminProvider),
      backgroundColor: AdminConstants.adminPrimary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.speed),
      label: const Text('Acciones Rápidas'),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Denegado'),
        backgroundColor: AdminConstants.adminError,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: AdminConstants.adminError,
            ),
            const SizedBox(height: 24),
            const Text(
              'Acceso Denegado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes permisos para acceder a esta sección.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== MÉTODOS DE NAVEGACIÓN Y ACCIONES =====

  void _navigateToFunction(AdminFunction function) {
    switch (function.route) {
      case '/admin/reservations': // ✅ Usamos la ruta existente
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminReservationsPage(),
          ),
        );
        break;
      default:
        // Código para funciones no implementadas o con rutas no coincidentes
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(function.title),
            content: Text('${function.description}\n\nPróximamente disponible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showNotificationsModal(AdminProvider adminProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (adminProvider.unreadNotifications > 0)
                  TextButton(
                    onPressed: () {
                      adminProvider.markAllNotificationsAsRead();
                      Navigator.pop(context);
                    },
                    child: const Text('Marcar todo como leído'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: adminProvider.notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(
                    adminProvider.notifications[index], 
                    adminProvider,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsMenu(AdminProvider adminProvider) {
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
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refrescar Dashboard'),
              onTap: () {
                Navigator.pop(context);
                adminProvider.refreshDashboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Admin Status'),
              onTap: () {
                Navigator.pop(context);
                adminProvider.debugPrintAdminStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración Admin'),
        content: const Text('Configuración del panel administrativo próximamente disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    } else {
      return '${difference.inDays} días ago';
    }
  }
}