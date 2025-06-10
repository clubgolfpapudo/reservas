// lib/core/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html; // 🔥 NUEVO: Para leer parámetros de URL

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

  /// 🔥 ACTUALIZADO: Obtiene el email del usuario actual
  /// Primero intenta leer de la URL, luego usa el configurado, luego fallback
  static Future<String> getCurrentUserEmail() async {
    // 1. 🔥 NUEVO: Intentar leer email de la URL primero
    try {
      final uri = Uri.parse(html.window.location.href);
      
      // 🐛 DEBUG DETALLADO - AGREGAR ESTAS LÍNEAS:
      print('🔍 URL completa: ${html.window.location.href}');
      print('🔍 URI parseada: $uri');
      print('🔍 Query string: ${uri.query}');
      print('🔍 Todos los parámetros: ${uri.queryParameters}');
      print('🔍 Parámetro email específico: ${uri.queryParameters['email']}');
      
      final emailFromUrl = uri.queryParameters['email'];
      
      if (emailFromUrl != null && emailFromUrl.isNotEmpty) {
        print('✅ Email obtenido de URL: $emailFromUrl');
        _currentUserEmail = emailFromUrl; // Guardarlo en memoria
        return emailFromUrl;
      } else {
        print('❌ Email no encontrado en URL o está vacío');
      }
    } catch (e) {
      print('⚠️ Error leyendo URL: $e');
    }
    
    // 2. Si ya está configurado en memoria, usarlo
    if (_currentUserEmail != null) {
      print('✅ Email obtenido de memoria: $_currentUserEmail');
      return _currentUserEmail!;
    }
    
    // 3. 🔄 Fallback temporal para desarrollo
    print('⚠️ Usuario no configurado, usando fallback');
    return 'felipe@garciab.cl';
  }

  /// 🔥 CORREGIDO: Obtiene el nombre del usuario actual
  static Future<String> getCurrentUserName() async {
    if (_currentUserName != null) {
      return _currentUserName!;
    }
    
    // Si no hay nombre, intentar obtenerlo del email
    final email = await getCurrentUserEmail();
    _currentUserName = await _getUserNameFromEmail(email);
    
    return _currentUserName ?? 'USUARIO';
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

  /// 🔥 CORREGIDO: Inicializar usuario desde URL (llamar en main.dart)
  static Future<void> initializeFromUrl() async {
    try {
      final email = await getCurrentUserEmail();
      print('🚀 Inicializando usuario desde URL: $email');
      
      // Intentar buscar el usuario en Firebase o usar datos de prueba
      final userData = await getUserByEmail(email);
      if (userData != null) {
        setCurrentUser(userData['email']!, userData['name']!);
      } else {
        // Si no existe en Firebase, buscar en mapeo local
        final mappedName = await _getUserNameFromEmail(email);
        setCurrentUser(email, mappedName);
      }
    } catch (e) {
      print('❌ Error inicializando usuario desde URL: $e');
    }
  }

  /// 🔥 NUEVO: Buscar nombre basado en email
  static Future<String> _getUserNameFromEmail(String email) async {
    // Mapeo de emails conocidos
    final emailToName = {
      'anita@buzeta.cl': 'ANA M. BELMAR P.',
      'felipe@garciab.cl': 'FELIPE GARCIA B.',
      'clara@garciab.cl': 'CLARA PARDO B.',
      'fgarcia88@hotmail.com': 'JUAN F. GONZALEZ P.',
      'fgarciabenitez@gmail.com': 'FELIPE GARCIA',
    };
    
    return emailToName[email] ?? email.split('@')[0].toUpperCase();
  }

  /// Lista de usuarios de prueba (mantener para compatibilidad)
  static const Map<String, String> testUsers = {
    'felipe@garciab.cl': 'FELIPE GARCIA',
    'ana@buzeta.cl': 'ANA M BELMAR P',
    'clara@garciab.cl': 'CLARA PARDO B',
    'juan@hotmail.com': 'JUAN F GONZALEZ P',
    'test@gmail.com': 'USUARIO DE PRUEBA', // Para testing
  };
}