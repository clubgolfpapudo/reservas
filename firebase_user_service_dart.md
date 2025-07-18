/// lib/core/services/firebase_user_service.dart
/// 
/// PROPÓSITO:
/// Servicio especializado para gestión de usuarios desde Firebase Firestore con enfoque específico
/// en la estructura de datos del Club de Golf Papudo. Maneja la complejidad de:
/// - Sincronización automática con Google Sheets (497+ usuarios)
/// - Estructura híbrida de campos en español/inglés debido a migración gradual
/// - Extracción inteligente de nombres desde múltiples formatos de datos
/// - Mapeo completo de campos de usuarios incluyendo teléfonos, roles, y metadatos
/// - Sistema robusto de fallback para desarrollo y casos de error
/// 
/// MOTIVO DE EXISTENCIA:
/// Firebase contiene usuarios sincronizados automáticamente desde Google Sheets del club,
/// pero la estructura de datos ha evolucionado creando inconsistencias de nomenclatura.
/// Este servicio abstrae esa complejidad y proporciona:
/// - API limpia y consistente para obtener usuarios
/// - Manejo de casos edge (usuarios sin nombre completo, emails duplicados)
/// - Optimización de queries para 497+ usuarios sin impacto en performance
/// - Compatibilidad con sistema legacy durante transición
/// - Logging detallado para debugging de problemas de sincronización
/// 
/// ESTRUCTURA DE DATOS FIREBASE MANEJADA:
/// - Campo 'name': Formato final correcto desde sincronización reciente
/// - Campo 'displayName': Formato legacy con posibles inconsistencias
/// - Campos separados: nombres, apellidoPaterno, apellidoMaterno (estructura española)
/// - Campos mapeados: phone vs celular, firstName vs nombres (migración inglés)
/// - Metadatos: lastSyncFromSheets, source, isActive, relacion
/// 
/// CASOS DE USO PRINCIPALES:
/// 1. Auto-completado de organizador en formularios de reserva
/// 2. Búsqueda de usuarios para agregar a reservas (hasta 4 jugadores)
/// 3. Mapeo de teléfonos para sistema de emails automáticos
/// 4. Validación de usuarios activos vs inactivos
/// 5. Integración con sistema de roles del club (SOCIO TITULAR, HIJO, etc.)
/// 
/// OPTIMIZACIONES IMPLEMENTADAS:
/// - Extracción inteligente de nombres con 4 niveles de fallback
/// - Ordenamiento alfabético automático para UI
/// - Filtrado de usuarios inválidos durante carga
/// - Sistema de fallback robusto para desarrollo offline
/// - Logging detallado para debugging sin afectar performance

import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio especializado para gestión de usuarios desde Firebase Firestore
/// 
/// Maneja la complejidad específica de la estructura de usuarios del Club de Golf Papudo,
/// incluyendo la migración gradual de nomenclatura español→inglés y la sincronización
/// automática con Google Sheets que contiene 497+ usuarios.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// - Extracción inteligente de nombres desde múltiples formatos
/// - Mapeo completo de campos híbridos (español/inglés)
/// - Sistema robusto de fallback para desarrollo
/// - Performance optimizada para carga de 497+ usuarios
/// - Compatibilidad con estructura legacy durante migración
class FirebaseUserService {
  /// Email por defecto para desarrollo y testing
  /// Corresponde a usuario real validado en auditoría Firebase
  static const String _defaultEmail = 'felipe@garciab.cl';
  
  /// Nombre por defecto correspondiente al email de desarrollo
  /// Formato correcto según estructura actual de Firebase
  static const String _defaultName = 'FELIPE GARCIA B';

  /// Constructor con logging para debugging
  /// 
  /// Indica que el servicio está en modo debug activo para facilitar
  /// identificación de problemas durante desarrollo.
  FirebaseUserService() {
    print('🔥 FirebaseUserService INITIALIZED - DEBUG MODE ACTIVE');
  }

  /// Obtiene el email del usuario actual
  /// 
  /// En la implementación actual retorna un email fijo para desarrollo.
  /// En el sistema final multi-deporte, esto se integrará con autenticación
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

  /// **MÉTODO PRINCIPAL** - Carga todos los usuarios desde Firebase con campos completos
  /// 
  /// Realiza carga optimizada de la colección 'users' con procesamiento inteligente
  /// de la estructura de datos híbrida. Incluye todos los campos necesarios para:
  /// - Búsquedas de usuarios en formularios de reserva
  /// - Mapeo de teléfonos para sistema de emails automáticos
  /// - Validación de usuarios activos vs inactivos
  /// - Información de contacto completa
  /// 
  /// PROCESO DE CARGA:
  /// 1. Query a colección 'users' de Firebase (497+ documentos)
  /// 2. Validación de email válido por documento
  /// 3. Extracción inteligente de nombres con 4 niveles de fallback
  /// 4. Mapeo completo de campos híbridos español/inglés
  /// 5. Filtrado de usuarios inválidos
  /// 6. Ordenamiento alfabético para UI
  /// 7. Fallback a usuarios de desarrollo si Firebase falla
  /// 
  /// CAMPOS RETORNADOS (13 campos por usuario):
  /// - name: Nombre formateado para mostrar en UI
  /// - email: Email único (clave primaria)
  /// - phone: Teléfono para emails (puede ser null)
  /// - displayName: Nombre completo legacy
  /// - firstName/lastName/middleName: Campos separados
  /// - isActive: Estado del usuario
  /// - celular: Campo español (compatibilidad)
  /// - rutPasaporte: Identificación única
  /// - relacion: Tipo de membresía (SOCIO TITULAR, HIJO, etc.)
  /// - fechaNacimiento: Información demográfica
  /// - lastSyncFromSheets: Timestamp última sincronización
  /// - source: Origen de datos (google_sheets_auto)
  /// 
  /// @return Lista de Maps con todos los usuarios y sus campos completos
  /// @throws No propaga excepciones, usa fallback en caso de error
  /// @debug Incluye logs detallados para debugging de cada usuario procesado
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      // Query principal a colección de usuarios en Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final List<Map<String, dynamic>> users = [];
      
      // Procesar cada documento de usuario
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Validación estricta de email válido
          if (data.containsKey('email') && 
              data['email'] != null && 
              data['email'].toString().trim().isNotEmpty) {
            
            // Normalizar email (lowercase, sin espacios)
            String email = data['email'].toString().trim().toLowerCase();
            
            // Extracción inteligente de nombre con múltiples fallbacks
            String name = _extractNameFromRealStructure(data);
            
            // Solo agregar usuarios con nombre válido extraído
            if (name.isNotEmpty) {
              // Mapeo completo de todos los campos disponibles en Firebase
              users.add({
                'name': name,                               // Nombre formateado para UI
                'email': email,                             // Email normalizado
                'phone': data['phone'],                     // Teléfono para emails (campo inglés)
                'displayName': data['displayName'],         // Nombre completo legacy
                'firstName': data['firstName'] ?? data['nombres'],           // Mapeo híbrido
                'lastName': data['lastName'] ?? data['apellidoPaterno'],     // Mapeo híbrido
                'middleName': data['middleName'] ?? data['apellidoMaterno'], // Mapeo híbrido
                'isActive': data['isActive'],               // Estado del usuario
                'celular': data['celular'],                 // Teléfono español (compatibilidad)
                'rutPasaporte': data['rutPasaporte'],       // Identificación única
                'relacion': data['relacion'],               // Tipo membresía del club
                'fechaNacimiento': data['fechaNacimiento'], // Información demográfica
                'lastSyncFromSheets': data['lastSyncFromSheets'], // Timestamp sincronización
                'source': data['source'],                   // Origen: google_sheets_auto
              });
            }
          }
        } catch (e) {
          // Continuar procesando otros usuarios si uno individual falla
          // Esto evita que un usuario corrupto rompa toda la carga
          continue;
        }
      }

      // Ordenamiento alfabético por nombre para UI consistente
      users.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
      
      // Retornar usuarios cargados o fallback si lista está vacía
      return users.isNotEmpty ? users : _getFallbackUsers();
      
    } catch (e) {
      // En caso de error de conectividad o Firebase, usar sistema fallback
      print('❌ Error cargando usuarios desde Firebase: $e');
      return _getFallbackUsers();
    }
  }

  /// Extracción inteligente de nombres desde estructura real de Firebase
  /// 
  /// Implementa algoritmo de 4 niveles para extraer nombres desde la estructura
  /// de datos híbrida resultado de la evolución del sistema y sincronización
  /// con Google Sheets.
  /// 
  /// ALGORITMO DE EXTRACCIÓN (orden de prioridad):
  /// 1. **Campo 'name'**: Formato final correcto desde sincronización reciente
  /// 2. **Campo 'displayName'**: Formato legacy, requiere limpieza de puntos
  /// 3. **Campos separados**: Construcción desde nombres + apellidos separados
  /// 4. **Email fallback**: Generación desde username de email como último recurso
  /// 
  /// PROCESAMIENTO DE CAMPOS SEPARADOS:
  /// - nombres: "FELIPE GARCIA" → "FELIPE G" (primer nombre + inicial segundo)
  /// - apellidoPaterno: "BENITEZ" → "BENITEZ" (completo)
  /// - apellidoMaterno: "RODRIGUEZ" → "R" (solo inicial, SIN PUNTO)
  /// - Resultado: "FELIPE G BENITEZ R"
  /// 
  /// LIMPIEZA APLICADA:
  /// - Eliminación de puntos al final (.$ regexp)
  /// - Conversión a mayúsculas para consistencia
  /// - Trim de espacios en blanco
  /// - Manejo de casos null/undefined
  /// 
  /// @param data Map con datos completos del usuario desde Firebase
  /// @return String con nombre formateado o vacío si no se puede extraer
  /// @debug Incluye logs detallados de cada paso del algoritmo
  static String _extractNameFromRealStructure(Map<String, dynamic> data) {
    try {
      // Debug: Mostrar todos los campos disponibles para análisis
      print('🔍 DEBUG - Campos disponibles en data:');
      data.forEach((key, value) {
        print('  $key: $value');
      });
      
      // PRIORIDAD 1: Campo 'name' (formato correcto desde Firebase)
      if (data.containsKey('name') && 
          data['name'] != null && 
          data['name'].toString().trim().isNotEmpty) {
        
        String nameFromFirebase = data['name'].toString().trim().toUpperCase();
        print('✅ USANDO CAMPO NAME: $nameFromFirebase');
        return nameFromFirebase;
      } else {
        print('❌ Campo name no disponible, usando fallback');
      }
      
      // PRIORIDAD 2: Campo 'displayName' con limpieza de puntos
      if (data.containsKey('displayName') &&
          data['displayName'] != null &&
          data['displayName'].toString().trim().isNotEmpty) {

        String displayNameFromFirebase = data['displayName'].toString().trim().toUpperCase();
        // Limpieza crítica: eliminar puntos al final heredados del sistema legacy
        displayNameFromFirebase = displayNameFromFirebase.replaceAll(RegExp(r'\.$'), '');
        print('✅ USANDO DISPLAYNAME (sin puntos): $displayNameFromFirebase');
        return displayNameFromFirebase;
      } else {
        print('❌ Campo displayName no disponible');
      }
      
      // PRIORIDAD 3: Construcción desde campos separados (estructura española)
      print('⚠️ USANDO FALLBACK - construyendo desde campos separados');
      List<String> nameParts = [];
      
      // Procesamiento de nombres: primer nombre + inicial segundo nombre
      if (data.containsKey('nombres') && data['nombres'] != null) {
        String nombres = data['nombres'].toString().trim();
        List<String> nombresList = nombres.split(' ');
        
        // Primer nombre completo
        if (nombresList.isNotEmpty) {
          nameParts.add(nombresList[0]);
          print('  Primer nombre: ${nombresList[0]}');
        }
        
        // Inicial del segundo nombre (sin punto)
        if (nombresList.length > 1 && nombresList[1].isNotEmpty) {
          nameParts.add(nombresList[1][0]); // SIN PUNTO - decisión de diseño
          print('  Inicial segundo nombre: ${nombresList[1][0]} (sin punto)');
        }
      }
      
      // Apellido paterno completo
      if (data.containsKey('apellidoPaterno') && data['apellidoPaterno'] != null) {
        String apellidoPaterno = data['apellidoPaterno'].toString().trim();
        nameParts.add(apellidoPaterno);
        print('  Apellido paterno: $apellidoPaterno');
      }
      
      // Inicial de apellido materno (sin punto)
      if (data.containsKey('apellidoMaterno') && data['apellidoMaterno'] != null) {
        String apellidoMaterno = data['apellidoMaterno'].toString().trim();
        if (apellidoMaterno.isNotEmpty) {
          nameParts.add(apellidoMaterno[0]); // CRÍTICO: SIN PUNTO para consistencia
          print('  Inicial apellido materno: ${apellidoMaterno[0]} (sin punto)');
        }
      }
      
      // Ensamblar resultado final
      if (nameParts.isNotEmpty) {
        String resultado = nameParts.join(' ').toUpperCase();
        print('🔧 RESULTADO FALLBACK: $resultado');
        return resultado;
      }
      
      // PRIORIDAD 4: Fallback desde email como último recurso
      if (data.containsKey('email')) {
        String emailFallback = _generateNameFromEmail(data['email'].toString());
        print('📧 USANDO EMAIL FALLBACK: $emailFallback');
        return emailFallback;
      }
      
      print('❌ NO SE PUDO GENERAR NOMBRE');
      return '';
      
    } catch (e) {
      print('❌ Error extrayendo nombre: $e');
      return '';
    }
  }

  /// Genera nombre desde email como fallback de último recurso
  /// 
  /// Utilizado cuando ningún campo de nombre está disponible o es válido.
  /// Extrae el username del email y lo convierte en un nombre legible.
  /// 
  /// PROCESO:
  /// 1. Extraer username antes del @
  /// 2. Remover caracteres especiales (números, símbolos)
  /// 3. Dividir por espacios/separadores
  /// 4. Capitalizar cada palabra
  /// 5. Unir con espacios
  /// 
  /// EJEMPLOS:
  /// - "felipe.garcia@club.cl" → "FELIPE GARCIA"
  /// - "user123@example.com" → "USER"
  /// - "invalid@email" → "USUARIO CLUB"
  /// 
  /// @param email Email del usuario para extraer nombre
  /// @return Nombre generado o "USUARIO CLUB" por defecto
  static String _generateNameFromEmail(String email) {
    try {
      String username = email.split('@')[0];
      // Remover números y caracteres especiales, convertir a espacios
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
  /// Proporciona conjunto de usuarios de prueba cuando Firebase no está
  /// disponible o hay errores de conectividad. Incluye:
  /// - Usuarios reales del club para testing
  /// - Variedad de nombres para testing de UI
  /// - Emails válidos para testing de funcionalidad
  /// - Suficientes usuarios para testing de búsqueda/filtrado
  /// 
  /// USUARIOS INCLUIDOS:
  /// - 4 usuarios reales del club (testing principal)
  /// - 11 usuarios ficticios (testing de volumen)
  /// - Formatos de nombre variados (testing de edge cases)
  /// 
  /// CASOS DE USO:
  /// - Desarrollo offline sin acceso a Firebase
  /// - Testing automatizado sin dependencias externas
  /// - Demostración del sistema sin datos reales
  /// - Debugging de problemas de UI con datos controlados
  /// 
  /// @return Lista de 15 usuarios de fallback con estructura consistente
  static List<Map<String, dynamic>> _getFallbackUsers() {
    print('🔄 Usando usuarios de fallback (Firebase no disponible)...');
    
    return [
      // Usuarios reales del club para testing principal
      {'name': 'ANA M BELMAR P', 'email': 'ana@buzeta.cl'},
      {'name': 'CLARA PARDO B', 'email': 'clara@garciab.cl'},
      {'name': 'JUAN F GONZALEZ P', 'email': 'fgarcia88@hotmail.com'},
      {'name': 'FELIPE GARCIA B', 'email': 'felipe@garciab.cl'},
      
      // Usuarios ficticios para testing de volumen y variedad
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

/// NOTAS TÉCNICAS PARA MANTENIMIENTO FUTURO:
/// 
/// 1. **Migración Nomenclatura**: El sistema actual maneja estructura híbrida
///    español/inglés. Cuando se complete migración a inglés, simplificar
///    _extractNameFromRealStructure() para usar solo campos ingleses.
/// 
/// 2. **Performance**: Con 497+ usuarios, la carga es eficiente pero considerar
///    implementar caché local si se requieren múltiples llamadas frecuentes.
/// 
/// 3. **Autenticación Real**: getCurrentUserEmail/Name están hardcodeados para
///    desarrollo. Integrar con Firebase Auth cuando se elimine dependencia GAS.
/// 
/// 4. **Validaciones**: Considerar agregar validaciones adicionales de formato
///    de email y estructura de nombres según crezca la base de usuarios.
/// 
/// 5. **Logging**: Los logs detallados son útiles para debugging pero pueden
///    removerse en producción final para mejor performance.
/// 
/// 6. **Error Handling**: El sistema nunca propaga errores hacia arriba,
///    siempre usa fallbacks. Evaluar si esto es apropiado para todos los casos.
/// 
/// 7. **Campos Futuros**: La estructura retorna 13 campos por usuario. Al
///    agregar nuevos campos a Firebase, actualizar el mapeo en getAllUsers().
/// 
/// 8. **Testing**: Los usuarios de fallback deben mantenerse actualizados
///    con la estructura real de Firebase para testing efectivo.