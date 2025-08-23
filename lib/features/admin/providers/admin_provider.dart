// lib/features/admin/providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/admin_constants.dart';

class AdminProvider extends ChangeNotifier {
  // 🔐 Estado de autenticación admin
  bool _isAdmin = false;
  String? _currentAdminEmail;
  List<String> _currentPermissions = [];
  AdminPermissionLevel _permissionLevel = AdminPermissionLevel.readOnly;
  
  // 📊 Estado del dashboard
  List<AdminMetric> _metrics = [];
  List<AdminNotification> _notifications = [];
  bool _isLoadingMetrics = false;
  bool _isLoadingNotifications = false;
  
  // 🔔 Estado de notificaciones
  int _unreadNotifications = 0;
  
  // Getters públicos
  bool get isAdmin => _isAdmin;
  String? get currentAdminEmail => _currentAdminEmail;
  List<String> get currentPermissions => List.unmodifiable(_currentPermissions);
  AdminPermissionLevel get permissionLevel => _permissionLevel;
  List<AdminMetric> get metrics => List.unmodifiable(_metrics);
  List<AdminNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoadingMetrics => _isLoadingMetrics;
  bool get isLoadingNotifications => _isLoadingNotifications;
  int get unreadNotifications => _unreadNotifications;
  
  // 🔐 Verificar estado de administrador
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
  
  // 🔑 Cargar permisos del administrador
  void _loadAdminPermissions(String email) {
    _currentPermissions = AdminConstants.adminPermissions[email] ?? [];
  }
  
  // 📊 Determinar nivel de permisos
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
  
  // 📱 Cargar datos administrativos
  Future<void> _loadAdminData() async {
    await Future.wait([
      _loadMetrics(),
      _loadNotifications(),
    ]);
  }
  
  // 🧹 Limpiar datos admin al cerrar sesión
  void _clearAdminData() {
    _currentPermissions.clear();
    _metrics.clear();
    _notifications.clear();
    _unreadNotifications = 0;
    _permissionLevel = AdminPermissionLevel.readOnly;
  }
  
  // 🔑 Verificar permisos específicos
  bool hasPermission(String permission) {
    if (!_isAdmin) return false;
    return _currentPermissions.contains('full_access') || 
           _currentPermissions.contains(permission);
  }
  
  // 📊 Verificar nivel mínimo de permisos
  bool hasMinimumPermissionLevel(AdminPermissionLevel requiredLevel) {
    return _permissionLevel.index >= requiredLevel.index;
  }
  
  // 🔧 Obtener funciones disponibles para el admin actual
  List<AdminFunction> getAvailableFunctions() {
    if (!_isAdmin) return [];
    
    return AdminConstants.adminFunctions.where((function) {
      return hasPermission(function.permission);
    }).toList();
  }
  
  // 📊 Cargar métricas del dashboard
  Future<void> _loadMetrics() async {
    if (!_isAdmin) return;
    
    _isLoadingMetrics = true;
    notifyListeners();
    
    try {
      // Simular carga de métricas (reemplazar con servicio real)
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
          title: 'Ocupación Canchas',
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
      debugPrint('Error cargando métricas: $e');
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }
  
  // 🔔 Cargar notificaciones
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
          message: 'Juan Pérez reservó Cancha 1 de Tenis',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          type: AdminNotificationType.info,
        ),
        AdminNotification(
          id: '2',
          title: 'Cancelación',
          message: 'María González canceló reserva de Pádel',
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
          message: 'Mantenimiento del servidor programado para mañana',
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
  
  // 🔄 Refrescar datos del dashboard
  Future<void> refreshDashboard() async {
    if (!_isAdmin) return;
    
    await Future.wait([
      _loadMetrics(),
      _loadNotifications(),
    ]);
  }
  
  // 🔔 Marcar notificación como leída
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
  
  // 🔔 Marcar todas las notificaciones como leídas
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
  
  // 📊 Obtener métrica específica
  AdminMetric? getMetricById(String metricId) {
    try {
      return _metrics.firstWhere((metric) => metric.id == metricId);
    } catch (e) {
      return null;
    }
  }
  
  // 🔔 Agregar nueva notificación (para testing o desarrollo)
  void addNotification(AdminNotification notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadNotifications++;
    }
    notifyListeners();
  }
  
  // 🔧 Obtener resumen de permisos
  Map<String, dynamic> getPermissionsSummary() {
    return {
      'isAdmin': _isAdmin,
      'email': _currentAdminEmail,
      'permissionLevel': _permissionLevel.toString(),
      'permissions': _currentPermissions,
      'availableFunctions': getAvailableFunctions().length,
    };
  }
  
  // 📱 Verificar si puede acceder a una función específica
  bool canAccessFunction(String functionId) {
    final function = AdminConstants.adminFunctions
        .where((f) => f.id == functionId)
        .firstOrNull;
    
    if (function == null) return false;
    return hasPermission(function.permission);
  }
  
  // 🔧 Debug: Obtener información del estado actual
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