/// lib/core/services/user_service.dart
/// 
/// PROPÃ“SITO:
/// Servicio de alto nivel que abstrae la lÃ³gica de obtenciÃ³n del usuario actual
/// para el sistema hÃ­brido GAS-Flutter. Maneja mÃºltiples fuentes de datos para
/// determinar quiÃ©n es el usuario actual que estÃ¡ utilizando la aplicaciÃ³n:
/// - ParÃ¡metros de URL desde integraciÃ³n GAS (sistema hÃ­brido actual)
/// - ConfiguraciÃ³n manual para testing y desarrollo
/// - Consultas directas a Firebase Firestore cuando sea necesario
/// - Fallbacks robustos para diferentes plataformas (Web, Android, iOS)
/// 
/// INTEGRACIÃ“N CON SISTEMA HÃBRIDO:
/// 1. Usuario ingresa email en sistema GAS (pageLogin.html)
/// 2. Selecciona "Pádel" y es redirigido a Flutter Web con parÃ¡metros URL
/// 3. UserService detecta email/nombre desde URL automÃ¡ticamente
/// 4. Auto-completa organizador en formularios de reserva
/// 5. Proporciona datos para validaciones y sistema de emails
/// 
/// FUENTES DE DATOS MANEJADAS (en orden de prioridad):
/// 1. **URL Parameters**: email y name desde sistema GAS (producciÃ³n)
/// 2. **ConfiguraciÃ³n Manual**: setCurrentUser() para desarrollo/testing
/// 3. **Firebase Firestore**: Consulta directa por email cuando sea necesario
/// 4. **Fallbacks por Plataforma**: Web vs Android/iOS con valores apropiados
/// 
/// COMPATIBILIDAD MULTIPLATAFORMA:
/// - **Web**: Lectura de URL parameters + fallbacks web
/// - **Android/iOS**: ConfiguraciÃ³n manual + fallbacks mÃ³vil
/// - **Desarrollo**: Sistema flexible para testing offline
/// - **Futuro**: Base para migraciÃ³n a Firebase Auth completo
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// Solo importar dart:html en web con conditional import
import 'dart:html' as html show window;

/// Servicio de alto nivel para gestiÃ³n del usuario actual
/// 
/// Centraliza la lÃ³gica compleja de detectar el usuario actual desde mÃºltiples
/// fuentes de datos en el sistema hÃ­brido GAS-Flutter. Proporciona API limpia
/// y consistente para el resto de la aplicaciÃ³n independientemente de la fuente
/// de datos utilizada.
/// 
/// CARACTERÃSTICAS PRINCIPALES:
/// - DetecciÃ³n automÃ¡tica de usuario desde URL parameters (integraciÃ³n GAS)
/// - ConfiguraciÃ³n manual para desarrollo y testing
/// - Consultas a Firebase como fuente de datos secundaria
/// - Fallbacks robustos por plataforma
/// - Logging detallado para debugging de integraciÃ³n
/// - Compatibilidad con futuras migraciones de autenticaciÃ³n
class UserService {
  /// Email del usuario actual cacheado en memoria
  /// Puede ser establecido desde URL, configuraciÃ³n manual, o consulta Firebase
  static String? _currentUserEmail;
  /// Nombre del usuario actual cacheado en memoria
  /// Correspondiente al email actual, usado para auto-completado
  static String? _currentUserName;

  /// Inicializa el servicio desde parÃ¡metros de URL al arrancar la aplicaciÃ³n
  /// 
  /// MÃ©todo llamado desde main.dart para detectar automÃ¡ticamente el usuario
  /// desde URL parameters cuando la app es abierta desde el sistema GAS.
  /// 
  /// PROCESO DE INICIALIZACIÃ“N:
  /// 1. Verifica que estÃ© ejecutÃ¡ndose en plataforma Web
  /// 2. Extrae email y nombre desde URL parameters
  /// 3. Configura usuario actual si los parÃ¡metros son vÃ¡lidos
  /// 4. Maneja errores gracefully con fallbacks apropiados
  /// 
  /// INTEGRACIÃ“N GAS:
  /// URL tÃ­pica: https://domain.com/app?email=user@club.cl&name=USER%20NAME
  /// 
  /// @sideEffect Actualiza _currentUserEmail y _currentUserName si detecta datos vÃ¡lidos
  /// @throws No propaga excepciones, maneja errores internamente con logs
  static Future<void> initializeFromUrl() async {
    if (kIsWeb) {
      try {
        // PERF: print('ðŸŒ Inicializando UserService desde URL...');
        final email = await getCurrentUserEmail();
        final name = await getCurrentUserName();
        // PERF: print('âœ… Usuario inicializado desde URL: $name ($email)');
      } catch (e) {
        // PERF: print('âš ï¸ Error inicializando desde URL: $e');
      }
    } else {
      // PERF: print('ðŸ“± UserService: Ejecutando en mÃ³vil, no hay URL que procesar');
    }
  }

  /// Configura manualmente el usuario actual
  /// 
  /// Utilizado para development, testing, o cuando se conocen los datos
  /// del usuario desde otra fuente (ej: autenticaciÃ³n Flutter futura).
  /// 
  /// @param email Email vÃ¡lido del usuario
  /// @param name Nombre formateado del usuario
  /// @sideEffect Actualiza variables estÃ¡ticas de usuario actual
  static void setCurrentUser(String email, String name) {
    _currentUserEmail = email;
    _currentUserName = name;
    // PERF: print('âœ… Usuario actual configurado: $name ($email)');
  }

  /// **MÃ‰TODO PRINCIPAL** - Obtiene email del usuario actual con fallbacks mÃºltiples
  /// 
  /// Implementa algoritmo de detecciÃ³n de usuario con 4 niveles de fallback:
  /// 1. **URL Parameters** (Web): Extrae email desde query string de URL
  /// 2. **ConfiguraciÃ³n Manual**: Usa email establecido con setCurrentUser()
  /// 3. **Fallback MÃ³vil**: Email por defecto para plataformas Android/iOS
  /// 4. **Fallback Web**: Email por defecto para Web cuando no hay URL params
  /// 
  /// URL PARSING DETALLADO:
  /// - Parsea URL completa de la ventana del navegador
  /// - Extrae query parameters usando Uri.queryParameters
  /// - Busca especÃ­ficamente parÃ¡metro 'email'
  /// - Actualiza estado interno si encuentra email vÃ¡lido
  /// - Logs detallados para debugging de integraciÃ³n GAS
  /// 
  /// DEBUGGING:
  /// Incluye logs extensivos de cada paso del proceso:
  /// - URL completa parseada
  /// - Todos los query parameters encontrados
  /// - Proceso de extracciÃ³n del email especÃ­fico
  /// - Fuente final de datos utilizada
  /// 
  /// @return Email del usuario actual (nunca null)
  /// @platform Web: Prioriza URL parameters, fallback a configuraciÃ³n manual
  /// @platform Mobile: Usa configuraciÃ³n manual o fallback especÃ­fico mÃ³vil
  static Future<String> getCurrentUserEmail() async {
    // 1. ðŸ”¥ NUEVO: Intentar leer email de la URL primero (SOLO EN WEB)
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        // ðŸ› DEBUG DETALLADO
        // PERF: print('ðŸ” URL completa: ${html.window.location.href}');
        // PERF: print('ðŸ” URI parseada: $uri');
        // PERF: print('ðŸ” Query string: ${uri.query}');
        // PERF: print('ðŸ” Todos los parÃ¡metros: ${uri.queryParameters}');
        // PERF: print('ðŸ” ParÃ¡metro email especÃ­fico: ${uri.queryParameters['email']}');
        
        // ðŸš€ NUEVO DEBUG EXTRA - Agregar estas lÃ­neas:
        // PERF: print('ðŸ” Location search: ${html.window.location.search}');
        // PERF: print('ðŸ” Location href: ${html.window.location.href}');
        // PERF: print('ðŸ” Hash: ${html.window.location.hash}');
        uri.queryParameters.forEach((key, value) {
          // PERF: print('ðŸ” ParÃ¡metro encontrado: "$key" = "$value"');
        });

        final emailFromUrl = uri.queryParameters['email'];
        if (emailFromUrl != null && emailFromUrl.isNotEmpty) {
          _currentUserEmail = emailFromUrl; // Actualizar usuario actual
          // PERF: print('âœ… Email obtenido de URL: $emailFromUrl');
          return emailFromUrl;
        }
      } catch (e) {
        // PERF: print('âš ï¸ Error leyendo email de URL: $e');
      }
    }

    // 2. Si hay usuario configurado manualmente, usarlo
    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      // PERF: print('âœ… Email desde configuraciÃ³n manual: $_currentUserEmail');
      return _currentUserEmail!;
    }

    // 3. ðŸ“± FALLBACK ANDROID/MÃ“VIL
    if (!kIsWeb) {
      const fallbackEmail = 'usuario.android@cgp.cl';
      // PERF: print('ðŸ“± Android: Usando email por defecto: $fallbackEmail');
      return fallbackEmail;
    }

    // 4. Fallback final para web
    const fallbackEmail = 'fgarciabenitez@gmail.com';
    // PERF: print('ðŸ”„ Usando email fallback: $fallbackEmail');
    return fallbackEmail;
  }

  /// Consulta Firebase Firestore para obtener displayName por email
  /// 
  /// MÃ©todo auxiliar que realiza consulta directa a la colecciÃ³n 'users'
  /// para obtener el displayName correspondiente a un email especÃ­fico.
  /// Utilizado como fuente de datos secundaria cuando no hay URL parameters.
  /// 
  /// PROCESO:
  /// 1. Query a colecciÃ³n 'users' con filtro por email exacto
  /// 2. Extrae campo 'displayName' del documento encontrado
  /// 3. Valida que el displayName no estÃ© vacÃ­o
  /// 4. Retorna valor encontrado o mensaje de error apropiado
  /// 
  /// @param email Email para buscar en Firebase
  /// @return DisplayName encontrado o mensaje de error descriptivo
  /// @throws No propaga excepciones, retorna mensajes de error como strings
  static Future<String> getDisplayNameFromFirestore(String email) async {
    try {
      // PERF: print('ðŸ” Consultando Firestore para email: $email');
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final displayName = data['displayName'] as String?;
        
        if (displayName != null && displayName.isNotEmpty) {
          // PERF: print('âœ… DisplayName encontrado: $displayName');
          return displayName;
        }
      }
      
      // PERF: print('âš ï¸ Usuario no encontrado en Firestore: $email');
      return 'USUARIO NO ENCONTRADO';
      
    } catch (e) {
      // PERF: print('âŒ Error consultando Firestore: $e');
      return 'ERROR DE CONEXIÃ“N';
    }
  }

  /// **MÃ‰TODO PRINCIPAL** - Obtiene nombre del usuario actual con fallbacks mÃºltiples
  /// 
  /// Algoritmo similar a getCurrentUserEmail() pero para nombres, con fuentes adicionales:
  /// 1. **ConfiguraciÃ³n Manual**: Nombre establecido con setCurrentUser()
  /// 2. **URL Parameters** (Web): Extrae 'name' desde query string y decodifica
  /// 3. **Firebase Firestore**: Consulta displayName por email como fallback
  /// 4. **Fallbacks por Plataforma**: Nombres apropiados para cada plataforma
  /// 
  /// PROCESAMIENTO DE URL:
  /// - Extrae parÃ¡metro 'name' de URL
  /// - Aplica Uri.decodeComponent() para manejar URL encoding
  /// - Convierte a mayÃºsculas para consistencia con formato del sistema
  /// - Cachea resultado para futuras llamadas
  /// 
  /// INTEGRACIÃ“N FIREBASE:
  /// - Usa email obtenido de getCurrentUserEmail()
  /// - Realiza consulta a Firestore si no hay nombre desde URL
  /// - Maneja casos de usuario no encontrado gracefully
  /// - Valida que el displayName sea vÃ¡lido antes de retornar
  /// 
  /// @return Nombre formateado del usuario actual (nunca null)
  /// @debug Incluye logs detallados del proceso de detecciÃ³n
  static Future<String> getCurrentUserName() async {
    // PERF: print('ðŸŽ¯ DEBUG getName: Iniciando getCurrentUserName()');
    
    // 1. Obtener email primero
    final email = await getCurrentUserEmail();
    // PERF: print('ðŸŽ¯ DEBUG getName: Email obtenido: "$email"');
    
    // 2. Si hay usuario configurado manualmente, usarlo
    if (_currentUserName != null && _currentUserName!.isNotEmpty) {
      // PERF: print('âœ… Nombre desde configuraciÃ³n manual: $_currentUserName');
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
          // PERF: print('âœ… Nombre obtenido de URL: $decodedName');
          return decodedName;
        }
      } catch (e) {
        // PERF: print('âš ï¸ Error leyendo nombre de URL: $e');
      }
    }

    // 4. ðŸ”¥ NUEVO: Consultar Firestore por email
    if (email != null && email.isNotEmpty && email != 'unknown') {
      final displayName = await getDisplayNameFromFirestore(email);
      if (displayName != 'USUARIO NO ENCONTRADO' && displayName != 'ERROR DE CONEXIÃ“N') {
        _currentUserName = displayName;
        // PERF: print('ðŸ”¥ Nombre obtenido de Firestore: $displayName');
        return displayName;
      }
    }

    // 5. Fallback para mÃ³vil
    if (!kIsWeb) {
      const fallbackName = 'USUARIO ANDROID';
      return fallbackName;
    }

    // 6. Fallback final
    const fallbackName = 'USUARIO DESCONOCIDO';
    // PERF: print('âš ï¸ Usando fallback: $fallbackName');
    return fallbackName;
  }

  /// Verifica si un usuario existe en la base de datos de Firebase
  /// 
  /// MÃ©todo auxiliar para validaciones que requieren confirmar la existencia
  /// de un usuario antes de realizar operaciones (ej: agregar a reservas).
  /// 
  /// PROCESO:
  /// 1. Query a colecciÃ³n 'users' con filtro where por email
  /// 2. Limita resultado a 1 documento para eficiencia
  /// 3. Verifica si el QuerySnapshot contiene documentos
  /// 4. Retorna boolean indicando existencia
  /// 
  /// CASOS DE USO:
  /// - ValidaciÃ³n antes de agregar usuarios a reservas
  /// - VerificaciÃ³n de emails en formularios
  /// - LÃ³gica de autorizaciÃ³n y permisos
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
      // PERF: print('âŒ Error verificando si usuario existe: $e');
      return false;
    }
  }

  /// Obtiene datos completos de un usuario desde Firebase
  /// 
  /// MÃ©todo auxiliar que retorna todos los campos disponibles de un usuario
  /// especÃ­fico. Ãštil para operaciones que requieren informaciÃ³n detallada
  /// mÃ¡s allÃ¡ del nombre y email bÃ¡sicos.
  /// 
  /// DATOS RETORNADOS:
  /// - Todos los campos disponibles en el documento Firebase
  /// - Estructura completa incluyendo metadatos de sincronizaciÃ³n
  /// - InformaciÃ³n de contacto (telÃ©fonos, direcciones)
  /// - Datos demogrÃ¡ficos y de membresÃ­a del club
  /// - Timestamps de Ãºltima actualizaciÃ³n
  /// 
  /// CASOS DE USO:
  /// - Mapeo de telÃ©fonos para sistema de emails
  /// - ValidaciÃ³n de roles y permisos
  /// - InformaciÃ³n para reportes y analytics
  /// - Debugging de problemas de datos especÃ­ficos
  /// - AuditorÃ­a de informaciÃ³n de usuarios
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
      // PERF: print('âŒ Error obteniendo datos del usuario: $e');
      return null;
    }
  }
}

/// NOTAS TÃ‰CNICAS PARA MANTENIMIENTO FUTURO:
/// 
/// 1. **TransiciÃ³n Post-GAS**: Cuando se elimine el sistema GAS, reemplazar
///    la lÃ³gica de URL parameters con Firebase Auth completo. Mantener la
///    estructura de fallbacks para compatibilidad durante transiciÃ³n.
/// 
/// 2. **CachÃ© Local**: Considerar implementar cachÃ© persistente local para
///    datos de usuario frecuentemente accedidos, especialmente en mÃ³vil.
/// 
/// 3. **ValidaciÃ³n de Datos**: Los mÃ©todos actuales asumen que los datos
///    en Firebase son vÃ¡lidos. Considerar agregar validaciones adicionales
///    segÃºn evolucionen los requisitos de calidad de datos.
/// 
/// 4. **Error Handling**: Los mÃ©todos nunca propagan excepciones hacia arriba,
///    siempre usan fallbacks. Evaluar si esto es apropiado para todos los casos
///    de uso futuros del sistema.
/// 
/// 5. **Performance**: Las consultas a Firestore son sÃ­ncronas y pueden ser
///    lentas en conexiones pobres. Considerar implementar timeouts y cachÃ©
///    para mejor UX en mÃ³vil.
/// 
/// 6. **Logging**: Los logs detallados son Ãºtiles para debugging pero pueden
///    afectar performance en producciÃ³n. Considerar sistema de logging
///    configurable por environment.
/// 
/// 7. **Seguridad**: Los URL parameters pueden ser manipulados por usuarios.
///    Cuando se migre a sistema completo Flutter, implementar validaciÃ³n
///    y sanitizaciÃ³n apropiada de todos los inputs.
/// 
/// 8. **Testing**: Los fallbacks facilitan testing pero pueden enmascarar
///    problemas reales. Implementar testing especÃ­fico para cada fuente
///    de datos y sus casos edge.
/// 
/// 9. **Multi-Deporte**: Al extender a Golf/Tenis, considerar si se necesitan
///    parÃ¡metros adicionales en URL (sport, courtType) y cÃ³mo afectarÃ¡n
///    la lÃ³gica de detecciÃ³n de usuario actual.

