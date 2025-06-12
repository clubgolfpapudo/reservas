// lib/core/services/user_service.dart - VERSIÓN LIMPIA Y FUNCIONAL
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Solo importar dart:html en web con conditional import
import 'dart:html' as html show window;

class UserService {
  // 🔥 USUARIO ACTUAL CONFIGURABLE (no hardcodeado)
  static String? _currentUserEmail;
  static String? _currentUserName;

  /// 🚀 NUEVO: Inicializar desde URL (para main.dart)
  static Future<void> initializeFromUrl() async {
    if (kIsWeb) {
      try {
        print('🌐 Inicializando UserService desde URL...');
        final email = await getCurrentUserEmail();
        final name = await getCurrentUserName();
        print('✅ Usuario inicializado desde URL: $name ($email)');
      } catch (e) {
        print('⚠️ Error inicializando desde URL: $e');
      }
    } else {
      print('📱 UserService: Ejecutando en móvil, no hay URL que procesar');
    }
  }

  /// 🚀 Configurar usuario actual (llamar al inicio de la app)
  static void setCurrentUser(String email, String name) {
    _currentUserEmail = email;
    _currentUserName = name;
    print('✅ Usuario actual configurado: $name ($email)');
  }

  /// 🔥 ACTUALIZADO: Obtiene el email del usuario actual
  /// Primero intenta leer de la URL, luego usa el configurado, luego fallback
  static Future<String> getCurrentUserEmail() async {
    // 1. 🔥 NUEVO: Intentar leer email de la URL primero (SOLO EN WEB)
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        // 🐛 DEBUG DETALLADO
        print('🔍 URL completa: ${html.window.location.href}');
        print('🔍 URI parseada: $uri');
        print('🔍 Query string: ${uri.query}');
        print('🔍 Todos los parámetros: ${uri.queryParameters}');
        print('🔍 Parámetro email específico: ${uri.queryParameters['email']}');
        
        // 🚀 NUEVO DEBUG EXTRA - Agregar estas líneas:
        print('🔍 Location search: ${html.window.location.search}');
        print('🔍 Location href: ${html.window.location.href}');
        print('🔍 Hash: ${html.window.location.hash}');
        uri.queryParameters.forEach((key, value) {
          print('🔍 Parámetro encontrado: "$key" = "$value"');
        });

        final emailFromUrl = uri.queryParameters['email'];
        if (emailFromUrl != null && emailFromUrl.isNotEmpty) {
          _currentUserEmail = emailFromUrl; // Actualizar usuario actual
          print('✅ Email obtenido de URL: $emailFromUrl');
          return emailFromUrl;
        }
      } catch (e) {
        print('⚠️ Error leyendo email de URL: $e');
      }
    }

    // 2. Si hay usuario configurado manualmente, usarlo
    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      print('✅ Email desde configuración manual: $_currentUserEmail');
      return _currentUserEmail!;
    }

    // 3. 📱 FALLBACK ANDROID/MÓVIL
    if (!kIsWeb) {
      const fallbackEmail = 'usuario.android@cgp.cl';
      print('📱 Android: Usando email por defecto: $fallbackEmail');
      return fallbackEmail;
    }

    // 4. Fallback final para web
    const fallbackEmail = 'fgarciabenitez@gmail.com';
    print('🔄 Usando email fallback: $fallbackEmail');
    return fallbackEmail;
  }

  static Future<String> getDisplayNameFromFirestore(String email) async {
    try {
      print('🔍 Consultando Firestore para email: $email');
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final displayName = data['displayName'] as String?;
        
        if (displayName != null && displayName.isNotEmpty) {
          print('✅ DisplayName encontrado: $displayName');
          return displayName;
        }
      }
      
      print('⚠️ Usuario no encontrado en Firestore: $email');
      return 'USUARIO NO ENCONTRADO';
      
    } catch (e) {
      print('❌ Error consultando Firestore: $e');
      return 'ERROR DE CONEXIÓN';
    }
  }

  static Future<String> getCurrentUserName() async {
    print('🎯 DEBUG getName: Iniciando getCurrentUserName()');
    
    // 1. Obtener email primero
    final email = await getCurrentUserEmail();
    print('🎯 DEBUG getName: Email obtenido: "$email"');
    
    // 2. Si hay usuario configurado manualmente, usarlo
    if (_currentUserName != null && _currentUserName!.isNotEmpty) {
      print('✅ Nombre desde configuración manual: $_currentUserName');
      return _currentUserName!;
    }

    // 3. Intentar leer nombre de la URL primero (SOLO EN WEB)
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        final nameFromUrl = uri.queryParameters['name'];
        if (nameFromUrl != null && nameFromUrl.isNotEmpty) {
          final decodedName = Uri.decodeComponent(nameFromUrl).toUpperCase();
          _currentUserName = decodedName;
          print('✅ Nombre obtenido de URL: $decodedName');
          return decodedName;
        }
      } catch (e) {
        print('⚠️ Error leyendo nombre de URL: $e');
      }
    }

    // 4. 🔥 NUEVO: Consultar Firestore por email
    if (email != null && email.isNotEmpty && email != 'unknown') {
      final displayName = await getDisplayNameFromFirestore(email);
      if (displayName != 'USUARIO NO ENCONTRADO' && displayName != 'ERROR DE CONEXIÓN') {
        _currentUserName = displayName;
        print('🔥 Nombre obtenido de Firestore: $displayName');
        return displayName;
      }
    }

    // 5. Fallback para móvil
    if (!kIsWeb) {
      const fallbackName = 'USUARIO ANDROID';
      return fallbackName;
    }

    // 6. Fallback final
    const fallbackName = 'USUARIO DESCONOCIDO';
    print('⚠️ Usando fallback: $fallbackName');
    return fallbackName;
  }

  /// 🔥 FUNCIONES AUXILIARES para operaciones de Firebase
  static Future<bool> userExists(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando si usuario existe: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo datos del usuario: $e');
      return null;
    }
  }
}