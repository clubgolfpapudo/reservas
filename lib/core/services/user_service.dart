// ACTUALIZA user_service.dart para que sea dinámico:

// lib/core/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // 🔥 USUARIO ACTUAL CONFIGURABLE (no hardcodeado)
  static String? _currentUserEmail;
  static String? _currentUserName;

  /// 🚀 NUEVO: Configurar usuario actual (llamar al inicio de la app)
  static void setCurrentUser(String email, String name) {
    _currentUserEmail = email;
    _currentUserName = name;
    print('✅ Usuario actual configurado: $name ($email)');
  }

  /// Obtiene el email del usuario actual
  static Future<String> getCurrentUserEmail() async {
    if (_currentUserEmail != null) {
      return _currentUserEmail!;
    }
    
    // 🔄 Fallback temporal para desarrollo
    print('⚠️ Usuario no configurado, usando fallback');
    return 'fgarciabenitez@gmail.com';
  }

  /// Obtiene el nombre del usuario actual
  static Future<String> getCurrentUserName() async {
    if (_currentUserName != null) {
      return _currentUserName!;
    }
    
    // 🔄 Fallback temporal para desarrollo
    print('⚠️ Usuario no configurado, usando fallback');
    return 'FELIPE GARCIA';
  }

  /// 🔥 NUEVO: Buscar usuario por email en Firebase
  static Future<Map<String, String>?> getUserByEmail(String email) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      final QuerySnapshot snapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return {
          'name': data['name']?.toString() ?? '',
          'email': data['email']?.toString() ?? '',
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Error buscando usuario por email: $e');
      return null;
    }
  }

  /// 🔥 NUEVO: Seleccionar usuario actual de la lista
  static Future<bool> selectUserFromFirebase(String email) async {
    try {
      final userData = await getUserByEmail(email);
      
      if (userData != null) {
        setCurrentUser(userData['email']!, userData['name']!);
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error seleccionando usuario: $e');
      return false;
    }
  }

  /// Lista de usuarios de prueba (mantener para compatibilidad)
  static const Map<String, String> testUsers = {
    'felipe@garciab.cl': 'FELIPE GARCIA',
    'ana@buzeta.cl': 'ANA M BELMAR P',
    'clara@garciab.cl': 'CLARA PARDO B',
    'juan@hotmail.com': 'JUAN F GONZALEZ P',
  };
}