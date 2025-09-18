// lib/features/admin/providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/admin_constants.dart';

class AdminProvider extends ChangeNotifier {
  // ðŸ” Estado de autenticaciÃ³n admin
  bool _isAdmin = false;
  String? _currentAdminEmail;
  List<String> _currentPermissions = [];
  AdminPermissionLevel _permissionLevel = AdminPermissionLevel.readOnly;
  
  // ðŸ“Š Estado del dashboard
  List<AdminMetric> _metrics = [];
  List<AdminNotification> _notifications = [];
  bool _isLoadingMetrics = false;
  bool _isLoadingNotifications = false;
  
  // ðŸ”” Estado de notificaciones
  int _unreadNotifications = 0; // Always 0 - notifications disabled
  
  // Getters pÃºblicos
  bool get isAdmin => _isAdmin;
  String? get currentAdminEmail => _currentAdminEmail;
  List<String> get currentPermissions => List.unmodifiable(_currentPermissions);
  AdminPermissionLevel get permissionLevel => _permissionLevel;
  List<AdminMetric> get metrics => List.unmodifiable(_metrics);
  List<AdminNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoadingMetrics => _isLoadingMetrics;
  bool get isLoadingNotifications => _isLoadingNotifications;
  int get unreadNotifications => _unreadNotifications;
  
  // ðŸ” Verificar estado de administrador
  void checkAdminStatus(String? email) {
    _isAdmin = AdminConstants.adminEmails.contains(email);
    _currentAdminEmail = _isAdmin ? email : null;
    
    if (_isAdmin && email != null) {
      _loadAdminPermissions(email);
      _determinePermissionLevel();
      _loadAdminData();
    } else {
      _clearAdminData();
    }
    
    notifyListeners();
  }
  
  // ðŸ”‘ Cargar permisos del administrador
  void _loadAdminPermissions(String email) {
    _currentPermissions = AdminConstants.adminPermissions[email] ?? [];
  }
  
  // ðŸ“Š Determinar nivel de permisos
  void _determinePermissionLevel() {
    if (_currentPermissions.contains('full_access')) {
      _permissionLevel = AdminPermissionLevel.superAdmin;
    } else if (_currentPermissions.length >= 4) {
      _permissionLevel = AdminPermissionLevel.admin;
    } else if (_currentPermissions.length >= 2) {
      _permissionLevel = AdminPermissionLevel.moderator;
    } else {
      _permissionLevel = AdminPermissionLevel.readOnly;
    }
  }
  
  // ðŸ“± Cargar datos administrativos
  Future<void> _loadAdminData() async {
    await Future.wait([
      _loadMetrics(),
      _loadNotifications(),
    ]);
  }
  
  // ðŸ§¹ Limpiar datos admin al cerrar sesiÃ³n
  void _clearAdminData() {
    _currentPermissions.clear();
    _metrics.clear();
    _notifications.clear();
    _unreadNotifications = 0;
    _permissionLevel = AdminPermissionLevel.readOnly;
  }
  
  // ðŸ”‘ Verificar permisos especÃ­ficos
  bool hasPermission(String permission) {
    if (!_isAdmin) return false;
    return _currentPermissions.contains('full_access') || 
           _currentPermissions.contains(permission);
  }
  
  // ðŸ“Š Verificar nivel mÃ­nimo de permisos
  bool hasMinimumPermissionLevel(AdminPermissionLevel requiredLevel) {
    return _permissionLevel.index >= requiredLevel.index;
  }
  
  // ðŸ”§ Obtener funciones disponibles para el admin actual
  List<AdminFunction> getAvailableFunctions() {
    if (!_isAdmin) return [];
    
    return AdminConstants.adminFunctions.where((function) {
      return hasPermission(function.permission);
    }).toList();
  }
  
  // ðŸ“Š Cargar mÃ©tricas del dashboard
  Future<void> _loadMetrics() async {
    if (!_isAdmin) return;
    
    _isLoadingMetrics = true;
    notifyListeners();
    
    try {
      // Simular carga de mÃ©tricas (reemplazar con servicio real)
      await Future.delayed(const Duration(seconds: 1));
      
      _metrics = [
        AdminMetric(
          id: 'total_users',
          title: 'Usuarios Totales',
          value: '497',
          subtitle: '+12 este mes',
          icon: Icons.people,
          color: AdminConstants.adminPrimary,
          percentage: 2.4,
          isPositive: true,
        ),
        AdminMetric(
          id: 'daily_reservations',
          title: 'Reservas Hoy',
          value: '23',
          subtitle: 'de 36 disponibles',
          icon: Icons.calendar_today,
          color: AdminConstants.adminSuccess,
          percentage: 63.9,
          isPositive: true,
        ),
        AdminMetric(
          id: 'court_occupation',
          title: 'OcupaciÃ³n Canchas',
          value: '84%',
          subtitle: 'Promedio semanal',
          icon: Icons.sports_tennis,
          color: AdminConstants.adminAccent,
          percentage: 84.0,
          isPositive: true,
        ),
        AdminMetric(
          id: 'revenue',
          title: 'Ingresos Mes',
          value: '\$2.1M',
          subtitle: '+8.5% vs mes anterior',
          icon: Icons.attach_money,
          color: AdminConstants.adminWarning,
          percentage: 8.5,
          isPositive: true,
        ),
      ];
    } catch (e) {
      debugPrint('Error cargando mÃ©tricas: $e');
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }
  
  // ðŸ”” Cargar notificaciones
  Future<void> _loadNotifications() async {
    if (!_isAdmin) return;
    
    _isLoadingNotifications = true;
    notifyListeners();
    
    try {
      // Simular carga de notificaciones (reemplazar con servicio real)
      await Future.delayed(const Duration(milliseconds: 800));
      
      _notifications = [
        AdminNotification(
          id: '1',
          title: 'Nueva reserva',
          message: 'Juan PÃ©rez reservÃ³ Cancha 1 de Tenis',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          type: AdminNotificationType.info,
        ),
        AdminNotification(
          id: '2',
          title: 'CancelaciÃ³n',
          message: 'MarÃ­a GonzÃ¡lez cancelÃ³ reserva de PÃ¡del',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          type: AdminNotificationType.warning,
        ),
        AdminNotification(
          id: '3',
          title: 'Sistema actualizado',
          message: 'Cache optimizado implementado exitosamente',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: AdminNotificationType.success,
          isRead: true,
        ),
        AdminNotification(
          id: '4',
          title: 'Mantenimiento programado',
          message: 'Mantenimiento del servidor programado para maÃ±ana',
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          type: AdminNotificationType.urgent,
        ),
      ];
      
      _unreadNotifications = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }
  
  // ðŸ”„ Refrescar datos del dashboard
  Future<void> refreshDashboard() async {
    if (!_isAdmin) return;
    
    await Future.wait([
      _loadMetrics(),
      _loadNotifications(),
    ]);
  }
  
  // ðŸ”” Marcar notificaciÃ³n como leÃ­da
  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = AdminNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        timestamp: _notifications[index].timestamp,
        type: _notifications[index].type,
        isRead: true,
        data: _notifications[index].data,
      );
      
      _unreadNotifications = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }
  
  // ðŸ”” Marcar todas las notificaciones como leÃ­das
  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((notification) => 
      AdminNotification(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timestamp: notification.timestamp,
        type: notification.type,
        isRead: true,
        data: notification.data,
      )
    ).toList();
    
    _unreadNotifications = 0;
    notifyListeners();
  }
  
  // ðŸ“Š Obtener mÃ©trica especÃ­fica
  AdminMetric? getMetricById(String metricId) {
    try {
      return _metrics.firstWhere((metric) => metric.id == metricId);
    } catch (e) {
      return null;
    }
  }
  
  // ðŸ”” Agregar nueva notificaciÃ³n (para testing o desarrollo)
  void addNotification(AdminNotification notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadNotifications++;
    }
    notifyListeners();
  }
  
  // ðŸ”§ Obtener resumen de permisos
  Map<String, dynamic> getPermissionsSummary() {
    return {
      'isAdmin': _isAdmin,
      'email': _currentAdminEmail,
      'permissionLevel': _permissionLevel.toString(),
      'permissions': _currentPermissions,
      'availableFunctions': getAvailableFunctions().length,
    };
  }
  
  // ðŸ“± Verificar si puede acceder a una funciÃ³n especÃ­fica
  bool canAccessFunction(String functionId) {
    final function = AdminConstants.adminFunctions
        .where((f) => f.id == functionId)
        .firstOrNull;
    
    if (function == null) return false;
    return hasPermission(function.permission);
  }
  
  // ðŸ”§ Debug: Obtener informaciÃ³n del estado actual
  void debugPrintAdminStatus() {
    if (kDebugMode) {
      print('=== ADMIN STATUS DEBUG ===');
      print('Is Admin: $_isAdmin');
      print('Email: $_currentAdminEmail');
      print('Permission Level: $_permissionLevel');
      print('Permissions: $_currentPermissions');
      print('Available Functions: ${getAvailableFunctions().length}');
      print('Unread Notifications: $_unreadNotifications');
      print('========================');
    }
  }
}
