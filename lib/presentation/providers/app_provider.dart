// lib/presentation/providers/app_provider.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_constants.dart';

/// Provider que maneja el estado global de la aplicación
class AppProvider extends ChangeNotifier {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADO GLOBAL DE LA APP
  // ═══════════════════════════════════════════════════════════════════════════

  // Estado de conectividad
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Estado de inicialización
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Estado de carga global
  bool _isGlobalLoading = false;
  bool get isGlobalLoading => _isGlobalLoading;

  // Tema actual
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Índice de navegación actual
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // Configuraciones de la app
  bool _maintenanceMode = false;
  bool get maintenanceMode => _maintenanceMode;

  String _appVersion = AppConstants.appVersion;
  String get appVersion => _appVersion;

  // Mensaje de anuncio global
  String? _announcementMessage;
  String? get announcementMessage => _announcementMessage;

  bool _showAnnouncement = false;
  bool get showAnnouncement => _showAnnouncement;

  // Error global
  String? _globalError;
  String? get globalError => _globalError;

  // Estado de sincronización
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicializa la aplicación
  Future<void> initializeApp() async {
    try {
      _setGlobalLoading(true);
      
      // Verificar conectividad
      await _checkConnectivity();
      
      // Configurar listener de conectividad
      _setupConnectivityListener();
      
      // Cargar configuraciones
      await _loadAppSettings();
      
      // Verificar versión de la app
      await _checkAppVersion();
      
      _isInitialized = true;
      _clearGlobalError();
      
    } catch (e) {
      _setGlobalError('Error al inicializar la aplicación: $e');
    } finally {
      _setGlobalLoading(false);
    }
  }

  /// Verifica la conectividad actual
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _isConnected = false;
    }
  }

  /// Configura el listener de cambios de conectividad
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;
      
      if (!wasConnected && _isConnected) {
        // Se reconectó - sincronizar datos
        _syncDataAfterReconnection();
      }
      
      notifyListeners();
    });
  }

  /// Carga configuraciones de la aplicación
  Future<void> _loadAppSettings() async {
    try {
      // En una implementación real, cargaría desde Firebase Settings
      // Por ahora usamos valores por defecto
      _maintenanceMode = false;
      _appVersion = AppConstants.appVersion;
      _announcementMessage = null;
      _showAnnouncement = false;
    } catch (e) {
      // Usar valores por defecto en caso de error
    }
  }

  /// Verifica si la versión de la app es compatible
  Future<void> _checkAppVersion() async {
    try {
      // En una implementación real, compararía con versión requerida en Firebase
      // Por ahora no hace nada
    } catch (e) {
      // Manejar error de versión
    }
  }

  /// Sincroniza datos después de reconectarse
  Future<void> _syncDataAfterReconnection() async {
    if (!_isConnected) return;
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      // Aquí se implementaría la lógica de sincronización
      await Future.delayed(const Duration(seconds: 2)); // Simulación
      
      _lastSyncTime = DateTime.now();
      
    } catch (e) {
      _setGlobalError('Error al sincronizar datos: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE NAVEGACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cambia el índice de navegación actual
  void setNavIndex(int index) {
    if (index != _currentNavIndex) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  /// Resetea la navegación al inicio
  void resetNavigation() {
    _currentNavIndex = 0;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE TEMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cambia el tema de la aplicación
  void setThemeMode(ThemeMode mode) {
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
      _saveThemePreference(mode);
    }
  }

  /// Alterna entre tema claro y oscuro
  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    setThemeMode(newMode);
  }

  /// Guarda la preferencia de tema
  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      // En una implementación real, guardaría en SharedPreferences
      // Por ahora no hace nada
    } catch (e) {
      // Manejar error al guardar preferencia
    }
  }

  /// Carga la preferencia de tema guardada
  Future<void> loadThemePreference() async {
    try {
      // En una implementación real, cargaría desde SharedPreferences
      // Por ahora usa tema claro por defecto
      _themeMode = ThemeMode.light;
    } catch (e) {
      _themeMode = ThemeMode.light;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Actualiza el modo de mantenimiento
  void setMaintenanceMode(bool enabled) {
    if (enabled != _maintenanceMode) {
      _maintenanceMode = enabled;
      notifyListeners();
    }
  }

  /// Actualiza el mensaje de anuncio
  void setAnnouncement(String? message, bool show) {
    _announcementMessage = message;
    _showAnnouncement = show;
    notifyListeners();
  }

  /// Oculta el anuncio actual
  void hideAnnouncement() {
    _showAnnouncement = false;
    notifyListeners();
  }

  /// Actualiza la versión de la app
  void setAppVersion(String version) {
    if (version != _appVersion) {
      _appVersion = version;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE SINCRONIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fuerza una sincronización manual
  Future<void> forcSync() async {
    if (_isSyncing || !_isConnected) return;
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      // Aquí se implementaría la lógica de sincronización forzada
      await Future.delayed(const Duration(seconds: 3)); // Simulación
      
      _lastSyncTime = DateTime.now();
      _clearGlobalError();
      
    } catch (e) {
      _setGlobalError('Error en sincronización: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Obtiene el estado de sincronización como texto
  String get syncStatusText {
    if (_isSyncing) {
      return 'Sincronizando...';
    }
    
    if (_lastSyncTime == null) {
      return 'No sincronizado';
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return 'Sincronizado hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Sincronizado hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Sincronizado hace ${difference.inHours} h';
    } else {
      return 'Sincronizado hace ${difference.inDays} días';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si la app está en un estado saludable
  bool get isAppHealthy {
    return _isConnected && 
           _isInitialized && 
           !_maintenanceMode && 
           _globalError == null;
  }

  /// Obtiene el color del estado de conectividad
  Color get connectivityColor {
    return _isConnected ? AppColors.success : AppColors.error;
  }

  /// Obtiene el icono del estado de conectividad
  IconData get connectivityIcon {
    return _isConnected ? Icons.wifi : Icons.wifi_off;
  }

  /// Obtiene mensaje del estado de la app
  String get appStatusMessage {
    if (_maintenanceMode) {
      return 'Aplicación en mantenimiento';
    }
    
    if (!_isConnected) {
      return AppConstants.noConnectionMessage;
    }
    
    if (_globalError != null) {
      return _globalError!;
    }
    
    if (_isSyncing) {
      return 'Sincronizando datos...';
    }
    
    return 'Todo funcionando correctamente';
  }

  /// Reinicia el estado de la aplicación
  Future<void> resetApp() async {
    _currentNavIndex = 0;
    _globalError = null;
    _lastSyncTime = null;
    _isSyncing = false;
    
    await initializeApp();
  }

  /// Maneja errores no capturados
  void handleUncaughtError(dynamic error, StackTrace stackTrace) {
    _setGlobalError('Error inesperado: $error');
    
    // En una implementación real, enviaría el error a un servicio de crash reporting
    debugPrint('Uncaught error: $error\n$stackTrace');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS DE ESTADO
  // ═══════════════════════════════════════════════════════════════════════════

  void _setGlobalLoading(bool loading) {
    _isGlobalLoading = loading;
    notifyListeners();
  }

  void _setGlobalError(String error) {
    _globalError = error;
    notifyListeners();
  }

  void _clearGlobalError() {
    _globalError = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE LIMPIEZA
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    // Limpiar listeners y recursos
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMPORTACIONES PARA COLORES
// ═══════════════════════════════════════════════════════════════════════════════

// Importar desde el tema
import '../../core/theme/app_theme.dart';