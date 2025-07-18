/// lib/core/services/user_service.dart
/// 
/// PROPÓSITO:
/// Servicio de alto nivel que abstrae la lógica de obtención del usuario actual
/// para el sistema híbrido GAS-Flutter. Maneja múltiples fuentes de datos para
/// determinar quién es el usuario actual que está utilizando la aplicación:
/// - Parámetros de URL desde integración GAS (sistema híbrido actual)
/// - Configuración manual para testing y desarrollo
/// - Consultas directas a Firebase Firestore cuando sea necesario
/// - Fallbacks robustos para diferentes plataformas (Web, Android, iOS)
/// 
/// MOTIVO DE EXISTENCIA:
/// El sistema actual es híbrido donde los usuarios ingresan desde GAS y son
/// redirigidos a Flutter con parámetros de URL. Este servicio centraliza toda
/// la lógica compleja de detectar el usuario actual desde múltiples fuentes
/// posibles y proporciona una API limpia para el resto del sistema.
/// 
/// INTEGRACIÓN CON SISTEMA HÍBRIDO:
/// 1. Usuario ingresa email en sistema GAS (pageLogin.html)
/// 2. Selecciona "Pádel" y es redirigido a Flutter Web con parámetros URL
/// 3. UserService detecta email/nombre desde URL automáticamente
/// 4. Auto-completa organizador en formularios de reserva
/// 5. Proporciona datos para validaciones y sistema de emails
/// 
/// FUENTES DE DATOS MANEJADAS (en orden de prioridad):
/// 1. **URL Parameters**: email y name desde sistema GAS (producción)
/// 2. **Configuración Manual**: setCurrentUser() para desarrollo/testing
/// 3. **Firebase Firestore**: Consulta directa por email cuando sea necesario
/// 4. **Fallbacks por Plataforma**: Web vs Android/iOS con valores apropiados
/// 
/// CASOS DE USO PRINCIPALES:
/// - Auto-completado del organizador en formularios de reserva
/// - Identificación del usuario actual para validaciones de conflictos
/// - Integración con sistema de emails (remitente de confirmaciones)
/// - Testing y desarrollo con usuarios configurables
/// - Transición futura a autenticación Flutter nativa (sin GAS)
/// 
/// COMPATIBILIDAD MULTIPLATAFORMA:
/// - **Web**: Lectura de URL parameters + fallbacks web
/// - **Android/iOS**: Configuración manual + fallbacks móvil
/// - **Desarrollo**: Sistema flexible para testing offline
/// - **Futuro**: Base para migración a Firebase Auth completo
/// 
/// DEBUGGING Y LOGS:
/// - Logs detallados de cada paso del proceso de detección
/// - Información de URL parsing para debugging de integración GAS
/// - Identificación clara de qué fuente de datos se está usando
/// - Warnings apropiados cuando se usan fallbacks

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// Importación condicional para dart:html solo en plataforma Web
import 'dart:html' as html show window;

/// Servicio de alto nivel para gestión del usuario actual
/// 
/// Centraliza la lógica compleja de detectar el usuario actual desde múltiples
/// fuentes de datos en el sistema híbrido GAS-Flutter. Proporciona API limpia
/// y consistente para el resto de la aplicación independientemente de la fuente
/// de datos utilizada.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// - Detección automática de usuario desde URL parameters (integración GAS)
/// - Configuración manual para desarrollo y testing
/// - Consultas a Firebase como fuente de datos secundaria
/// - Fallbacks robustos por plataforma
/// - Logging detallado para debugging de integración
/// - Compatibilidad con futuras migraciones de autenticación
class UserService {
  /// Email del usuario actual cacheado en memoria
  /// Puede ser establecido desde URL, configuración manual, o consulta Firebase
  static String? _currentUserEmail;
  
  /// Nombre del usuario actual cacheado en memoria
  /// Correspondiente al email actual, usado para auto-completado
  static String? _currentUserName;

  /// Inicializa el servicio desde parámetros de URL al arrancar la aplicación
  /// 
  /// Método llamado desde main.dart para detectar automáticamente el usuario
  /// desde URL parameters cuando la app es abierta desde el sistema GAS.
  /// 
  /// PROCESO DE INICIALIZACIÓN:
  /// 1. Verifica que esté ejecutándose en plataforma Web
  /// 2. Extrae email y nombre desde URL parameters
  /// 3. Configura usuario actual si los parámetros son válidos
  /// 4. Maneja errores gracefully con fallbacks apropiados
  /// 
  /// INTEGRACIÓN GAS:
  /// URL típica: https://domain.com/app?email=user@club.cl&name=USER%20NAME
  /// 
  /// @sideEffect Actualiza _currentUserEmail y _currentUserName si detecta datos válidos
  /// @throws No propaga excepciones, maneja errores internamente con logs
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

  /// Configura manualmente el usuario actual
  /// 
  /// Utilizado para development, testing, o cuando se conocen los datos
  /// del usuario desde otra fuente (ej: autenticación Flutter futura).
  /// 
  /// @param email Email válido del usuario
  /// @param name Nombre formateado del usuario
  /// @sideEffect Actualiza variables estáticas de usuario actual
  static void setCurrentUser(String email, String name) {
    _currentUserEmail = email;
    _currentUserName = name;
    print('✅ Usuario actual configurado: $name ($email)');
  }

  /// **MÉTODO PRINCIPAL** - Obtiene email del usuario actual con fallbacks múltiples
  /// 
  /// Implementa algoritmo de detección de usuario con 4 niveles de fallback:
  /// 1. **URL Parameters** (Web): Extrae email desde query string de URL
  /// 2. **Configuración Manual**: Usa email establecido con setCurrentUser()
  /// 3. **Fallback Móvil**: Email por defecto para plataformas Android/iOS
  /// 4. **Fallback Web**: Email por defecto para Web cuando no hay URL params
  /// 
  /// URL PARSING DETALLADO:
  /// - Parsea URL completa de la ventana del navegador
  /// - Extrae query parameters usando Uri.queryParameters
  /// - Busca específicamente parámetro 'email'
  /// - Actualiza estado interno si encuentra email válido
  /// - Logs detallados para debugging de integración GAS
  /// 
  /// DEBUGGING:
  /// Incluye logs extensivos de cada paso del proceso:
  /// - URL completa parseada
  /// - Todos los query parameters encontrados
  /// - Proceso de extracción del email específico
  /// - Fuente final de datos utilizada
  /// 
  /// @return Email del usuario actual (nunca null)
  /// @platform Web: Prioriza URL parameters, fallback a configuración manual
  /// @platform Mobile: Usa configuración manual o fallback específico móvil
  static Future<String> getCurrentUserEmail() async {
    // 1. PRIORIDAD MÁXIMA: URL Parameters (solo en Web)
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        
        // Debugging detallado para troubleshooting integración GAS
        print('🔍 URL completa: ${html.window.location.href}');
        print('🔍 URI parseada: $uri');
        print('🔍 Query string: ${uri.query}');
        print('🔍 Todos los parámetros: ${uri.queryParameters}');
        print('🔍 Parámetro email específico: ${uri.queryParameters['email']}');
        print('🔍 Location search: ${html.window.location.search}');
        print('🔍 Location href: ${html.window.location.href}');
        print('🔍 Hash: ${html.window.location.hash}');
        
        // Log de todos los parámetros encontrados para debugging
        uri.queryParameters.forEach((key, value) {
          print('🔍 Parámetro encontrado: "$key" = "$value"');
        });

        final emailFromUrl = uri.queryParameters['email'];
        if (emailFromUrl != null && emailFromUrl.isNotEmpty) {
          _currentUserEmail = emailFromUrl; // Cachear para futuras llamadas
          print('✅ Email obtenido de URL: $emailFromUrl');
          return emailFromUrl;
        }
      } catch (e) {
        print('⚠️ Error leyendo email de URL: $e');
      }
    }

    // 2. CONFIGURACIÓN MANUAL: Usuario establecido programáticamente
    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      print('✅ Email desde configuración manual: $_currentUserEmail');
      return _currentUserEmail!;
    }

    // 3. FALLBACK MÓVIL: Email específico para plataformas Android/iOS
    if (!kIsWeb) {
      const fallbackEmail = 'usuario.android@cgp.cl';
      print('📱 Android: Usando email por defecto: $fallbackEmail');
      return fallbackEmail;
    }

    // 4. FALLBACK WEB: Email por defecto cuando no hay URL parameters
    const fallbackEmail = 'fgarciabenitez@gmail.com';
    print('🔄 Usando email fallback: $fallbackEmail');
    return fallbackEmail;
  }

  /// Consulta Firebase Firestore para obtener displayName por email
  /// 
  /// Método auxiliar que realiza consulta directa a la colección 'users'
  /// para obtener el displayName correspondiente a un email específico.
  /// Utilizado como fuente de datos secundaria cuando no hay URL parameters.
  /// 
  /// PROCESO:
  /// 1. Query a colección 'users' con filtro por email exacto
  /// 2. Extrae campo 'displayName' del documento encontrado
  /// 3. Valida que el displayName no esté vacío
  /// 4. Retorna valor encontrado o mensaje de error apropiado
  /// 
  /// @param email Email para buscar en Firebase
  /// @return DisplayName encontrado o mensaje de error descriptivo
  /// @throws No propaga excepciones, retorna mensajes de error como strings
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

  /// **MÉTODO PRINCIPAL** - Obtiene nombre del usuario actual con fallbacks múltiples
  /// 
  /// Algoritmo similar a getCurrentUserEmail() pero para nombres, con fuentes adicionales:
  /// 1. **Configuración Manual**: Nombre establecido con setCurrentUser()
  /// 2. **URL Parameters** (Web): Extrae 'name' desde query string y decodifica
  /// 3. **Firebase Firestore**: Consulta displayName por email como fallback
  /// 4. **Fallbacks por Plataforma**: Nombres apropiados para cada plataforma
  /// 
  /// PROCESAMIENTO DE URL:
  /// - Extrae parámetro 'name' de URL
  /// - Aplica Uri.decodeComponent() para manejar URL encoding
  /// - Convierte a mayúsculas para consistencia con formato del sistema
  /// - Cachea resultado para futuras llamadas
  /// 
  /// INTEGRACIÓN FIREBASE:
  /// - Usa email obtenido de getCurrentUserEmail()
  /// - Realiza consulta a Firestore si no hay nombre desde URL
  /// - Maneja casos de usuario no encontrado gracefully
  /// - Valida que el displayName sea válido antes de retornar
  /// 
  /// @return Nombre formateado del usuario actual (nunca null)
  /// @debug Incluye logs detallados del proceso de detección
  static Future<String> getCurrentUserName() async {
    print('🎯 DEBUG getName: Iniciando getCurrentUserName()');
    
    // 1. Obtener email primero (necesario para consulta Firebase)
    final email = await getCurrentUserEmail();
    print('🎯 DEBUG getName: Email obtenido: "$email"');
    
    // 2. CONFIGURACIÓN MANUAL: Nombre establecido programáticamente
    if (_currentUserName != null && _currentUserName!.isNotEmpty) {
      print('✅ Nombre desde configuración manual: $_currentUserName');
      return _currentUserName!;
    }

    // 3. URL PARAMETERS: Extraer nombre desde query string (solo Web)
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        final nameFromUrl = uri.queryParameters['name'];
        if (nameFromUrl != null && nameFromUrl.isNotEmpty) {
          // Decodificar URL encoding (%20 → espacios) y normalizar formato
          final decodedName = Uri.decodeComponent(nameFromUrl).toUpperCase();
          _currentUserName = decodedName; // Cachear para futuras llamadas
          print('✅ Nombre obtenido de URL: $decodedName');
          return decodedName;
        }
      } catch (e) {
        print('⚠️ Error leyendo nombre de URL: $e');
      }
    }

    // 4. FIREBASE FIRESTORE: Consulta displayName por email
    if (email.isNotEmpty && email != 'unknown') {
      final displayName = await getDisplayNameFromFirestore(email);
      if (displayName != 'USUARIO NO ENCONTRADO' && displayName != 'ERROR DE CONEXIÓN') {
        _currentUserName = displayName; // Cachear resultado exitoso
        print('🔥 Nombre obtenido de Firestore: $displayName');
        return displayName;
      }
    }

    // 5. FALLBACK MÓVIL: Nombre específico para plataformas Android/iOS
    if (!kIsWeb) {
      const fallbackName = 'USUARIO ANDROID';
      return fallbackName;
    }

    // 6. FALLBACK WEB FINAL: Cuando todas las fuentes fallan
    const fallbackName = 'USUARIO DESCONOCIDO';
    print('⚠️ Usando fallback: $fallbackName');
    return fallbackName;
  }

  /// Verifica si un usuario existe en la base de datos de Firebase
  /// 
  /// Método auxiliar para validaciones que requieren confirmar la existencia
  /// de un usuario antes de realizar operaciones (ej: agregar a reservas).
  /// 
  /// PROCESO:
  /// 1. Query a colección 'users' con filtro where por email
  /// 2. Limita resultado a 1 documento para eficiencia
  /// 3. Verifica si el QuerySnapshot contiene documentos
  /// 4. Retorna boolean indicando existencia
  /// 
  /// CASOS DE USO:
  /// - Validación antes de agregar usuarios a reservas
  /// - Verificación de emails en formularios
  /// - Lógica de autorización y permisos
  /// - Debugging de problemas de usuarios
  /// 
  /// @param email Email a verificar en la base de datos
  /// @return true si el usuario existe, false en caso contrario
  /// @throws No propaga excepciones, retorna false en caso de error
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

  /// Obtiene datos completos de un usuario desde Firebase
  /// 
  /// Método auxiliar que retorna todos los campos disponibles de un usuario
  /// específico. Útil para operaciones que requieren información detallada
  /// más allá del nombre y email básicos.
  /// 
  /// DATOS RETORNADOS:
  /// - Todos los campos disponibles en el documento Firebase
  /// - Estructura completa incluyendo metadatos de sincronización
  /// - Información de contacto (teléfonos, direcciones)
  /// - Datos demográficos y de membresía del club
  /// - Timestamps de última actualización
  /// 
  /// CASOS DE USO:
  /// - Mapeo de teléfonos para sistema de emails
  /// - Validación de roles y permisos
  /// - Información para reportes y analytics
  /// - Debugging de problemas de datos específicos
  /// - Auditoría de información de usuarios
  /// 
  /// @param email Email del usuario a consultar
  /// @return Map con todos los datos del usuario o null si no existe
  /// @throws No propaga excepciones, retorna null en caso de error
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

/// NOTAS TÉCNICAS PARA MANTENIMIENTO FUTURO:
/// 
/// 1. **Transición Post-GAS**: Cuando se elimine el sistema GAS, reemplazar
///    la lógica de URL parameters con Firebase Auth completo. Mantener la
///    estructura de fallbacks para compatibilidad durante transición.
/// 
/// 2. **Caché Local**: Considerar implementar caché persistente local para
///    datos de usuario frecuentemente accedidos, especialmente en móvil.
/// 
/// 3. **Validación de Datos**: Los métodos actuales asumen que los datos
///    en Firebase son válidos. Considerar agregar validaciones adicionales
///    según evolucionen los requisitos de calidad de datos.
/// 
/// 4. **Error Handling**: Los métodos nunca propagan excepciones hacia arriba,
///    siempre usan fallbacks. Evaluar si esto es apropiado para todos los casos
///    de uso futuros del sistema.
/// 
/// 5. **Performance**: Las consultas a Firestore son síncronas y pueden ser
///    lentas en conexiones pobres. Considerar implementar timeouts y caché
///    para mejor UX en móvil.
/// 
/// 6. **Logging**: Los logs detallados son útiles para debugging pero pueden
///    afectar performance en producción. Considerar sistema de logging
///    configurable por environment.
/// 
/// 7. **Seguridad**: Los URL parameters pueden ser manipulados por usuarios.
///    Cuando se migre a sistema completo Flutter, implementar validación
///    y sanitización apropiada de todos los inputs.
/// 
/// 8. **Testing**: Los fallbacks facilitan testing pero pueden enmascarar
///    problemas reales. Implementar testing específico para cada fuente
///    de datos y sus casos edge.
/// 
/// 9. **Multi-Deporte**: Al extender a Golf/Tenis, considerar si se necesitan
///    parámetros adicionales en URL (sport, courtType) y cómo afectarán
///    la lógica de detección de usuario actual.