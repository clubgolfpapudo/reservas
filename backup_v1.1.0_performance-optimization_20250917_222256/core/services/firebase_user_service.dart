/// lib/core/services/firebase_user_service.dart
/// 
/// PROPÃ“SITO:
/// Servicio especializado para gestiÃ³n de usuarios desde Firebase Firestore con enfoque especÃ­fico
/// en la estructura de datos del Club de Golf Papudo. Maneja la complejidad de:
/// - SincronizaciÃ³n automÃ¡tica con Google Sheets (497+ usuarios)
/// - Estructura hÃ­brida de campos en espaÃ±ol/inglÃ©s debido a migraciÃ³n gradual
/// - ExtracciÃ³n inteligente de nombres desde mÃºltiples formatos de datos
/// - Mapeo completo de campos de usuarios incluyendo telÃ©fonos, roles, y metadatos
/// - Sistema robusto de fallback para desarrollo y casos de error
/// 
/// ESTRUCTURA DE DATOS FIREBASE MANEJADA:
/// - Campo 'name': Formato final correcto desde sincronizaciÃ³n reciente
/// - Campo 'displayName': Formato legacy con posibles inconsistencias
/// - Campos separados: nombres, apellidoPaterno, apellidoMaterno (estructura espaÃ±ola)
/// - Campos mapeados: phone vs celular, firstName vs nombres (migraciÃ³n inglÃ©s)
/// - Metadatos: lastSyncFromSheets, source, isActive, relacion
/// 
/// CASOS DE USO PRINCIPALES:
/// 1. Auto-completado de organizador en formularios de reserva
/// 2. BÃºsqueda de usuarios para agregar a reservas (hasta 4 jugadores)
/// 3. Mapeo de telÃ©fonos para sistema de emails automÃ¡ticos
/// 4. ValidaciÃ³n de usuarios activos vs inactivos
/// 5. IntegraciÃ³n con sistema de roles del club (SOCIO TITULAR, HIJO, etc.)
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio especializado para gestiÃ³n de usuarios desde Firebase Firestore
/// 
/// Maneja la complejidad especÃ­fica de la estructura de usuarios del Club de Golf Papudo,
/// incluyendo la migraciÃ³n gradual de nomenclatura espaÃ±olâ†’inglÃ©s y la sincronizaciÃ³n
/// automÃ¡tica con Google Sheets que contiene 497+ usuarios.
/// 
/// CARACTERÃSTICAS PRINCIPALES:
/// - ExtracciÃ³n inteligente de nombres desde mÃºltiples formatos
/// - Mapeo completo de campos hÃ­bridos (espaÃ±ol/inglÃ©s)
/// - Sistema robusto de fallback para desarrollo
/// - Performance optimizada para carga de 497+ usuarios
/// - Compatibilidad con estructura legacy durante migraciÃ³n
class FirebaseUserService {
  /// Constructor con logging para debugging
  /// 
  /// Indica que el servicio estÃ¡ en modo debug activo para facilitar
  /// identificaciÃ³n de problemas durante desarrollo.
  FirebaseUserService() {
    print('ðŸ”¥ FirebaseUserService INITIALIZED - DEBUG MODE ACTIVE');
  }
  
  /// Email por defecto para desarrollo y testing
  /// Corresponde a usuario real validado en auditorÃ­a Firebase
  static const String _defaultEmail = 'felipe@garciab.cl';
  /// Nombre por defecto correspondiente al email de desarrollo
  /// Formato correcto segÃºn estructura actual de Firebase
  static const String _defaultName = 'FELIPE GARCIA B';

  /// Obtiene el email del usuario actual
  /// 
  /// En la implementaciÃ³n actual retorna un email fijo para desarrollo.
  /// En el sistema final multi-deporte, esto se integrarÃ¡ con autenticaciÃ³n
  /// real de Flutter eliminando la dependencia del sistema GAS.
  /// 
  /// @return Email del usuario actual para auto-completado
  /// @todo Integrar con Firebase Auth cuando se elimine dependencia GAS
  static Future<String> getCurrentUserEmail() async {
    return _defaultEmail;
  }

  /// Obtiene el nombre del usuario actual
  /// 
  /// Retorna nombre formateado correspondiente al email actual.
  /// Usado para auto-completado del organizador en formularios de reserva.
  /// 
  /// @return Nombre formateado del usuario actual
  /// @todo Integrar con datos reales de Firebase Auth
  static Future<String> getCurrentUserName() async {
    return _defaultName;
  }

  /// **MÃ‰TODO PRINCIPAL** - Carga todos los usuarios desde Firebase con campos completos
  /// 
  /// Realiza carga optimizada de la colecciÃ³n 'users' con procesamiento inteligente
  /// de la estructura de datos hÃ­brida. Incluye todos los campos necesarios para:
  /// - BÃºsquedas de usuarios en formularios de reserva
  /// - Mapeo de telÃ©fonos para sistema de emails automÃ¡ticos
  /// - ValidaciÃ³n de usuarios activos vs inactivos
  /// - InformaciÃ³n de contacto completa
  /// 
  /// PROCESO DE CARGA:
  /// 1. Query a colecciÃ³n 'users' de Firebase (497+ documentos)
  /// 2. ValidaciÃ³n de email vÃ¡lido por documento
  /// 3. ExtracciÃ³n inteligente de nombres con 4 niveles de fallback
  /// 4. Mapeo completo de campos hÃ­bridos espaÃ±ol/inglÃ©s
  /// 5. Filtrado de usuarios invÃ¡lidos
  /// 6. Ordenamiento alfabÃ©tico para UI
  /// 7. Fallback a usuarios de desarrollo si Firebase falla
  /// 
  /// CAMPOS RETORNADOS (13 campos por usuario):
  /// - name: Nombre formateado para mostrar en UI
  /// - email: Email Ãºnico (clave primaria)
  /// - phone: TelÃ©fono para emails (puede ser null)
  /// - displayName: Nombre completo legacy
  /// - firstName/lastName/middleName: Campos separados
  /// - isActive: Estado del usuario
  /// - celular: Campo espaÃ±ol (compatibilidad)
  /// - rutPasaporte: IdentificaciÃ³n Ãºnica
  /// - relacion: Tipo de membresÃ­a (SOCIO TITULAR, HIJO, etc.)
  /// - fechaNacimiento: InformaciÃ³n demogrÃ¡fica
  /// - lastSyncFromSheets: Timestamp Ãºltima sincronizaciÃ³n
  /// - source: Origen de datos (google_sheets_auto)
  /// 
  /// @return Lista de Maps con todos los usuarios y sus campos completos
  /// @throws No propaga excepciones, usa fallback en caso de error
  /// @debug Incluye logs detallados para debugging de cada usuario procesado
  // ========================================================================
  // CACHE SINGLETON - NUEVA IMPLEMENTACIÃ“N OPTIMIZADA
  // ========================================================================

  /// Cache estÃ¡tico de usuarios en memoria (sobrevive toda la sesiÃ³n)
  static List<Map<String, dynamic>>? _cachedUsers;

  /// Flag para indicar si los usuarios ya fueron cargados al menos una vez
  static bool _isLoaded = false;

  /// Timestamp de Ãºltima carga para determinar si el cache debe refrescarse
  static DateTime? _lastLoaded;

  /// Tiempo de vida del cache en minutos (30 minutos por defecto)
  static const int _cacheLifetimeMinutes = 30;

  /// Flag para debugging del cache
  static bool _cacheDebugEnabled = true;

  /// **MÃ‰TODO PRINCIPAL OPTIMIZADO** - Carga usuarios con cache singleton
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // âœ… VERIFICAR CACHE VÃLIDO PRIMERO
      if (_isCacheValid()) {
        if (_cacheDebugEnabled) {
          print('âš¡ CACHE HIT: Retornando ${_cachedUsers!.length} usuarios desde memoria (${_getTimeSinceLoad()}min ago)');
        }
        return _cachedUsers!;
      }

      // âŒ CACHE EXPIRADO O NO EXISTE - CARGAR DESDE FIREBASE
      if (_cacheDebugEnabled) {
        print('ðŸ”„ CACHE MISS: Cargando usuarios desde Firebase...');
      }
      final startTime = DateTime.now();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Validar que tenga email vÃ¡lido
          if (data.containsKey('email') &&
              data['email'] != null &&
              data['email'].toString().trim().isNotEmpty) {

            String email = data['email'].toString().trim().toLowerCase();
            String name = _extractNameFromRealStructure(data);

            if (name.isNotEmpty) {
              // Incluir todos los campos necesarios de Firebase
              users.add({
                'name': name,
                'email': email,
                'phone': data['phone'],
                'displayName': data['displayName'],
                'firstName': data['givenNames'] ?? data['nombres'],
                'lastName': data['lastName'] ?? data['apellidoPaterno'],
                'middleName': data['secondLastName'] ?? data['apellidoMaterno'],
                'isActive': data['isActive'],
                'celular': data['celular'],
                'rutPasaporte': data['rutPasaporte'],
                'relacion': data['relacion'],
                'fechaNacimiento': data['fechaNacimiento'],
                'lastSyncFromSheets': data['lastSyncFromSheets'],
                'source': data['source'],
              });
            }
          }
        } catch (e) {
          // Continuar procesando otros usuarios si uno falla
          continue;
        }
      }

      // Ordenar alfabÃ©ticamente por nombre
      users.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      final finalUsers = users.isNotEmpty ? users : _getFallbackUsers();

      // âœ… GUARDAR EN CACHE PARA FUTURAS LLAMADAS
      _updateCache(finalUsers);

      if (_cacheDebugEnabled) {
        final loadTime = DateTime.now().difference(startTime).inMilliseconds;
        print('âœ… CACHE UPDATED: ${finalUsers.length} usuarios cargados y cacheados en ${loadTime}ms');
      }

      return finalUsers;

    } catch (e) {
      print('âŒ Error cargando usuarios: $e');
      
      // Si hay cache (aunque estÃ© expirado), usarlo como fallback
      if (_cachedUsers != null && _cachedUsers!.isNotEmpty) {
        if (_cacheDebugEnabled) {
          print('âš ï¸ CACHE FALLBACK: Usando cache expirado debido a error');
        }
        return _cachedUsers!;
      }

      // Ãšltimo recurso: fallback estÃ¡tico
      return _getFallbackUsers();
    }
  }

  // ========================================================================
  // MÃ‰TODOS DE GESTIÃ“N DE CACHE
  // ========================================================================

  /// Verifica si el cache actual es vÃ¡lido
  static bool _isCacheValid() {
    if (!_isLoaded || _cachedUsers == null || _cachedUsers!.isEmpty) {
      return false;
    }

    if (_lastLoaded == null) {
      return false;
    }

    final minutesSinceLoad = DateTime.now().difference(_lastLoaded!).inMinutes;
    return minutesSinceLoad < _cacheLifetimeMinutes;
  }

  /// Actualiza el cache con nuevos datos
  static void _updateCache(List<Map<String, dynamic>> users) {
    _cachedUsers = users;
    _isLoaded = true;
    _lastLoaded = DateTime.now();
  }

  /// Obtiene tiempo transcurrido desde Ãºltima carga (para debugging)
  static int _getTimeSinceLoad() {
    if (_lastLoaded == null) return 0;
    return DateTime.now().difference(_lastLoaded!).inMinutes;
  }

  /// ExtracciÃ³n inteligente de nombres desde estructura real de Firebase
  /// 
  /// Implementa algoritmo de 4 niveles para extraer nombres desde la estructura
  /// de datos hÃ­brida resultado de la evoluciÃ³n del sistema y sincronizaciÃ³n
  /// con Google Sheets.
  /// 
  /// ALGORITMO DE EXTRACCIÃ“N (orden de prioridad):
  /// 1. **Campo 'name'**: Formato final correcto desde sincronizaciÃ³n reciente
  /// 2. **Campo 'displayName'**: Formato legacy, requiere limpieza de puntos
  /// 3. **Campos separados**: ConstrucciÃ³n desde nombres + apellidos separados
  /// 4. **Email fallback**: GeneraciÃ³n desde username de email como Ãºltimo recurso
  /// 
  /// PROCESAMIENTO DE CAMPOS SEPARADOS:
  /// - nombres: "FELIPE GARCIA" â†’ "FELIPE G" (primer nombre + inicial segundo)
  /// - apellidoPaterno: "BENITEZ" â†’ "BENITEZ" (completo)
  /// - apellidoMaterno: "RODRIGUEZ" â†’ "R" (solo inicial, SIN PUNTO)
  /// - Resultado: "FELIPE G BENITEZ R"
  /// 
  /// LIMPIEZA APLICADA:
  /// - EliminaciÃ³n de puntos al final (.$ regexp)
  /// - ConversiÃ³n a mayÃºsculas para consistencia
  /// - Trim de espacios en blanco
  /// - Manejo de casos null/undefined
  /// 
  /// @param data Map con datos completos del usuario desde Firebase
  /// @return String con nombre formateado o vacÃ­o si no se puede extraer
  /// @debug Incluye logs detallados de cada paso del algoritmo
  static String _extractNameFromRealStructure(Map<String, dynamic> data) {
    try {
      // DEBUG: Imprimir todos los campos disponibles
      // PERF-CRITICAL: print('ðŸ” DEBUG - Campos disponibles en data:');
    // PERF-CRITICAL: Logging masivo comentado
    // data.forEach((key, value) {
        // PERF-CRITICAL: print('  $key: $value');
    // });
      
      // PRIORIDAD 1: Usar campo 'name' (formato correcto desde Firebase)
      if (data.containsKey('name') && 
          data['name'] != null && 
          data['name'].toString().trim().isNotEmpty) {
        
        String nameFromFirebase = data['name'].toString().trim().toUpperCase();
        // PERF-CRITICAL: print('âœ… USANDO CAMPO NAME: $nameFromFirebase');
        return nameFromFirebase;
      } else {
        // PERF-CRITICAL: print('âŒ Campo name no disponible, usando fallback');
      }
      
      // PRIORIDAD 2: Usar displayName si existe y no estÃ¡ vacÃ­o
      if (data.containsKey('displayName') &&
          data['displayName'] != null &&
          data['displayName'].toString().trim().isNotEmpty) {

        String displayNameFromFirebase = data['displayName'].toString().trim().toUpperCase();
        // ðŸ”¥ NUEVO: Quitar puntos al final del displayName
        displayNameFromFirebase = displayNameFromFirebase.replaceAll(RegExp(r'\.$'), '');
        print('âœ… USANDO DISPLAYNAME (sin puntos): $displayNameFromFirebase');
        return displayNameFromFirebase;
      } else {
        print('âŒ Campo displayName no disponible');
      }
      
      // PRIORIDAD 3: Construir desde campos separados (FALLBACK)
      print('âš ï¸ USANDO FALLBACK - construyendo desde campos separados');
      List<String> nameParts = [];
      
      // Procesar nombres: primer nombre + inicial segundo nombre (sin punto)
      if (data.containsKey('nombres') && data['nombres'] != null) {
        String nombres = data['nombres'].toString().trim();
        List<String> nombresList = nombres.split(' ');
        
        if (nombresList.isNotEmpty) {
          nameParts.add(nombresList[0]);
          print('  Primer nombre: ${nombresList[0]}');
        }
        
        if (nombresList.length > 1 && nombresList[1].isNotEmpty) {
          nameParts.add(nombresList[1][0]); // Sin punto
          print('  Inicial segundo nombre: ${nombresList[1][0]} (sin punto)');
        }
      }
      
      if (data.containsKey('apellidoPaterno') && data['apellidoPaterno'] != null) {
        String apellidoPaterno = data['apellidoPaterno'].toString().trim();
        nameParts.add(apellidoPaterno);
        print('  Apellido paterno: $apellidoPaterno');
      }
      
      if (data.containsKey('apellidoMaterno') && data['apellidoMaterno'] != null) {
        String apellidoMaterno = data['apellidoMaterno'].toString().trim();
        if (apellidoMaterno.isNotEmpty) {
          nameParts.add(apellidoMaterno[0]); // Sin punto - CRÃTICO: AQUÃ NO DEBE HABER PUNTO
          print('  Inicial apellido materno: ${apellidoMaterno[0]} (sin punto)');
        }
      }
      
      if (nameParts.isNotEmpty) {
        String resultado = nameParts.join(' ').toUpperCase();
        print('ðŸ”§ RESULTADO FALLBACK: $resultado');
        return resultado;
      }
      
      // PRIORIDAD 4: Fallback desde email
      if (data.containsKey('email')) {
        String emailFallback = _generateNameFromEmail(data['email'].toString());
        print('ðŸ“§ USANDO EMAIL FALLBACK: $emailFallback');
        return emailFallback;
      }
      
      print('âŒ NO SE PUDO GENERAR NOMBRE');
      return '';
      
    } catch (e) {
      print('âŒ Error extrayendo nombre: $e');
      return '';
    }
  }

  /// Genera nombre desde email como fallback de Ãºltimo recurso
  /// 
  /// Utilizado cuando ningÃºn campo de nombre estÃ¡ disponible o es vÃ¡lido.
  /// Extrae el username del email y lo convierte en un nombre legible.
  /// 
  /// PROCESO:
  /// 1. Extraer username antes del @
  /// 2. Remover caracteres especiales (nÃºmeros, sÃ­mbolos)
  /// 3. Dividir por espacios/separadores
  /// 4. Capitalizar cada palabra
  /// 5. Unir con espacios
  /// 
  /// EJEMPLOS:
  /// - "felipe.garcia@club.cl" â†’ "FELIPE GARCIA"
  /// - "user123@example.com" â†’ "USER"
  /// - "invalid@email" â†’ "USUARIO CLUB"
  /// 
  /// @param email Email del usuario para extraer nombre
  /// @return Nombre generado o "USUARIO CLUB" por defecto
  static String _generateNameFromEmail(String email) {
    try {
      String username = email.split('@')[0];
      username = username.replaceAll(RegExp(r'[^a-zA-Z]'), ' ');
      
      List<String> words = username.split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word.toUpperCase())
          .toList();
      
      if (words.isEmpty) {
        return 'USUARIO CLUB';
      }
      
      return words.join(' ');
      
    } catch (e) {
      return 'USUARIO CLUB';
    }
  }

  /// Sistema de fallback robusto para desarrollo y casos de error
  /// 
  /// Proporciona conjunto de usuarios de prueba cuando Firebase no estÃ¡
  /// disponible o hay errores de conectividad. Incluye:
  /// - Usuarios reales del club para testing
  /// - Variedad de nombres para testing de UI
  /// - Emails vÃ¡lidos para testing de funcionalidad
  /// - Suficientes usuarios para testing de bÃºsqueda/filtrado
  /// 
  /// USUARIOS INCLUIDOS:
  /// - 4 usuarios reales del club (testing principal)
  /// - 11 usuarios ficticios (testing de volumen)
  /// - Formatos de nombre variados (testing de edge cases)
  /// 
  /// CASOS DE USO:
  /// - Desarrollo offline sin acceso a Firebase
  /// - Testing automatizado sin dependencias externas
  /// - DemostraciÃ³n del sistema sin datos reales
  /// - Debugging de problemas de UI con datos controlados
  /// 
  /// @return Lista de 15 usuarios de fallback con estructura consistente
  static List<Map<String, dynamic>> _getFallbackUsers() {
    print('ðŸ”„ Usando usuarios de fallback (Firebase no disponible)...');
    
    return [
      {'name': 'ANA M BELMAR P', 'email': 'ana@buzeta.cl'},
      {'name': 'CLARA PARDO B', 'email': 'clara@garciab.cl'},
      {'name': 'JUAN F GONZALEZ P', 'email': 'fgarcia88@hotmail.com'},
      {'name': 'FELIPE GARCIA B', 'email': 'felipe@garciab.cl'},
      {'name': 'PEDRO MARTINEZ L', 'email': 'pedro.martinez@example.com'},
      {'name': 'MARIA GONZALEZ R', 'email': 'maria.gonzalez@example.com'},
      {'name': 'CARLOS RODRIGUEZ M', 'email': 'carlos.rodriguez@example.com'},
      {'name': 'LUIS FERNANDEZ B', 'email': 'luis.fernandez@example.com'},
      {'name': 'SOFIA MARTINEZ T', 'email': 'sofia.martinez@example.com'},
      {'name': 'DIEGO SANCHEZ L', 'email': 'diego.sanchez@example.com'},
      {'name': 'CAMILA TORRES V', 'email': 'camila.torres@example.com'},
      {'name': 'ALEJANDRO RUIZ P', 'email': 'alejandro.ruiz@example.com'},
      {'name': 'VALENTINA MORALES G', 'email': 'valentina.morales@example.com'},
      {'name': 'SEBASTIAN CASTRO H', 'email': 'sebastian.castro@example.com'},
      {'name': 'ISIDORA SILVA M', 'email': 'isidora.silva@example.com'},
    ];
  }
}

/// NOTAS TÃ‰CNICAS PARA MANTENIMIENTO FUTURO:
/// 
/// 1. **MigraciÃ³n Nomenclatura**: El sistema actual maneja estructura hÃ­brida
///    espaÃ±ol/inglÃ©s. Cuando se complete migraciÃ³n a inglÃ©s, simplificar
///    _extractNameFromRealStructure() para usar solo campos ingleses.
/// 
/// 2. **Performance**: Con 497+ usuarios, la carga es eficiente pero considerar
///    implementar cachÃ© local si se requieren mÃºltiples llamadas frecuentes.
/// 
/// 3. **AutenticaciÃ³n Real**: getCurrentUserEmail/Name estÃ¡n hardcodeados para
///    desarrollo. Integrar con Firebase Auth cuando se elimine dependencia GAS.
/// 
/// 4. **Validaciones**: Considerar agregar validaciones adicionales de formato
///    de email y estructura de nombres segÃºn crezca la base de usuarios.
/// 
/// 5. **Logging**: Los logs detallados son Ãºtiles para debugging pero pueden
///    removerse en producciÃ³n final para mejor performance.
/// 
/// 6. **Error Handling**: El sistema nunca propaga errores hacia arriba,
///    siempre usa fallbacks. Evaluar si esto es apropiado para todos los casos.
/// 
/// 7. **Campos Futuros**: La estructura retorna 13 campos por usuario. Al
///    agregar nuevos campos a Firebase, actualizar el mapeo en getAllUsers().
/// 
/// 8. **Testing**: Los usuarios de fallback deben mantenerse actualizados
///    con la estructura real de Firebase para testing efectivo.
