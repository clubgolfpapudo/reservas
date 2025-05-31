// lib/core/services/user_service.dart
class UserService {
  static const String _defaultEmail = 'felipe@garciab.cl';
  static const String _defaultName = 'FELIPE GARCIA';

  /// Obtiene el email del usuario actual (versión simplificada)
  static Future<String> getCurrentUserEmail() async {
    // Por ahora retornamos email fijo para testing
    return _defaultEmail;
  }

  /// Obtiene el nombre del usuario actual  
  static Future<String> getCurrentUserName() async {
    return _defaultName;
  }

  /// Lista de usuarios de prueba
  static const Map<String, String> testUsers = {
    'felipe@garciab.cl': 'FELIPE GARCIA',
    'ana@buzeta.cl': 'ANA M BELMAR P',
    'clara@garciab.cl': 'CLARA PARDO B',
    'juan@hotmail.com': 'JUAN F GONZALEZ P',
  };
}