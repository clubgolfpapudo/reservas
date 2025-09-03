# Sistema de Reservas Multi-Deporte - Club de Golf Papudo

## Información General del Proyecto

**Fecha de actualización:** 3 de Septiembre, 2025  
**URL de Producción:** https://paddlepapudo.github.io/cgp_reservas/  
**Estado actual:** Sistema multi-deporte funcional con arquitectura limpia implementada  
**Usuarios activos:** 497+ socios sincronizados automáticamente  

### Stack Tecnológico

- **Framework:** Flutter 3.x
- **Lenguaje:** Dart
- **Backend:** Firebase (Firestore, Authentication, Functions)
- **Arquitectura:** Clean Architecture
- **Deployment:** GitHub Pages (Flutter Web)
- **Email System:** Firebase Functions con plantillas HTML personalizadas

---

## Arquitectura del Sistema

### Estructura de Carpetas (Clean Architecture)

```
lib/
├── core/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│       ├── firestore_service.dart
│       └── firebase_user_service.dart
├── domain/
│   ├── entities/
│   │   └── booking.dart
│   ├── repositories/
│   └── use_cases/
└── presentation/
    ├── pages/
    │   ├── admin_reservations_page.dart
    │   ├── golf_reservations_page.dart
    │   ├── paddle_reservations_page.dart
    │   └── tennis_reservations_page.dart
    ├── providers/
    │   ├── booking_provider.dart
    │   ├── auth_provider.dart
    │   └── admin_provider.dart
    └── widgets/
        ├── booking/
        └── admin/
```

### Componentes Principales

#### 1. Capa de Datos (Data Layer)

**`lib/data/services/firestore_service.dart`**
- Servicio principal para operaciones CRUD con Firebase
- Métodos clave:
  - `updateBooking(Booking booking)`: Actualización completa de reservas
  - `updateBookingPlayers(String bookingId, List<BookingPlayer> players)`: Actualización atómica de jugadores
  - `getBookingsByDate(DateTime date)`: Recuperación de reservas por fecha
  - `deleteBooking(String bookingId)`: Eliminación de reservas

#### 2. Capa de Dominio (Domain Layer)

**`lib/domain/entities/booking.dart`**
- Modelo de datos principal para reservas
- Campos principales:
  - `courtId`: Identificador de cancha/tee (ej: 'golf_tee_1', 'tennis_cancha_1')
  - `sport`: Tipo de deporte ('GOLF', 'TENIS', 'PADDLE')
  - `date`: Fecha de la reserva
  - `timeSlot`: Horario reservado
  - `players`: Lista de jugadores (BookingPlayer)

#### 3. Capa de Presentación (Presentation Layer)

**Provider Pattern para Estado:**
- `BookingProvider`: Gestiona estado de reservas y llamadas a servicios
- `AuthProvider`: Maneja autenticación de usuarios
- `AdminProvider`: Controla funcionalidades administrativas

**Páginas por Deporte:**
- `golf_reservations_page.dart`: Sistema de reservas para golf
- `tennis_reservations_page.dart`: Sistema de reservas para tenis  
- `paddle_reservations_page.dart`: Sistema de reservas para pádel

---

## Funcionalidades por Deporte

### Golf System
- **Canchas:** Hoyo 1 (golf_tee_1) y Hoyo 10 (golf_tee_10)
- **Capacidad:** 1-4 jugadores por reserva
- **Colores UI:** Verde golf (#4CAF50, #7CB342)
- **Plantilla Email:** generateGolfEmailTemplate() con diseño verde corporativo
- **Estado:** Funcional, sistema de emails implementado

### Tenis System  
- **Canchas:** 4 canchas (tennis_cancha_1 a tennis_cancha_4)
- **Nombres mostrados:** C.1, C.2, C.3, C.4 (implementado Sept 2025)
- **Capacidad:** Variable según configuración
- **Colores UI diferenciados por cancha:**
  - C.1: Azul (#2196F3)
  - C.2: Verde (#4CAF50)
  - C.3: Turquesa (#00BCD4)
  - C.4: Púrpura (#9C27B0)
- **Estado:** Completamente funcional con UI mejorada

### Pádel System
- **Canchas:** 3 canchas (PITE, LILEN, PLAIYA)
- **Capacidad:** Sistema estándar pádel
- **Colores UI:** Azul profesional (#2E7AFF, #1E5AFF) 
- **Auto-selección:** PITE por defecto
- **Modal de confirmación:** Muestra nombres reales de canchas (implementado Sept 2025)
- **Estado:** Completamente funcional

---

## Sistema de Backend (Firebase Functions)

### Estructura de Functions

**`functions/index.js`** - Archivo principal con todas las cloud functions

### Funciones Principales

#### 1. Sistema de Emails
```javascript
// Detección de deporte basada en courtId
function getSportFromCourtId(courtId) {
  const courtStr = String(courtId).trim().toLowerCase();
  
  if (courtStr.startsWith('tennis_') || courtStr.includes('tennis')) {
    return 'TENIS';
  } else if (courtStr.startsWith('golf_') || courtStr.includes('golf') || courtStr.includes('tee')) {
    return 'GOLF';
  } else {
    return 'PADEL'; // Default para pádel
  }
}

// Generación de HTML por deporte
function generateBookingEmailHtml(booking, organizerName, isVisitorBooking, email) {
  const sport = getSportFromCourtId(booking.courtId);
  
  if (sport === 'TENIS') {
    return generateTennisEmailTemplate(booking, organizerName, isVisitorBooking, email);
  } else if (sport === 'GOLF') {
    return generateGolfEmailTemplate(booking, organizerName, isVisitorBooking, email);
  } else {
    return generatePadelEmailTemplate(booking, organizerName, isVisitorBooking, email);
  }
}
```

#### 2. Plantillas de Email

**Golf Email Template:**
- Diseño verde corporativo (#4CAF50)
- Logo Club de Golf Papudo
- Información específica de tees (Hoyo 1/Hoyo 10)
- Botón de cancelación integrado
- Mensaje especial para jugadores VISITA

**Tennis/Paddle Templates:**
- Diseños diferenciados por colores de deporte
- Información específica de canchas
- Funcionalidad de cancelación

#### 3. Cloud Functions Activas
- `sendBookingEmailHTTP`: Envío de confirmaciones
- `cancelBooking`: Gestión de cancelaciones
- `sendCancellationNotification`: Notificaciones a jugadores restantes

---

## Base de Datos (Firestore)

### Estructura de Colecciones

```
cgpreservas/
├── users/{userId}
│   ├── uid: string
│   ├── name: string  
│   ├── email: string
│   └── memberNumber: string
├── bookings/{bookingId}
│   ├── courtId: string
│   ├── sport: string
│   ├── date: timestamp
│   ├── timeSlot: string
│   ├── players: array
│   └── organizerEmail: string
└── sports_config/{sportName}
    ├── courts: array
    ├── timeSlots: array
    └── maxPlayers: number
```

### Identificadores de Canchas

**Golf:**
- `golf_tee_1`: Hoyo 1
- `golf_tee_10`: Hoyo 10

**Tenis:**
- `tennis_cancha_1` a `tennis_cancha_4`

**Pádel:**
- `pite`, `lilen`, `plaiya`

---

## Sistema de Colores y Branding

### Diferenciación Visual por Deporte

```dart
// Golf
Color get _golfColor => const Color(0xFF4CAF50); // Verde golf
String get _golfDisplayName => 'golf';

// Tenis - Colores diferenciados por cancha
Color get _tenisColor => const Color(0xFFD2691E); // Tierra batida
String get _tenisDisplayName => 'tenis';

// Pádel
Color get _padelColor => const Color(0xFF2E7AFF); // Azul profesional  
String get _padelDisplayName => 'pádel';
```

### Implementación en Componentes

```dart
String get _sportDisplayName {
  if (widget.sport == 'TENIS') {
    return 'tenis';
  } else if (widget.sport == 'GOLF') {
    return 'golf';
  } else {
    return 'pádel';
  }
}

Color get _sportColor {
  if (widget.sport == 'TENIS') {
    return const Color(0xFFD2691E);
  } else if (widget.sport == 'GOLF') {
    return const Color(0xFF4CAF50);
  } else {
    return const Color(0xFF2E7AFF);
  }
}
```

---

## Issues Completamente Resueltos

### Arquitectura y Compilación (Agosto 2025)
- **Problema:** Implementación de golf violaba Clean Architecture
- **Solución:** Eliminación de 8+ archivos específicos problemáticos
- **Resultado:** Arquitectura consistente con patrón reutilizable

### Sistema de Emails por Deporte
- **Problema:** Golf usaba plantilla de pádel
- **Solución:** Implementación de `generateGolfEmailTemplate()` y lógica de detección
- **Resultado:** Cada deporte tiene su plantilla personalizada

### Error de Borrado Masivo de Jugadores (Septiembre 2025)
- **Problema:** Al eliminar un jugador, se borraban todos los jugadores
- **Causa:** Llamada a función genérica en lugar de atómica
- **Solución:** Implementación de `updateBookingPlayers()` específico
- **Estado:** ✅ RESUELTO

### Lógica de Slots Incompletos Golf (Septiembre 2025)
- **Problema:** Sistema no manejaba reservas parciales en golf
- **Requerimiento:** Mostrar capacidad X/Y y permitir unirse a slots existentes
- **Estado:** ✅ RESUELTO

### Nomenclatura Canchas de Tenis (Septiembre 2025)
- **Problema:** Nombres truncados ("Canc...") en interfaz
- **Solución:** Implementación de nombres "C.1", "C.2", "C.3", "C.4"
- **Archivos modificados:** `tennis_constants.dart`, `enhanced_court_tab.dart`
- **Resultado:** Colores diferenciados por cancha y nombres legibles
- **Estado:** ✅ RESUELTO

### Modal de Confirmación Pádel (Septiembre 2025)
- **Problema:** Modal mostraba "Cancha Pádel 1" en lugar del nombre real
- **Causa:** `AppConstants.getCourtName()` no mapeaba nombres reales
- **Solución:** Actualización de mapeo para PITE, LILEN, PLAIYA
- **Archivos modificados:** `app_constants.dart`
- **Estado:** ✅ RESUELTO

---

## Issues Pendientes

### **PRIORIDAD MEDIA**

#### Validación Backend Faltante
- **Descripción:** Sin validación para jugadores duplicados
- **Impacto:** Vulnerabilidad de integridad de datos
- **Solución propuesta:** Agregar validación en cloud functions
- **Prioridad:** Media (reclasificado de Alta)

#### Problemas UI Menores
- **Descripción:** Overflow botón "Ingresar", estadísticas incorrectas, AppBar dinámico
- **Impacto:** Experiencia de usuario
- **Prioridad:** Media

### **NUEVOS TEMAS PENDIENTES**

#### Agregar Link a Formulario de Registro
- **Ubicación:** Página de login
- **Descripción:** Implementar enlace al formulario de registro de nuevos usuarios
- **Prioridad:** Por definir

#### Ajustar Horario de Reserva de 72 Horas
- **Descripción:** Modificar ventana de reserva de 72 horas para Pádel y Tenis
- **Impacto:** Lógica de negocio
- **Deportes afectados:** Pádel y Tenis
- **Prioridad:** Por definir

---

## Métricas de Performance

### Compilación y Deployment
- **Build Flutter:** <40 segundos exitoso
- **Deploy Firebase Functions:** Sin errores tras correcciones
- **Carga inicial:** <3 segundos optimizada
- **Navegación entre deportes:** <500ms

### Base de Usuarios
- **Usuarios sincronizados:** 497+ socios activos
- **Deportes operativos:** 3 (Golf, Tenis, Pádel)
- **Canchas totales:** 9 (2 tees golf + 4 tenis + 3 pádel)

---

## Próximos Desarrollos Prioritarios

### Inmediato (Alto Impacto)
1. **Implementar ajuste horario reserva 72 horas**
   - Modificar lógica de negocio para Pádel y Tenis
   - Actualizar validaciones de fecha/hora

2. **Agregar funcionalidad registro nuevos usuarios**
   - Implementar link en página de login
   - Configurar flujo de onboarding

### Optimizaciones Mediano Plazo
3. **Resolver validación backend jugadores duplicados**
   - Agregar validación en cloud functions
   - Prevenir vulnerabilidad de integridad

4. **Resolver problemas UI menores**
   - Overflow botón "Ingresar"
   - Estadísticas incorrectas
   - AppBar dinámico por sección

### Testing y Calidad
5. **Testing integral sistema completo**
   - Validar flujo completo reservas todos los deportes
   - Confirmar emails funcionando correctamente
   - Testing de regresión para cambios recientes

---

## Guía de Desarrollo

### Para continuar el desarrollo de este proyecto:

1. **Clonar repositorio y configurar entorno:**
   ```bash
   git clone [repository-url]
   flutter pub get
   ```

2. **Configurar Firebase:**
   - Verificar `firebase.json` y configuración Functions
   - Asegurar permisos Firestore correctos

3. **Estructura de trabajo recomendada:**
   - Usar branches feature para nuevos desarrollos
   - Mantener `main` estable para producción
   - Seguir patrón Clean Architecture establecido

4. **Testing:**
   - Probar cada deporte por separado
   - Validar emails en entorno de pruebas
   - Confirmar funcionalidad admin antes de deploy

### Archivos críticos para modificaciones:

**Backend:**
- `functions/index.js`: Lógica principal cloud functions
- Plantillas email específicas por deporte

**Frontend:**  
- `lib/presentation/providers/booking_provider.dart`: Estado reservas
- `lib/data/services/firestore_service.dart`: Operaciones base datos
- `lib/presentation/pages/{sport}_reservations_page.dart`: UI por deporte

**Constantes y Configuración:**
- `lib/core/constants/app_constants.dart`: Mapeo nombres canchas
- `lib/core/constants/tennis_constants.dart`: Configuración tenis
- `lib/presentation/widgets/enhanced_court_tab.dart`: Colores diferenciados

### Cambios Recientes Implementados (Septiembre 2025):

1. **Sistema de nombres tenis:** C.1, C.2, C.3, C.4 con colores diferenciados
2. **Modal pádel:** Corrección para mostrar nombres reales (PITE, LILEN, PLAIYA)
3. **Mapeo de canchas:** Actualización completa en `AppConstants.getCourtName()`

El proyecto mantiene una arquitectura sólida y escalable, con separación clara de responsabilidades que facilita el mantenimiento y la adición de nuevas funcionalidades. Los desarrollos recientes han mejorado significativamente la experiencia de usuario y la consistencia visual del sistema.