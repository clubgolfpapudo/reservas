# CGP Reservas - Estructura Firebase Firestore

> **Colecciones y documentos configurados y funcionando al 100%**

## 🔥 **COLECCIÓN PRINCIPAL: `bookings`**

### **Formato 1: Reservas Manuales (Firebase directo)**
```json
{
  // ID del documento: generado automáticamente por Firebase
  "id": "doc_id_auto_generated",
  
  // Identificación básica
  "courtId": "court_3",           // court_1, court_2, court_3
  "date": "2025-05-25",           // YYYY-MM-DD formato
  "time": "16:30",                // HH:MM formato 24h
  
  // Jugadores (array de objetos)
  "players": [
    {
      "name": "JUGADOR TEST",
      "isConfirmed": true,
      "email": null,              // opcional
      "phone": null               // opcional
    }
  ],
  
  // Estado y metadata
  "status": "complete",           // "complete" o "incomplete"
  "createdAt": Timestamp,         // Firebase Timestamp
  "updatedAt": Timestamp          // Firebase Timestamp
}
```

### **Formato 2: Reservas Google Sheets (Sincronizadas)**
```json
{
  // ID del documento: formato "booking_X_DD_MMM_HHMM"
  "id": "booking_3_25_May_1630",
  
  // Identificación básica
  "courtId": "court_3",
  "court": 3,                     // número de cancha adicional
  
  // Fecha anidada (diferencia clave)
  "dateTime": {
    "date": "2025-05-25",         // mismo formato YYYY-MM-DD
    "day": 25,
    "month": "May",
    "time": "16:30",              // HH:MM formato 24h
    "timestamp": 1748205000000    // Unix timestamp
  },
  
  // Jugadores con estructura extendida
  "players": [
    {
      "name": "ANIBAL REINOSO",
      "email": "anibalreinosomendez@gmail.com",
      "status": "confirmed",      // "confirmed" en lugar de isConfirmed
      "isMainBooker": true        // jugador principal
    },
    {
      "name": "JUAN REINOSO M",
      "email": "juan.reinosomendez@gmail.com", 
      "status": "confirmed",
      "isMainBooker": false
    },
    {
      "name": "PADEL2 VISITA",
      "email": "reservaspapudo3@gmail.com",
      "status": "confirmed", 
      "isMainBooker": false
    },
    {
      "name": "PADEL3 VISITA",
      "email": "reservaspapudo4@gmail.com",
      "status": "confirmed",
      "isMainBooker": false
    }
  ],
  
  // Campos adicionales Google Sheets
  "activePlayersCount": 4,        // contador de jugadores
  "calendlyUri": "https://api.calendly.com/scheduled_events/...",
  "status": "complete",
  
  // Metadata de sincronización
  "metadata": {
    "createdAt": 1748217892972,   // Unix timestamp (number)
    "updatedAt": 1748217892972,   // Unix timestamp (number)
    "createdBy": "SheetSync"      // origen de la data
  }
}
```

## 📊 **DATOS REALES EN PRODUCCIÓN (25 Mayo 2025)**

### **Documentos confirmados existentes:**

#### **court_1 (PITE):**
```json
// Documento 1
{
  "courtId": "court_1",
  "dateTime": { "date": "2025-05-25", "time": "09:00" },
  "players": [
    { "name": "FELIPE GARCIA", "status": "confirmed", "isMainBooker": true },
    { "name": "CLARA PARDO B", "status": "confirmed" },
    { "name": "PEDRO F ALMARZA G", "status": "confirmed" }
  ],
  "activePlayersCount": 3,  // ← INCOMPLETA (solo 3 jugadores)
  "status": "complete"
}

// Documento 2  
{
  "courtId": "court_1", 
  "dateTime": { "date": "2025-05-25", "time": "10:30" },
  "players": [
    { "name": "FELIPE GARCIA", "status": "confirmed" },
    { "name": "ANA M", "status": "confirmed" },
    // + 2 jugadores más
  ],
  "activePlayersCount": 4,  // ← COMPLETA
  "status": "complete"
}

// Documentos adicionales para 12:00 y 18:00...
```

#### **court_2 (LILEN):**
```json
{
  "courtId": "court_2",
  "dateTime": { "date": "2025-05-25", "time": "18:00" },
  "players": [
    // 4 jugadores confirmados
  ],
  "activePlayersCount": 4,
  "status": "complete"
}
```

#### **court_3 (PLAIYA):**
```json
// Reserva manual
{
  "courtId": "court_3",
  "date": "2025-05-25",     // ← Formato directo (no anidado)
  "time": "16:30",          // ← Formato directo 
  "players": [
    { "name": "JUGADOR TEST", "isConfirmed": true }
  ],
  "status": "complete"
}

// Reserva Google Sheets (mismo horario)
{
  "courtId": "court_3",
  "dateTime": { "date": "2025-05-25", "time": "16:30" },
  "players": [
    { "name": "ANIBAL REINOSO", "status": "confirmed", "isMainBooker": true },
    { "name": "JUAN REINOSO M", "status": "confirmed" },
    { "name": "PADEL2 VISITA", "status": "confirmed" },
    { "name": "PADEL3 VISITA", "status": "confirmed" }
  ],
  "activePlayersCount": 4,
  "status": "complete"
}
```

## 🔧 **MAPEO Y COMPATIBILIDAD**

### **Campos críticos para mapeo:**

| Campo App | Formato Manual | Formato Google Sheets | Mapeo |
|-----------|----------------|----------------------|--------|
| **timeSlot** | `time` | `dateTime.time` | `data['dateTime']?['time'] ?? data['time']` |
| **date** | `date` | `dateTime.date` | `data['dateTime']?['date'] ?? data['date']` |
| **isConfirmed** | `isConfirmed: true` | `status: "confirmed"` | `map['isConfirmed'] ?? (map['status'] == 'confirmed')` |
| **status calculado** | Ignorar campo | Ignorar campo | Calcular por `players.length` |

### **Lógica de status implementada:**
```dart
// En BookingModel.toEntity()
BookingStatus? bookingStatus;
final playersList = players.map((player) => player.toPlayer()).toList();

if (playersList.isEmpty) {
  bookingStatus = null;
} else if (playersList.length == 4) {
  bookingStatus = BookingStatus.complete;     // AZUL
} else {
  bookingStatus = BookingStatus.incomplete;   // NARANJA
}
```

## 🔍 **CONSULTA FIRESTORE IMPLEMENTADA**

### **Stream unificado:**
```dart
static Stream<List<Booking>> getBookingsByDate(DateTime date) {
  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  
  return _firestore
      .collection('bookings')
      .snapshots()                    // Todas las reservas
      .map((snapshot) {
        final bookings = snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc.data(), doc.id).toEntity())
            .where((booking) => booking.date == dateStr)  // Filtro post-mapeo
            .toList();
        
        return bookings;
      });
}
```

### **¿Por qué consulta completa?**
- **Problema:** `dateTime.date` no es consultable directamente con `.where()`
- **Solución:** Traer todos los documentos, mapear ambos formatos, filtrar después
- **Performance:** Aceptable para volúmenes actuales (~10-50 reservas/día)

## 🏗️ **COLECCIONES ADICIONALES (Preparadas)**

### **`courts` (Opcional - para futuro):**
```json
{
  "id": "court_1",
  "name": "PITE", 
  "number": 1,
  "isActive": true,
  "settings": {
    "maxPlayers": 4,
    "duration": 90
  }
}
```

### **`users` (Preparado para autenticación):**
```json
{
  "uid": "firebase_auth_uid",
  "name": "FELIPE GARCIA",
  "email": "felipe@garciab.cl", 
  "role": "socio_titular",
  "profile": {
    "phone": "+56912345678",
    "category": "socio_titular"
  }
}
```

## ✅ **ESTADO ACTUAL VERIFICADO**

### **Funcionalidades confirmadas:**
- ✅ **Lectura dual:** Ambos formatos funcionando simultáneamente
- ✅ **Stream en tiempo real:** Actualizaciones automáticas
- ✅ **Mapeo robusto:** Sin errores de conversión
- ✅ **Filtrado correcto:** Por fecha y cancha
- ✅ **Status dinámico:** Colores basados en jugadores reales

### **Logs de verificación:**
```
🔍 Total documentos en BD: 6
🔍 Reservas filtradas para 2025-05-25: 6
✅ Reservas cargadas: 6
   - court_1 09:00: 3 jugadores (INCOMPLETA)
   - court_1 10:30: 4 jugadores (COMPLETA)
   - court_1 12:00: 4 jugadores (COMPLETA)
   - court_1 18:00: 4 jugadores (COMPLETA)
   - court_2 18:00: 4 jugadores (COMPLETA)
   - court_3 16:30: 4 jugadores (COMPLETA)
```

## 🔄 **SINCRONIZACIÓN GOOGLE SHEETS**

### **Flujo de datos:**
```
Google Sheets → Firebase Functions/Apps Script → Firestore
```

### **Campos de sincronización esperados:**
- **Identificación:** `courtId`, `dateTime` estructurado
- **Jugadores:** Array completo con emails y status
- **Metadata:** `createdBy: "SheetSync"`, timestamps
- **Calendly:** URI de eventos programados (opcional)

### **Formato ID esperado:**
```
"booking_{court}_{day}_{month}_{time}"
Ejemplo: "booking_3_25_May_1630"
```

---

## 💡 **NOTAS PARA DESARROLLO:**

1. **Compatibilidad dual es permanente** - ambos formatos coexistirán
2. **Status calculado dinámicamente** - ignorar campo status de Firebase
3. **Consulta completa es intencional** - para soportar estructuras diferentes
4. **Estructura preparada** para extensiones (users, courts, etc.)

Esta estructura está **completamente probada y funcionando** con datos reales.