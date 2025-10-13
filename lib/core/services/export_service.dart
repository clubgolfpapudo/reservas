// lib/core/services/export_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exporta reservas a Excel para un rango de fechas
  Future<void> exportReservationsToExcel({
    required DateTime startDate,
    required DateTime endDate,
    String? sport, // null = todos los deportes
  }) async {
    try {
      print('🔍 Iniciando exportación de reservas...');
      print('📅 Rango: ${startDate.toString()} - ${endDate.toString()}');
      print('🏀 Deporte: ${sport ?? "Todos"}');
      
      // 1. Obtener reservas del rango de fechas
      final reservations = await _getReservationsInRange(
        startDate,
        endDate,
        sport,
      );

      print('✅ Reservas obtenidas: ${reservations.length}');
      
      if (reservations.isEmpty) {
        print('⚠️ No se encontraron reservas para el rango seleccionado');
      }

      // 2. Crear archivo Excel
      final excel = Excel.createExcel();
      final sheet = excel['Reservas'];

      // 3. Agregar encabezados
      _addHeaders(sheet);

      // 4. Agregar datos
      int rowIndex = 1;
      for (var reservation in reservations) {
        _addReservationRow(sheet, rowIndex, reservation);
        rowIndex++;
      }

      print('📊 Filas agregadas al Excel: $rowIndex');

      // 5. Eliminar sheet por defecto
      excel.delete('Sheet1');

      // 6. Descargar archivo
      _downloadExcelFile(excel, startDate, endDate);
      print('✅ Archivo descargado exitosamente');
    } catch (e) {
      print('❌ Error al exportar reservas: $e');
      throw Exception('Error al exportar reservas: $e');
    }
  }

  /// Obtiene reservas de Firestore en el rango especificado
  Future<List<Map<String, dynamic>>> _getReservationsInRange(
    DateTime startDate,
    DateTime endDate,
    String? sport,
  ) async {
    try {
      // Ajustar fechas para incluir todo el día
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      print('🔎 Buscando en Firestore...');
      print('   Start: ${start.toString()}');
      print('   End: ${end.toString()}');

      // Convertir fechas a formato String YYYY-MM-DD (como están en Firestore)
      final startString = DateFormat('yyyy-MM-dd').format(start);
      final endString = DateFormat('yyyy-MM-dd').format(end);
      
      print('   Start String: $startString');
      print('   End String: $endString');

      // Consulta usando Strings en lugar de Timestamps
      Query query = _firestore.collection('bookings')
          .where('date', isGreaterThanOrEqualTo: startString)
          .where('date', isLessThanOrEqualTo: endString)
          .orderBy('date', descending: false);

      final snapshot = await query.get();
      
      print('📦 Documentos obtenidos de Firestore: ${snapshot.docs.length}');

      List<Map<String, dynamic>> reservations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        print('   📄 Doc ID: ${doc.id}, Court: ${data['courtId']}, Date: ${data['date']}');
        
        // Filtrar por deporte si se especificó
        if (sport != null) {
          final courtId = data['courtId'] as String?;
          if (courtId != null && !_matchesSport(courtId, sport)) {
            print('      ⏭️ Filtrado: no coincide con deporte $sport');
            continue;
          }
        }

        // Agregar ID del documento
        data['id'] = doc.id;
        reservations.add(data);
      }

      print('✅ Reservas después de filtrar: ${reservations.length}');

      // Ordenar por fecha y luego por timeSlot en memoria
      reservations.sort((a, b) {
        final dateA = a['date'] as String? ?? '';
        final dateB = b['date'] as String? ?? '';
        
        final dateComparison = dateA.compareTo(dateB);
        if (dateComparison != 0) return dateComparison;
        
        // Si las fechas son iguales, ordenar por timeSlot
        final timeA = a['timeSlot'] as String? ?? '';
        final timeB = b['timeSlot'] as String? ?? '';
        return timeA.compareTo(timeB);
      });

      return reservations;
    } catch (e, stackTrace) {
      print('❌ Error en _getReservationsInRange: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Determina si una cancha corresponde al deporte especificado
  bool _matchesSport(String courtId, String sport) {
    final courtLower = courtId.toLowerCase();
    if (sport == 'Golf' && courtLower.contains('golf')) return true;
    if (sport == 'Tenis' && courtLower.contains('tennis')) return true;
    if (sport == 'Pádel' && (courtLower.contains('padel') || courtLower.contains('pádel'))) return true;
    return false;
  }

  /// Agrega encabezados a la hoja de Excel
  void _addHeaders(Sheet sheet) {
    final headers = [
      'ID Reserva',
      'Fecha',
      'Hora',
      'Deporte',
      'Cancha',
      'Jugador Principal',
      'Email Principal',
      'Jugador 2',
      'Jugador 3',
      'Jugador 4',
      'Estado',
      'Fecha Creación',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }
  }

  /// Agrega una fila con datos de reserva
  void _addReservationRow(Sheet sheet, int rowIndex, Map<String, dynamic> data) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final datetimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Parsear fecha (ahora es String en formato YYYY-MM-DD)
    String formattedDate = '';
    if (data['date'] is String) {
      try {
        final dateString = data['date'] as String;
        final parsedDate = DateTime.parse(dateString); // Parse "2025-10-08"
        formattedDate = dateFormat.format(parsedDate); // Format to "08/10/2025"
      } catch (e) {
        formattedDate = data['date'] as String; // Si falla, usar el string original
      }
    }

    // Parsear fecha de creación
    String formattedCreatedAt = '';
    if (data['createdAt'] is Timestamp) {
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      formattedCreatedAt = datetimeFormat.format(createdAt);
    } else if (data['createdAt'] is String) {
      formattedCreatedAt = data['createdAt'] as String;
    }

    // Determinar deporte por courtId
    final courtId = data['courtId'] as String? ?? '';
    final courtLower = courtId.toLowerCase();
    String sport = 'Desconocido';
    String courtName = courtId;
    
    if (courtLower.contains('golf')) {
      sport = 'Golf';
      // Extraer el nombre limpio: golf_tee_1 -> Tee 1, golf_tee_10 -> Tee 10
      if (courtId.contains('tee')) {
        final parts = courtId.split('_');
        if (parts.length >= 3) {
          courtName = 'Tee ${parts[2]}';
        } else {
          courtName = 'Golf';
        }
      } else {
        courtName = 'Cancha de Golf';
      }
    } else if (courtLower.contains('tennis') || courtLower.contains('tenis')) {
      sport = 'Tenis';
      // Extraer número: tennis_court_1 -> Tenis 1
      final parts = courtId.split('_');
      if (parts.length >= 3) {
        courtName = 'Tenis ${parts[2]}';
      } else {
        courtName = 'Tenis';
      }
    } else if (courtLower.contains('padel') || courtLower.contains('pádel')) {
      sport = 'Pádel';
      // Extraer número: Pádel_court_1 -> Pádel 1
      final parts = courtId.split('_');
      if (parts.length >= 3) {
        courtName = 'Pádel ${parts[2]}';
      } else {
        courtName = 'Pádel';
      }
    }

    // Obtener jugadores
    final players = data['players'] as List<dynamic>? ?? [];
    final mainPlayer = players.isNotEmpty ? players[0] as Map<String, dynamic>? : null;
    
    // Obtener nombres de jugadores adicionales
    String player2Name = '';
    String player3Name = '';
    String player4Name = '';
    
    if (players.length > 1) {
      final p2 = players[1] as Map<String, dynamic>?;
      player2Name = p2?['name'] ?? '';
    }
    if (players.length > 2) {
      final p3 = players[2] as Map<String, dynamic>?;
      player3Name = p3?['name'] ?? '';
    }
    if (players.length > 3) {
      final p4 = players[3] as Map<String, dynamic>?;
      player4Name = p4?['name'] ?? '';
    }

    final values = [
      data['id'] ?? '',
      formattedDate,
      data['timeSlot'] ?? '',
      sport,
      courtName,
      mainPlayer?['name'] ?? '',
      mainPlayer?['email'] ?? '',
      player2Name,
      player3Name,
      player4Name,
      data['status'] ?? 'active',
      formattedCreatedAt,
    ];

    for (int i = 0; i < values.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = TextCellValue(values[i].toString());
    }
  }

  /// Descarga el archivo Excel generado
  void _downloadExcelFile(Excel excel, DateTime startDate, DateTime endDate) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final filename = 'Reservas_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.xlsx';

    // Convertir a bytes
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Error al generar archivo Excel');
    }

    // Crear blob y descargar
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Exporta estadísticas resumidas
  Future<void> exportStatisticsToExcel({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final reservations = await _getReservationsInRange(startDate, endDate, null);

      final excel = Excel.createExcel();
      
      // Hoja 1: Resumen por deporte
      _createSportSummarySheet(excel, reservations);
      
      // Hoja 2: Horarios más populares
      _createTimeSlotSummarySheet(excel, reservations);
      
      // Hoja 3: Usuarios más activos
      _createUserSummarySheet(excel, reservations);

      excel.delete('Sheet1');

      final dateFormat = DateFormat('yyyy-MM-dd');
      final filename = 'Estadisticas_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.xlsx';

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Error al generar archivo Excel');

      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Error al exportar estadísticas: $e');
    }
  }

  void _createSportSummarySheet(Excel excel, List<Map<String, dynamic>> reservations) {
    final sheet = excel['Resumen por Deporte'];
    
    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Deporte');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Total Reservas');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Porcentaje');

    // Estilo para headers
    for (int col = 0; col < 3; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }

    // Contar por deporte con detección mejorada
    final Map<String, int> sportCount = {};
    for (var res in reservations) {
      final courtId = res['courtId'] as String? ?? '';
      final courtLower = courtId.toLowerCase();
      
      String sport = 'Otros';
      if (courtLower.contains('golf')) {
        sport = 'Golf';
      } else if (courtLower.contains('tennis') || courtLower.contains('tenis')) {
        sport = 'Tenis';
      } else if (courtLower.contains('padel') || courtLower.contains('pádel')) {
        sport = 'Pádel';
      }
      
      sportCount[sport] = (sportCount[sport] ?? 0) + 1;
    }

    int row = 1;
    final total = reservations.length;
    
    // Ordenar por cantidad (mayor a menor)
    final sortedSports = sportCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedSports) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
          IntCellValue(entry.value);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
          TextCellValue('${(entry.value / total * 100).toStringAsFixed(1)}%');
      row++;
    }
  }

  void _createTimeSlotSummarySheet(Excel excel, List<Map<String, dynamic>> reservations) {
    final sheet = excel['Horarios Populares'];
    
    // Headers con estilo
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Horario');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Total Reservas');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Porcentaje');
    
    for (int col = 0; col < 3; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }

    // Contar por horario
    final Map<String, int> timeSlotCount = {};
    for (var res in reservations) {
      final timeSlot = res['timeSlot'] as String? ?? 'Sin horario';
      timeSlotCount[timeSlot] = (timeSlotCount[timeSlot] ?? 0) + 1;
    }

    // Ordenar por cantidad (mayor a menor)
    final sortedSlots = timeSlotCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int row = 1;
    final total = reservations.length;
    
    for (var entry in sortedSlots) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          TextCellValue(entry.key);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
          IntCellValue(entry.value);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
          TextCellValue('${(entry.value / total * 100).toStringAsFixed(1)}%');
      row++;
    }
  }

  void _createUserSummarySheet(Excel excel, List<Map<String, dynamic>> reservations) {
    final sheet = excel['Usuarios Activos'];
    
    // Headers con estilo
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Ranking');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Usuario');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Email');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Total Reservas');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Porcentaje');
    
    for (int col = 0; col < 5; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }

    // Contar reservas por usuario (jugador principal)
    final Map<String, Map<String, dynamic>> userCount = {};
    for (var res in reservations) {
      final players = res['players'] as List<dynamic>? ?? [];
      if (players.isNotEmpty) {
        final mainPlayer = players[0] as Map<String, dynamic>?;
        if (mainPlayer != null) {
          final email = mainPlayer['email'] as String? ?? 'sin-email';
          if (!userCount.containsKey(email)) {
            userCount[email] = {
              'name': mainPlayer['name'] ?? 'Sin nombre',
              'email': email,
              'count': 0,
            };
          }
          userCount[email]!['count'] = (userCount[email]!['count'] as int) + 1;
        }
      }
    }

    // Ordenar por cantidad de reservas (mayor a menor)
    final sortedUsers = userCount.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    int row = 1;
    final total = reservations.length;
    
    // Top 50 usuarios más activos
    for (var user in sortedUsers.take(50)) {
      final count = user['count'] as int;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = 
          IntCellValue(row); // Ranking
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = 
          TextCellValue(user['name'] as String);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = 
          TextCellValue(user['email'] as String);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = 
          IntCellValue(count);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = 
          TextCellValue('${(count / total * 100).toStringAsFixed(1)}%');
      
      // Destacar top 3 con color
      if (row <= 3) {
        for (int col = 0; col < 5; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromInt(0xFFF9E79F), // Amarillo suave
          );
        }
      }
      
      row++;
    }
  }
}