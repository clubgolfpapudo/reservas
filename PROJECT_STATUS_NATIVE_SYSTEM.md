# PROJECT STATUS - NATIVE SYSTEM

## INFORMACIÓN GENERAL DEL PROYECTO

**Nombre:** Sistema de Reservas de Pádel - Club de Golf Papudo  
**Stack:** Flutter Web + Firebase  
**Dominio:** https://cgpreservas.web.app  
**Estado:** ✅ **FUNCIONAL - PRODUCCIÓN COMPLETA**

## FUNCIONALIDADES IMPLEMENTADAS Y OPERATIVAS

### ✅ SISTEMA CORE - 100% FUNCIONAL
- **Reservas multi-jugador:** Hasta 4 jugadores por reserva
- **Calendario interactivo:** Selección de fecha y horario
- **Gestión de canchas:** 3 canchas disponibles (Court 1, 2, 3)
- **Base de datos:** Firebase Firestore completamente configurada
- **UI/UX:** Interfaz moderna y responsive

### ✅ SISTEMA DE EMAILS - 100% FUNCIONAL
- **Notificaciones automáticas:** Emails a todos los jugadores al crear reserva
- **URLs personalizadas:** Cada jugador recibe su email personalizado en el botón "Cancelar"
- **HTML profesional:** Emails con diseño del club y toda la información de la reserva
- **Función:** `sendBookingEmailHTTP` - Deploy exitoso y operativa

### ✅ CANCELACIÓN INDIVIDUAL - 100% FUNCIONAL
- **Cancelación por jugador:** Cada jugador puede cancelarse individualmente sin afectar a otros
- **Lógica diferenciada:** 
  - Si cancela organizador: Se elimina toda la reserva
  - Si cancela invitado: Solo se remueve ese jugador, reserva continúa
- **Función:** `cancelBooking` - Deploy exitoso y operativa
- **Página de confirmación:** HTML de confirmación al cancelar exitosamente

## ARQUITECTURA TÉCNICA

### FRONTEND - Flutter Web
```
lib/
├── main.dart                 # Entry point
├── screens/
│   ├── booking_screen.dart   # Pantalla principal de reservas
│   └── confirmation_screen.dart
├── services/
│   └── booking_service.dart  # Lógica de negocio
├── widgets/
│   ├── calendar_widget.dart  # Selector de fechas
│   ├── court_selector.dart   # Selector de canchas
│   └── time_slot_widget.dart # Selector de horarios
└── models/
    └── booking_model.dart    # Modelo de datos
```

### BACKEND - Firebase Functions
```
functions/
├── index.js                  # Cloud Functions principales
├── package.json             # Dependencias Node.js
└── node_modules/            # Librerías instaladas
```

**Funciones Cloud desplegadas:**
- `sendBookingEmailHTTP` ✅ Operativa
- `cancelBooking` ✅ Operativa

### BASE DE DATOS - Firestore
**Colección:** `bookings`
```javascript
{
  id: "court1-2025-06-05-1200",      // ID único generado
  courtNumber: "court_1",             // Cancha seleccionada
  date: "2025-06-05",                 // Fecha de reserva
  timeSlot: "12:00",                  // Horario
  players: [                          // Array de jugadores
    {
      name: "Felipe García",
      email: "felipe@garciab.cl",
      phone: "+56912345678"
    },
    {
      name: "Ana Buzeta", 
      email: "ana@buzeta.cl",
      phone: "+56987654321"
    }
  ],
  status: "confirmed",                // Estado de la reserva
  createdAt: Timestamp,               // Fecha de creación
  lastModified: Timestamp             // Última modificación
}
```

## CONFIGURACIÓN DE DESARROLLO

### Requisitos del Sistema
- **Flutter:** 3.24.5+ 
- **Dart:** 3.5.4+
- **Firebase CLI:** Última versión
- **Node.js:** 20+ (para Cloud Functions)

### Variables de Entorno
```bash
# Firebase Project
PROJECT_ID: cgpreservas
REGION: us-central1

# URLs de producción
WEB_APP: https://cgpreservas.web.app
FUNCTIONS_BASE: https://us-central1-cgpreservas.cloudfunctions.net
```

### Comandos de Deploy
```bash
# Deploy completo
firebase deploy

# Solo functions
firebase deploy --only functions --force

# Solo hosting
firebase deploy --only hosting

# Logs en tiempo real
firebase functions:log --only=sendBookingEmailHTTP
firebase functions:log --only=cancelBooking
```

## FLUJO DE USUARIO COMPLETO

### 1. CREAR RESERVA
1. Usuario selecciona **fecha** en calendario
2. Usuario selecciona **cancha** (Court 1, 2, o 3)
3. Usuario selecciona **horario** disponible
4. Usuario ingresa datos de **hasta 4 jugadores**:
   - Nombre completo
   - Email válido
   - Teléfono (opcional)
5. Sistema genera **ID único**: `court1-2025-06-05-1200`
6. Se guarda en **Firestore**
7. Se envían **emails automáticos** a todos los jugadores

### 2. EMAILS AUTOMÁTICOS
- **Asunto:** "Reserva de Pádel Confirmada - Club de Golf Papudo"
- **Contenido:** Todos los detalles de la reserva
- **Botón personalizado:** "Cancelar mi participación" con URL única por jugador
- **URL ejemplo:** `https://us-central1-cgpreservas.cloudfunctions.net/cancelBooking?id=court1-2025-06-05-1200&email=felipe%40garciab.cl`

### 3. CANCELACIÓN INDIVIDUAL
- Jugador hace click en **"Cancelar"** desde su email
- Sistema identifica **qué jugador** cancela por el email en la URL
- **Si es organizador (primer jugador):** Elimina toda la reserva
- **Si es invitado:** Solo remueve ese jugador, otros continúan
- Muestra página de **confirmación exitosa**

## ÚLTIMOS BUGS SOLUCIONADOS

### ❌ Bug: URLs de cancelación incorrectas
**Problema:** Todos los emails tenían el email del organizador en la URL
**Solución:** Se corrigió para pasar `playerEmail` individual a cada email
**Status:** ✅ Solucionado - Deploy exitoso

### ❌ Bug: Cancelación elimina toda la reserva
**Problema:** Al cancelar cualquier jugador se eliminaba toda la reserva
**Solución:** Se implementó lógica diferenciada:
- Organizador cancela → Elimina reserva completa  
- Invitado cancela → Solo remueve ese jugador
**Status:** ✅ Solucionado - Deploy exitoso

### ❌ Bug: Firebase no detectaba cambios
**Problema:** `firebase deploy` decía "No changes detected"
**Solución:** Se agregaron comentarios para forzar detección de cambios
**Status:** ✅ Solucionado

## TESTING REALIZADO

### ✅ Test Completo de Reservas
- Creación de reserva con 4 jugadores ✅
- Recepción de emails personalizados ✅
- URLs únicas por jugador ✅
- Cancelación individual de invitado ✅
- Verificación de que otros jugadores permanecen ✅

### ✅ Test de Edge Cases
- Cancelación cuando solo queda 1 jugador ✅
- Reservas en diferentes canchas y horarios ✅
- Manejo de emails con caracteres especiales ✅

## HORARIOS Y CONFIGURACIÓN OPERATIVA

### ⏰ Horarios Disponibles
- **Lunes a Domingo:** 08:00 - 22:00
- **Slots de tiempo:** Intervalos de 1.5 horas
- **Slots disponibles:** 08:00, 09:30, 11:00, 12:30, 14:00, 15:30, 17:00, 18:30, 20:00, 21:30

### 🏓 Canchas Disponibles
- **Court 1** (court_1)
- **Court 2** (court_2) 
- **Court 3** (court_3)

### 📧 Configuración de Emails
- **Servicio:** Firebase Functions con Nodemailer
- **Remitente:** Sistema automatizado del club
- **Templates:** HTML responsive con diseño del club

## DEBUGGING Y LOGS

### 🔍 Comandos de Debugging
```bash
# Ver logs específicos
firebase functions:log --only=sendBookingEmailHTTP --lines=20
firebase functions:log --only=cancelBooking --lines=20

# Debugging en tiempo real
firebase functions:log --follow

# Ver todas las reservas en Firestore
# Acceder via Firebase Console > Firestore Database > bookings collection
```

### 📊 Información de Logs Clave
- **Emails enviados:** Confirmación de cada email individual
- **Cancelaciones:** Logs detallados de qué jugador cancela
- **Errores comunes:** Emails inválidos, IDs no encontrados

## BUGS ACTUALES IDENTIFICADOS

### 🚨 **Bug Crítico: Lógica de Fecha de Apertura**
**Problema:** La app siempre se abre mostrando HOY, incluso cuando ya pasaron todas las horas de reserva del día  
**Comportamiento actual:** Si son las 23:00, aún muestra reservas de hoy (ya imposibles)  
**Comportamiento deseado:** Si la hora actual > última reserva del día, abrir automáticamente en día siguiente  
**Prioridad:** 🔴 ALTA - Afecta UX diariamente  
**Archivos afectados:** `lib/screens/booking_screen.dart` - Lógica de inicialización de fecha

### 🚨 **Bug UI: Overflow en Popup de Reserva (Chrome)**
**Problema:** Error de constraints y overflow en modal de resumen de reserva  
**Error específico:**
```
BoxConstraints has non-normalized height constraints
A RenderFlex overflowed by 4.8 pixels on the bottom
BOTTOM OVERFLOWED BY 2.0 PIXELS
```
**Prioridad:** 🟡 MEDIA - Solo afecta Chrome, funcional pero visualmente incorrecto  
**Archivos afectados:** Widget del popup de reserva  
**Solución sugerida:** Ajustar constraints de altura y usar Scrollable

### 🚨 **Limitación Crítica: Usuarios Hardcodeados**
**Problema:** Los usuarios están definidos en el código, no en base de datos  
**Impacto:** Imposible agregar/editar socios sin modificar código  
**Requerimiento:** Migrar a Firebase + sincronización con Google Sheets  
**Prioridad:** 🔴 ALTA - Bloquea escalabilidad  

## MEJORAS REQUERIDAS PRIORITARIAS

### 🔄 **URGENT - Lógica de Fecha Inteligente**
```dart
// Implementar en booking_screen.dart
DateTime getInitialDate() {
  final now = DateTime.now();
  final lastSlotToday = DateTime(now.year, now.month, now.day, 21, 30); // 21:30 última reserva
  
  if (now.isAfter(lastSlotToday)) {
    return now.add(Duration(days: 1)); // Mostrar mañana
  }
  return now; // Mostrar hoy
}
```

### 🔄 **URGENT - Sistema de Usuarios Dinámico**
**Implementar:**
1. **Colección Firebase:** `users` o `socios`
2. **Sincronización:** Google Sheets API → Firebase
3. **Campos requeridos:**
   - Nombre completo
   - Email
   - Teléfono
   - Estado (activo/inactivo)
   - Tipo de socio

**Google Sheets Integration:**
- **Planilla:** 'MaestroSocios'
- **Función Cloud:** `syncUsersFromSheets`
- **Frecuencia:** Diaria o manual

### 🔄 **MEDIUM - Fix UI Overflow**
**Popup de reserva necesita:**
1. **Constraints flexibles** para diferentes tamaños de pantalla
2. **ScrollView** para contenido largo
3. **Responsive design** específico para Chrome

## PRÓXIMAS MEJORAS SUGERIDAS

### 🔄 Funcionalidades Adicionales
1. **Panel de administración** para gestionar reservas desde web
2. **Notificaciones push** para recordatorios
3. **Integración con calendario** (Google Calendar, Outlook)
4. **Sistema de pagos** online
5. **Reportes de uso** de canchas
6. **App móvil nativa** (iOS/Android)

### 🔧 Optimizaciones Técnicas
1. **Cache de horarios** disponibles
2. **Validación de horarios** en tiempo real
3. **Backup automático** de reservas
4. **Logs más detallados** para debugging
5. **Tests automatizados** unitarios y de integración

## CONOCIMIENTO CONTEXTUAL IMPORTANTE

### 🏌️ Sobre el Club
- **Nombre:** Club de Golf Papudo
- **Ubicación:** Papudo, Chile
- **Deporte:** Sistema específico para reservas de **Pádel** (no golf)
- **Capacidad:** Máximo 4 jugadores por reserva (estándar del pádel)

### 👤 Roles de Usuario
- **Organizador:** Primer jugador que crea la reserva
- **Invitados:** Jugadores 2, 3 y 4 agregados a la reserva
- **Lógica:** Solo el organizador puede eliminar toda la reserva; invitados solo se auto-cancelan

### 🔄 Flujo de Cancelación Específico
- **Organizador cancela:** Toda la reserva se elimina (asume que el organizador coordina)
- **Invitado cancela:** Solo ese jugador se remueve, reserva continúa con otros jugadores
- **Página de confirmación:** Diferente mensaje según tipo de cancelación

## PROBLEMAS CONOCIDOS Y SOLUCIONES

### ⚠️ Problemas Actuales Conocidos
1. **Fecha de apertura:** Siempre muestra HOY independiente de la hora actual
2. **UI overflow:** Error de constraints en popup de reserva (Chrome específico)
3. **Usuarios hardcodeados:** No hay gestión dinámica de socios desde Firebase
4. **Google Sheets:** Falta sincronización con planilla 'MaestroSocios'

### ⚠️ Problemas Potenciales Futuros
1. **Firebase quotas:** Con mucho uso, verificar límites de Cloud Functions
2. **Emails spam:** Algunos proveedores pueden marcar emails automáticos como spam
3. **Concurrencia:** Múltiples usuarios reservando mismo horario simultáneamente
4. **URLs largas:** URLs de cancelación pueden ser truncadas en algunos clientes de email

### 🛠️ Soluciones Implementadas
1. **Encoding de emails:** `encodeURIComponent()` para caracteres especiales
2. **Logging detallado:** Para debugging rápido de problemas
3. **Error handling:** Páginas de error amigables para usuarios
4. **CORS configurado:** Para permitir requests desde el frontend

## COMANDOS RÁPIDOS DE DESARROLLO

```bash
# Levantar entorno local
flutter run -d chrome

# Ver logs en tiempo real
firebase functions:log --lines=50

# Deploy rápido de functions
firebase deploy --only functions --force

# Verificar status de funciones
firebase functions:list

# Abrir Firebase Console
start https://console.firebase.google.com/project/cgpreservas
```

## TAREAS INMEDIATAS PRIORIZADAS

### 🔴 **PRIORIDAD ALTA (Próxima sesión)**
1. **Lógica de fecha inteligente** - Si hora actual > 21:30, abrir en día siguiente
2. **Sistema de usuarios dinámico** - Migrar desde hardcode a Firebase + Google Sheets
3. **Fix overflow popup** - Solucionar constraints y RenderFlex en Chrome

### 🟡 **PRIORIDAD MEDIA**
1. **Panel de administración** básico para ver/cancelar reservas
2. **Validación de horarios** en tiempo real para evitar conflictos
3. **Tests automatizados** para flujos críticos

### 🟢 **PRIORIDAD BAJA**
1. **Notificaciones push** y recordatorios
2. **Integración calendario** personal
3. **App móvil nativa**

## INFORMACIÓN PARA DESARROLLO DE GOOGLE SHEETS

### 📊 **Planilla 'MaestroSocios'**
**Estructura esperada:**
- **Columna A:** Nombre completo
- **Columna B:** Email
- **Columna C:** Teléfono  
- **Columna D:** Estado (Activo/Inactivo)
- **Columna E:** Tipo de socio (opcional)

**Implementación necesaria:**
```javascript
// Nueva función Cloud: syncUsersFromSheets
exports.syncUsersFromSheets = onRequest(async (req, res) => {
  // 1. Conectar Google Sheets API
  // 2. Leer planilla 'MaestroSocios'
  // 3. Sincronizar con colección 'users' en Firestore
  // 4. Manejar usuarios nuevos/editados/eliminados
});
```