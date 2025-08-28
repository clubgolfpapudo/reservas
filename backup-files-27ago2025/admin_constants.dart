// lib/core/constants/admin_constants.dart
import 'package:flutter/material.dart';

class AdminConstants {
  // 🔐 Lista de administradores
  static const List<String> adminEmails = [
    'felipe@garciab.cl',
    'administracion@clubgolfpapudo.cl',
    'gerente@clubgolfpapudo.cl',
    // Futuros administradores se agregan aquí
  ];
  
  // 🎨 Configuración UI
  static const String adminPanelTitle = 'Panel de Administración';
  static const String adminMenuLabel = 'Admin';
  static const String adminWelcomeMessage = 'Bienvenido al panel administrativo';
  
  // 🔑 Sistema de permisos granular
  static const Map<String, List<String>> adminPermissions = {
    'felipe@garciab.cl': [
      'full_access',
      'user_management',
      'reports',
      'settings',
      'reservations_management',
      'court_management',
    ],
    'administracion@clubgolfpapudo.cl': [
      'read_only',
      'reports',
      'reservations_management',
    ],
    'gerente@clubgolfpapudo.cl': [
      'user_management',
      'reports',
      'reservations_management',
    ],
  };
  
  // 📊 Funciones administrativas disponibles
  static const List<AdminFunction> adminFunctions = [
    AdminFunction(
      id: 'user_management',
      title: 'Gestión de Usuarios',
      icon: Icons.people,
      description: 'Administrar usuarios del sistema',
      route: '/admin/users',
      permission: 'user_management',
    ),
    AdminFunction(
      id: 'reservations_management',
      title: 'Gestión de Reservas',
      icon: Icons.calendar_today,
      description: 'Ver y administrar todas las reservas',
      route: '/admin/reservations',
      permission: 'reservations_management',
    ),
    AdminFunction(
      id: 'court_management',
      title: 'Gestión de Canchas',
      icon: Icons.sports_tennis,
      description: 'Configurar canchas y horarios',
      route: '/admin/courts',
      permission: 'court_management',
    ),
    AdminFunction(
      id: 'reports',
      title: 'Reportes y Estadísticas',
      icon: Icons.analytics,
      description: 'Ver estadísticas y generar reportes',
      route: '/admin/reports',
      permission: 'reports',
    ),
    AdminFunction(
      id: 'notifications',
      title: 'Gestión de Notificaciones',
      icon: Icons.notifications,
      description: 'Enviar avisos y notificaciones',
      route: '/admin/notifications',
      permission: 'user_management',
    ),
    AdminFunction(
      id: 'settings',
      title: 'Configuración del Sistema',
      icon: Icons.settings,
      description: 'Configurar parámetros del sistema',
      route: '/admin/settings',
      permission: 'settings',
    ),
  ];
  
  // 🎨 Colores del tema admin
  static const Color adminPrimary = Color(0xFF1565C0);
  static const Color adminSecondary = Color(0xFF0D47A1);
  static const Color adminAccent = Color(0xFF2196F3);
  static const Color adminSuccess = Color(0xFF4CAF50);
  static const Color adminWarning = Color(0xFFFF9800);
  static const Color adminError = Color(0xFFF44336);
  
  // 📱 Configuración de interfaz
  static const double adminCardRadius = 12.0;
  static const double adminSpacing = 16.0;
  static const EdgeInsets adminPadding = EdgeInsets.all(20.0);
  
  // 🔧 Configuración de funcionalidades
  static const int maxRecentActivities = 10;
  static const int reportsCacheMinutes = 30;
  static const bool enableAuditLog = true;
  
  // 📊 Métricas por defecto
  static const List<String> defaultMetrics = [
    'total_users',
    'daily_reservations',
    'court_occupation',
    'revenue',
  ];
}

// 🔧 Clase modelo para funciones administrativas
class AdminFunction {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final String route;
  final String permission;
  
  const AdminFunction({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.route,
    required this.permission,
  });
  
  // Convertir a Map para serialización
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'route': route,
      'permission': permission,
    };
  }
  
  // Crear desde Map
  factory AdminFunction.fromMap(Map<String, dynamic> map) {
    return AdminFunction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: Icons.help_outline, // Icono por defecto
      description: map['description'] ?? '',
      route: map['route'] ?? '',
      permission: map['permission'] ?? '',
    );
  }
}

// 🔑 Enum para niveles de permisos
enum AdminPermissionLevel {
  readOnly,
  moderator,
  admin,
  superAdmin,
}

// 📊 Clase para métricas del dashboard
class AdminMetric {
  final String id;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double percentage;
  final bool isPositive;
  
  const AdminMetric({
    required this.id,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.percentage = 0.0,
    this.isPositive = true,
  });
}

// 🔔 Clase para notificaciones admin
class AdminNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final AdminNotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;
  
  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });
}

enum AdminNotificationType {
  info,
  warning,
  error,
  success,
  urgent,
}