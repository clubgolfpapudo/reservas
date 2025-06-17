// lib/core/services/firebase_user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserService {
  FirebaseUserService() {
    print('🔥 FirebaseUserService INITIALIZED - DEBUG MODE ACTIVE');
  }
  static const String _defaultEmail = 'felipe@garciab.cl';
  static const String _defaultName = 'FELIPE GARCIA B';

  /// Obtiene el email del usuario actual
  static Future<String> getCurrentUserEmail() async {
    return _defaultEmail;
  }

  /// Obtiene el nombre del usuario actual  
  static Future<String> getCurrentUserName() async {
    return _defaultName;
  }

  /// 🔥 CARGAR USUARIOS CON ESTRUCTURA REAL (displayName + campos separados)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    print('🔥 INICIANDO carga de usuarios desde Firebase...');
    
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      print('🔥 Conectando a colección users...');
      
      final QuerySnapshot snapshot = await firestore
          .collection('users')
          .get();

      print('🔥 Query ejecutada. Documentos encontrados: ${snapshot.docs.length}');

      final List<Map<String, dynamic>> users = [];
      int validUsers = 0;
      int invalidUsers = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Validar que tenga email válido
          if (data.containsKey('email') && 
              data['email'] != null && 
              data['email'].toString().trim().isNotEmpty) {
            
            String email = data['email'].toString().trim().toLowerCase();
            String name = _extractNameFromRealStructure(data);
            
            if (name.isNotEmpty) {
              users.add({
                'name': name,
                'email': email,
              });
              
              validUsers++;
              
              if (validUsers <= 5) {
                print('✅ Usuario ${validUsers}: $name - $email');
              }
              
            } else {
              invalidUsers++;
              if (invalidUsers <= 3) {
                print('⚠️ Usuario sin nombre válido: $email');
              }
            }
            
          } else {
            invalidUsers++;
            if (invalidUsers <= 3) {
              print('❌ Usuario sin email: ${doc.id}');
            }
          }
        } catch (e) {
          invalidUsers++;
          print('❌ Error procesando documento ${doc.id}: $e');
        }
      }

      print('✅ RESUMEN FINAL:');
      print('   ✅ $validUsers usuarios válidos procesados');
      print('   ❌ $invalidUsers usuarios inválidos');
      print('   🎉 ${users.length} usuarios totales disponibles');
      
      // Ordenar alfabéticamente
      users.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
      
      if (users.isNotEmpty) {
        print('🎉 Retornando ${users.length} usuarios de Firebase');
        return users;
      } else {
        print('⚠️ No se encontraron usuarios válidos, usando fallback');
        return _getFallbackUsers();
      }
      
    } catch (e) {
      print('❌ ERROR CRÍTICO cargando usuarios: $e');
      return _getFallbackUsers();
    }
  }

  /// 🔧 EXTRAER NOMBRE DE LA ESTRUCTURA REAL
  static String _extractNameFromRealStructure(Map<String, dynamic> data) {
    try {
      // DEBUG: Imprimir todos los campos disponibles
      print('🔍 DEBUG - Campos disponibles en data:');
      data.forEach((key, value) {
        print('  $key: $value');
      });
      
      // PRIORIDAD 1: Usar campo 'name' (formato correcto desde Firebase)
      if (data.containsKey('name') && 
          data['name'] != null && 
          data['name'].toString().trim().isNotEmpty) {
        
        String nameFromFirebase = data['name'].toString().trim().toUpperCase();
        print('✅ USANDO CAMPO NAME: $nameFromFirebase');
        return nameFromFirebase;
      } else {
        print('❌ Campo name no disponible, usando fallback');
      }
      
      // PRIORIDAD 2: Usar displayName si existe y no está vacío
      if (data.containsKey('displayName') &&
          data['displayName'] != null &&
          data['displayName'].toString().trim().isNotEmpty) {

        String displayNameFromFirebase = data['displayName'].toString().trim().toUpperCase();
        // 🔥 NUEVO: Quitar puntos al final del displayName
        displayNameFromFirebase = displayNameFromFirebase.replaceAll(RegExp(r'\.$'), '');
        print('✅ USANDO DISPLAYNAME (sin puntos): $displayNameFromFirebase');
        return displayNameFromFirebase;
      } else {
        print('❌ Campo displayName no disponible');
      }
      
      // PRIORIDAD 3: Construir desde campos separados (FALLBACK)
      print('⚠️ USANDO FALLBACK - construyendo desde campos separados');
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
          nameParts.add(apellidoMaterno[0]); // Sin punto - CRÍTICO: AQUÍ NO DEBE HABER PUNTO
          print('  Inicial apellido materno: ${apellidoMaterno[0]} (sin punto)');
        }
      }
      
      if (nameParts.isNotEmpty) {
        String resultado = nameParts.join(' ').toUpperCase();
        print('🔧 RESULTADO FALLBACK: $resultado');
        return resultado;
      }
      
      // PRIORIDAD 4: Fallback desde email
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

  /// 🔧 GENERAR NOMBRE DESDE EMAIL (fallback)
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

  /// 🔄 USUARIOS DE FALLBACK EXPANDIDOS
  static List<Map<String, dynamic>> _getFallbackUsers() {
    print('🔄 Usando usuarios de fallback (Firebase no disponible)...');
    
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