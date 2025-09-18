// lib/features/admin/presentation/widgets/admin_menu_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../../../core/constants/admin_constants.dart';

class AdminMenuButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showBadge;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  
  const AdminMenuButton({
    Key? key,
    this.onTap,
    this.showBadge = true,
    this.padding,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Solo mostrar si el usuario es administrador
        if (!adminProvider.isAdmin) return const SizedBox.shrink();
        
        return GestureDetector(
          onTap: onTap ?? () => _navigateToAdminDashboard(context),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Contenido principal del botÃ³n
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AdminConstants.adminMenuLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize ?? 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Badge de notificaciones no leÃ­das
                if (false && adminProvider.unreadNotifications > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AdminConstants.adminError,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          adminProvider.unreadNotifications > 99 
                              ? '99+' 
                              : adminProvider.unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _navigateToAdminDashboard(BuildContext context) {
    Navigator.pushNamed(context, '/admin-dashboard');
  }
}

// ðŸŽ¨ Variante del botÃ³n para usar en diferentes contextos
class AdminMenuButtonVariant extends StatelessWidget {
  final AdminMenuStyle style;
  final VoidCallback? onTap;
  final bool showBadge;
  
  const AdminMenuButtonVariant({
    Key? key,
    required this.style,
    this.onTap,
    this.showBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (!adminProvider.isAdmin) return const SizedBox.shrink();
        
        switch (style) {
          case AdminMenuStyle.compact:
            return _buildCompactButton(context, adminProvider);
          case AdminMenuStyle.pill:
            return _buildPillButton(context, adminProvider);
          case AdminMenuStyle.iconOnly:
            return _buildIconOnlyButton(context, adminProvider);
          case AdminMenuStyle.outlined:
            return _buildOutlinedButton(context, adminProvider);
          default:
            return const AdminMenuButton();
        }
      },
    );
  }
  
  Widget _buildCompactButton(BuildContext context, AdminProvider adminProvider) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/admin-dashboard'),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminConstants.adminPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AdminConstants.adminPrimary.withOpacity(0.3),
          ),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 14,
                  color: AdminConstants.adminPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: AdminConstants.adminPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (false && adminProvider.unreadNotifications > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AdminConstants.adminError,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPillButton(BuildContext context, AdminProvider adminProvider) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/admin-dashboard'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AdminConstants.adminPrimary,
              AdminConstants.adminSecondary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AdminConstants.adminPrimary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (false && adminProvider.unreadNotifications > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AdminConstants.adminError,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIconOnlyButton(BuildContext context, AdminProvider adminProvider) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/admin-dashboard'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 20,
              color: Colors.white,
            ),
            if (false && adminProvider.unreadNotifications > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AdminConstants.adminError,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOutlinedButton(BuildContext context, AdminProvider adminProvider) {
    return OutlinedButton.icon(
      onPressed: onTap ?? () => Navigator.pushNamed(context, '/admin-dashboard'),
      icon: Stack(
        children: [
          const Icon(
            Icons.admin_panel_settings,
            size: 18,
          ),
          if (false && adminProvider.unreadNotifications > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AdminConstants.adminError,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      label: const Text('Admin'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminConstants.adminPrimary,
        side: BorderSide(color: AdminConstants.adminPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ðŸŽ¨ Enum para estilos del botÃ³n admin
enum AdminMenuStyle {
  default_,
  compact,
  pill,
  iconOnly,
  outlined,
}
