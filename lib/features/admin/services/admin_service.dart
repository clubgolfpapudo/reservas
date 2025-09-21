// lib/features/admin/services/admin_service.dart
import 'package:flutter/foundation.dart';
import '../../../core/constants/admin_constants.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  // ðŸ” Cache de datos admin
  Map<String, dynamic> _adminCache = {};
  DateTime? _lastCacheUpdate;
  static const int _cacheLifetimeMinutes = 30;

  // ðŸ” Verificar si un email es administrador
  bool isAdminEmail(String email) {
    return AdminConstants.adminEmails.contains(email.toLowerCase());
  }

  // ðŸ”‘ Obtener permisos de un administrador
  List<String> getAdminPermissions(String email) {
    return AdminConstants.adminPermissions[email.toLowerCase()] ?? [];
  }

  // ðŸ“Š Verificar si tiene un permiso específico
  bool hasPermission(String email, String permission) {
    final permissions = getAdminPermissions(email);
    return permissions.contains('full_access') || permissions.contains(permission);
  }

  // ðŸ“Š Obtener nivel de permisos
  AdminPermissionLevel getPermissionLevel(String email) {
    final permissions = getAdminPermissions(email);
    
    if (permissions.contains('full_access')) {
      return AdminPermissionLevel.superAdmin;
    } else if (permissions.length >= 4) {
      return AdminPermissionLevel.admin;
    } else if (permissions.length >= 2) {
      return AdminPermissionLevel.moderator;
    } else {
      return AdminPermissionLevel.readOnly;
    }
  }

  // ðŸ”§ Obtener funciones disponibles para un admin
  List<AdminFunction> getAvailableFunctions(String email) {
    return AdminConstants.adminFunctions.where((function) {
      return hasPermission(email, function.permission);
    }).toList();
  }

  // ðŸ“Š Cargar métricas del sistema (simulado - conectar con API real)
  Future<List<AdminMetric>> loadSystemMetrics() async {
    try {
      // Verificar cache
      if (_isCacheValid('metrics')) {
        debugPrint('ðŸ“Š Admin metrics loaded from cache');
        return _adminCache['metrics'] as List<AdminMetric>;
      }

      // Simular carga desde API
      await Future.delayed(const Duration(seconds: 2));
      
      final metrics = [
        AdminMetric(
          id: 'total_users',
          title: 'Usuarios Totales',
          value: await _getUserCount(),
          subtitle: '+${await _getNewUsersThisMonth()} este mes',
          icon: Icons.people,
          color: AdminConstants.adminPrimary,
          percentage: await _getUserGrowthPercentage(),
          isPositive: true,
        ),
        AdminMetric(
          id: 'daily_reservations',
          title: 'Reservas Hoy',
          value: await _getTodayReservations(),
          subtitle: 'de ${await _getTotalAvailableSlots()} disponibles',
          icon: Icons.calendar_today,
          color: AdminConstants.adminSuccess,
          percentage: await _getReservationOccupancyPercentage(),
          isPositive: true,
        ),
        AdminMetric(
          id: 'court_occupation',
          title: 'Ocupación Canchas',
          value: '${await _getCourtOccupationPercentage()}%',
          subtitle: 'Promedio semanal',
          icon: Icons.sports_tennis,
          color: AdminConstants.adminAccent,
          percentage: await _getCourtOccupationPercentage(),
          isPositive: true,
        ),
        AdminMetric(
          id: 'revenue',
          title: 'Ingresos Mes',
          value: await _getMonthlyRevenue(),
          subtitle: '+${await _getRevenueGrowthPercentage()}% vs mes anterior',
          icon: Icons.attach_money,
          color: AdminConstants.adminWarning,
          percentage: await _getRevenueGrowthPercentage(),
          isPositive: true,
        ),
      ];

      // Guardar en cache
      _updateCache('metrics', metrics);
      
      debugPrint('ðŸ“Š Admin metrics loaded from API');
      return metrics;
    } catch (e) {
      debugPrint('âŒ Error loading admin metrics: $e');
      return _getDefaultMetrics();
    }
  }

  // ðŸ”” Cargar notificaciones admin
  Future<List<AdminNotification>> loadAdminNotifications() async {
    try {
      // Verificar cache
      if (_isCacheValid('notifications')) {
        debugPrint('ðŸ”” Admin notifications loaded from cache');
        return _adminCache['notifications'] as List<AdminNotification>;
      }

      // Simular carga desde API
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final notifications = await _fetchNotificationsFromAPI();
      
      // Guardar en cache
      _updateCache('notifications', notifications);
      
      debugPrint('ðŸ”” Admin notifications loaded from API');
      return notifications;
    } catch (e) {
      debugPrint('âŒ Error loading admin notifications: $e');
      return _getDefaultNotifications();
    }
  }

  // ðŸ“Š Obtener estadísticas de usuarios
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      return {
        'totalUsers': await _getUserCount(),
        'activeToday': await _getActiveUsersToday(),
        'newThisWeek': await _getNewUsersThisWeek(),
        'newThisMonth': await _getNewUsersThisMonth(),
      };
    } catch (e) {
      debugPrint('âŒ Error loading user statistics: $e');
      return {
        'totalUsers': '497',
        'activeToday': '42',
        'newThisWeek': '8',
        'newThisMonth': '12',
      };
    }
  }

  // ðŸ“… Obtener estadísticas de reservas
  Future<Map<String, dynamic>> getReservationStatistics() async {
    try {
      return {
        'todayReservations': await _getTodayReservations(),
        'weekReservations': await _getWeekReservations(),
        'monthReservations': await _getMonthReservations(),
        'occupancyRate': await _getReservationOccupancyPercentage(),
      };
    } catch (e) {
      debugPrint('âŒ Error loading reservation statistics: $e');
      return {
        'todayReservations': '23',
        'weekReservations': '156',
        'monthReservations': '687',
        'occupancyRate': 84.0,
      };
    }
  }

  // ðŸ’° Obtener estadísticas financieras
  Future<Map<String, dynamic>> getFinancialStatistics() async {
    try {
      return {
        'monthlyRevenue': await _getMonthlyRevenue(),
        'dailyRevenue': await _getDailyRevenue(),
        'revenueGrowth': await _getRevenueGrowthPercentage(),
        'averagePerReservation': await _getAverageRevenuePerReservation(),
      };
    } catch (e) {
      debugPrint('âŒ Error loading financial statistics: $e');
      return {
        'monthlyRevenue': '\$2.1M',
        'dailyRevenue': '\$68K',
        'revenueGrowth': 8.5,
        'averagePerReservation': '\$35',
      };
    }
  }

  // ðŸ”” Crear nueva notificación admin
  AdminNotification createNotification({
    required String title,
    required String message,
    required AdminNotificationType type,
    Map<String, dynamic>? data,
  }) {
    return AdminNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      data: data,
    );
  }

  // ðŸ“Š Exportar datos para reportes
  Future<Map<String, dynamic>> exportDataForReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Simular exportación de datos
      await Future.delayed(const Duration(seconds: 3));
      
      switch (reportType) {
        case 'users':
          return await _exportUserData(startDate, endDate);
        case 'reservations':
          return await _exportReservationData(startDate, endDate);
        case 'financial':
          return await _exportFinancialData(startDate, endDate);
        default:
          throw Exception('Tipo de reporte no válido: $reportType');
      }
    } catch (e) {
      debugPrint('âŒ Error exporting data: $e');
      rethrow;
    }
  }

  // ðŸ”§ Limpiar cache
  void clearCache() {
    _adminCache.clear();
    _lastCacheUpdate = null;
    debugPrint('ðŸ§¹ Admin cache cleared');
  }

  // ðŸ“Š Obtener información del cache
  Map<String, dynamic> getCacheInfo() {
    return {
      'cacheSize': _adminCache.length,
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      'isValid': _lastCacheUpdate != null && _isCacheValid(''),
      'cachedKeys': _adminCache.keys.toList(),
    };
  }

  // ===== MÃ‰TODOS PRIVADOS =====

  // ðŸ”§ Verificar si el cache es válido
  bool _isCacheValid(String key) {
    if (_lastCacheUpdate == null || !_adminCache.containsKey(key)) {
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastCacheUpdate!);
    return difference.inMinutes < _cacheLifetimeMinutes;
  }

  // ðŸ”§ Actualizar cache
  void _updateCache(String key, dynamic data) {
    _adminCache[key] = data;
    _lastCacheUpdate = DateTime.now();
  }

  // ðŸ“Š Métodos de datos simulados (reemplazar con API real)
  
  Future<String> _getUserCount() async {
    // Simular consulta a base de datos
    await Future.delayed(const Duration(milliseconds: 500));
    return '497';
  }

  Future<int> _getNewUsersThisMonth() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 12;
  }

  Future<double> _getUserGrowthPercentage() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 2.4;
  }

  Future<String> _getTodayReservations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return '23';
  }

  Future<int> _getTotalAvailableSlots() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 36;
  }

  Future<double> _getReservationOccupancyPercentage() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return 63.9;
  }

  Future<double> _getCourtOccupationPercentage() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return 84.0;
  }

  Future<String> _getMonthlyRevenue() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return '\$2.1M';
  }

  Future<double> _getRevenueGrowthPercentage() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 8.5;
  }

  Future<String> _getActiveUsersToday() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '42';
  }

  Future<int> _getNewUsersThisWeek() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return 8;
  }

  Future<String> _getWeekReservations() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return '156';
  }

  Future<String> _getMonthReservations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return '687';
  }

  Future<String> _getDailyRevenue() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '\$68K';
  }

  Future<String> _getAverageRevenuePerReservation() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return '\$35';
  }

  // ðŸ”” Obtener notificaciones desde API simulada
  Future<List<AdminNotification>> _fetchNotificationsFromAPI() async {
    return [
      AdminNotification(
        id: '1',
        title: 'Nueva reserva',
        message: 'Juan Pérez reservó Cancha 1 de Tenis para hoy 16:00',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: AdminNotificationType.info,
      ),
      AdminNotification(
        id: '2',
        title: 'Cancelación',
        message: 'María González canceló su reserva de Pádel para mañana',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: AdminNotificationType.warning,
      ),
      AdminNotification(
        id: '3',
        title: 'Sistema actualizado',
        message: 'Cache optimizado implementado exitosamente - Performance mejorada 95%',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: AdminNotificationType.success,
        isRead: true,
      ),
      AdminNotification(
        id: '4',
        title: 'Mantenimiento programado',
        message: 'Mantenimiento del servidor programado para mañana 02:00 - 04:00',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        type: AdminNotificationType.urgent,
      ),
      AdminNotification(
        id: '5',
        title: 'Nuevo usuario registrado',
        message: 'Carlos Silva se registró en el sistema',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        type: AdminNotificationType.info,
        isRead: true,
      ),
    ];
  }

  // ðŸ“Š Métricas por defecto en caso de error
  List<AdminMetric> _getDefaultMetrics() {
    return [
      const AdminMetric(
        id: 'total_users',
        title: 'Usuarios Totales',
        value: '497',
        subtitle: 'Dato en cache',
        icon: Icons.people,
        color: AdminConstants.adminPrimary,
      ),
      const AdminMetric(
        id: 'daily_reservations',
        title: 'Reservas Hoy',
        value: '23',
        subtitle: 'Dato en cache',
        icon: Icons.calendar_today,
        color: AdminConstants.adminSuccess,
      ),
      const AdminMetric(
        id: 'court_occupation',
        title: 'Ocupación Canchas',
        value: '84%',
        subtitle: 'Dato en cache',
        icon: Icons.sports_tennis,
        color: AdminConstants.adminAccent,
      ),
      const AdminMetric(
        id: 'revenue',
        title: 'Ingresos Mes',
        value: '\$2.1M',
        subtitle: 'Dato en cache',
        icon: Icons.attach_money,
        color: AdminConstants.adminWarning,
      ),
    ];
  }

  // ðŸ”” Notificaciones por defecto en caso de error
  List<AdminNotification> _getDefaultNotifications() {
    return [
      AdminNotification(
        id: 'default_1',
        title: 'Sistema funcionando',
        message: 'Todos los sistemas operando normalmente',
        timestamp: DateTime.now(),
        type: AdminNotificationType.success,
        isRead: true,
      ),
    ];
  }

  // ðŸ“Š Métodos de exportación de datos
  
  Future<Map<String, dynamic>> _exportUserData(DateTime startDate, DateTime endDate) async {
    return {
      'reportType': 'users',
      'period': '${startDate.toIso8601String()} - ${endDate.toIso8601String()}',
      'totalUsers': 497,
      'newUsers': 25,
      'activeUsers': 342,
      'data': [
        // Datos simulados de usuarios
      ],
    };
  }

  Future<Map<String, dynamic>> _exportReservationData(DateTime startDate, DateTime endDate) async {
    return {
      'reportType': 'reservations',
      'period': '${startDate.toIso8601String()} - ${endDate.toIso8601String()}',
      'totalReservations': 687,
      'completedReservations': 654,
      'cancelledReservations': 33,
      'data': [
        // Datos simulados de reservas
      ],
    };
  }

  Future<Map<String, dynamic>> _exportFinancialData(DateTime startDate, DateTime endDate) async {
    return {
      'reportType': 'financial',
      'period': '${startDate.toIso8601String()} - ${endDate.toIso8601String()}',
      'totalRevenue': 2100000,
      'averagePerReservation': 35,
      'growth': 8.5,
      'data': [
        // Datos simulados financieros
      ],
    };
  }

  // ðŸ”§ Debug: Imprimir estado del servicio
  void debugPrintServiceStatus() {
    if (kDebugMode) {
      print('=== ADMIN SERVICE DEBUG ===');
      print('Cache size: ${_adminCache.length}');
      print('Last cache update: $_lastCacheUpdate');
      print('Cache lifetime: $_cacheLifetimeMinutes minutes');
      print('Available admin emails: ${AdminConstants.adminEmails.length}');
      print('Available functions: ${AdminConstants.adminFunctions.length}');
      print('=========================');
    }
  }
}

