# Sistema de Reservas Multi-Deporte - Club de Golf Papudo

## Información General del Proyecto

**Fecha de actualización:** 4 de Septiembre, 2025  
**URL de Producción:** https://paddlepapudo.github.io/cgp_reservas/  
**Estado actual:** Sistema multi-deporte funcional con ventana 72 horas y emails de admin implementados  
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
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── tennis_constants.dart
│   └── utils/                    
│       └── booking_time_utils.dart  
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│       ├── firestore_service.dart
│       ├── firebase_user_service.dart
│       └── email_service.dart
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
    │   ├── tennis_reservations_page.dart
    │   └── main.dart (SimpleLoginPage)
    ├── providers/
    │   ├── booking_provider.dart
    │   ├── auth_provider.dart
    │   └── admin_provider.dart
    └── widgets/
        ├── booking/
        ├── admin/
        └── enhanced_court_tab.dart
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

**`lib/data/services/email_service.dart`**
- Servicio centralizado para envío de emails
- Métodos implementados:
  - `sendBookingConfirmation(Booking booking)`: Confirmaciones de reserva
  - `sendCancellationNotification()`: Notificaciones de cancelación
  - `sendPlayerAddedNotification()`: Notificaciones cuando admin agrega jugador
  - `sendPlayerRemovedNotification()`: Notificaciones cuando admin remueve jugador

#### 2. Capa de Dominio (Domain Layer)

**`lib/domain/entities/booking.dart`**
- Modelo de datos principal para reservas
- Campos principales:
  - `courtId`: Identificador de cancha/tee (ej: 'golf_tee_1', 'tennis_cancha_1')
  - `date`: Fecha de la reserva (String)
  - `timeSlot`: Horario reservado (String)
  - `players`: Lista de jugadores (BookingPlayer)

**`lib/domain/entities/booking_player.dart`**
- Modelo para jugadores individuales
- Campos: `id`, `name`, `phone`, `email`, `isConfirmed`

#### 3. Capa de Presentación (Presentation Layer)

**Provider Pattern para Estado:**
- `BookingProvider`: Gestiona estado de reservas y llamadas a servicios
- `AuthProvider`: Maneja autenticación de usuarios
- `AdminProvider`: Controla funcionalidades administrativas

**Páginas por Deporte:**
- `main.dart`: Página de login principal (SimpleLoginPage)
- `golf_reservations_page.dart`: Sistema de reservas para golf
- `tennis_reservations_page.dart`: Sistema de reservas para tenis  
- `paddle_reservations_page.dart`: Sistema de reservas para pádel

---

## Funcionalidades por Deporte

### Golf System
- **Canchas:** Hoyo 1 (golf_tee_1) y Hoyo 10 (golf_tee_10)
- **Capacidad:** 1-4 jugadores por reserva
- **Colores UI:** Verde golf (#4CAF50, #7CB342)
- **Horarios:** 8:00 AM - 16:00/17:00 PM (invierno/verano), intervalos de 12 minutos
- **Ventana de reservas:** 48 horas desde hora actual
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
- **Horarios:** Slots predefinidos intervalos 90 min
  - Invierno: 9:00, 10:30, 12:00, 13:30, 15:00, 16:30
  - Verano: + 18:00, 19:30
- **Ventana de reservas:** 72 horas desde hora actual
- **Estado:** Funcional con UI mejorada y ventana 72h implementada

### Pádel System
- **Canchas:** 3 canchas (PITE, LILEN, PLAIYA)
- **Capacidad:** Sistema estándar pádel (4 jugadores)
- **Colores UI:** Azul profesional (#2E7AFF, #1E5AFF) 
- **Auto-selección:** PITE por defecto
- **Modal de confirmación:** Muestra nombres reales de canchas (implementado Sept 2025)
- **Horarios:** Slots predefinidos intervalos 90 min
  - Invierno: 9:00, 10:30, 12:00, 13:30, 15:00, 16:30
  - Verano: + 18:00, 19:30
- **Ventana de reservas:** 72 horas desde hora actual
- **Estado:** Completamente funcional con ventana 72h implementada

---

## Sistema de Backend (Firebase Functions)

### Estructura de Functions

**`functions/index.js`** - Archivo principal con todas las cloud functions

### Funciones Principales

#### 1. Sistema de Emails
```javascript
// Detección de tipo de email basada en parámetros
const requestType = req.body.type; // 'player_added', 'player_removed', o undefined
const { isAdminAction = false, adminActionType = null } = req.body;

// Generación condicional de contenido
if (requestType === 'player_added') {
  emailHtml = generateBookingEmailHtml(...).replace(...); // Reemplazos para "agregado"
} else if (requestType === 'player_removed') {
  emailHtml = generateBookingEmailHtml(...).replace(...); // Reemplazos para "removido"
} else {
  emailHtml = generateBookingEmailHtml(...); // Email normal
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
- `sendBookingEmailHTTP`: Envío de confirmaciones y notificaciones admin
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
│   ├── date: string
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
- `tennis_cancha_1` a `tennis_cancha_4` (mostrados como C.1 a C.4)

**Pádel:**
- `pite`, `lilen`, `plaiya` (nombres reales de las canchas)

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

### Implementación de Colores por Cancha de Tenis

```dart
// En enhanced_court_tab.dart
Color _getCourtPrimaryColor(String courtName) {
  switch (courtName) {
    case 'C.1': return const Color(0xFF2196F3); // Azul
    case 'C.2': return const Color(0xFF4CAF50); // Verde
    case 'C.3': return const Color(0xFF00BCD4); // Turquesa
    case 'C.4': return const Color(0xFF9C27B0); // Púrpura
    default: return const Color(0xFF2196F3);
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

### Nomenclatura y UI Canchas de Tenis (Septiembre 2025)
- **Problema:** Nombres truncados ("Canc...") en interfaz
- **Solución:** Implementación de nombres "C.1", "C.2", "C.3", "C.4"
- **Archivos modificados:** 
  - `tennis_constants.dart`: COURT_NAMES actualizadas
  - `enhanced_court_tab.dart`: Colores diferenciados por cancha
  - `tennis_reservations_page.dart`: Switch statements actualizados
- **Resultado:** Colores diferenciados por cancha y nombres legibles
- **Estado:** ✅ RESUELTO

### Modal de Confirmación Pádel (Septiembre 2025)
- **Problema:** Modal mostraba "Cancha Pádel 1" en lugar del nombre real
- **Causa:** `AppConstants.getCourtName()` no mapeaba nombres reales
- **Solución:** Actualización de mapeo para PITE, LILEN, PLAIYA
- **Archivos modificados:** `app_constants.dart`
- **Estado:** ✅ RESUELTO

### Overflow Página de Inicio (Septiembre 2025)
- **Problema:** Error "Bottom overflowed by X pixels" en main.dart
- **Causa:** `mainAxisAlignment.center` con contenido excesivo para pantalla
- **Solución:** Cambio a `mainAxisAlignment.start` y `mainAxisSize.max`, reducción de espaciados
- **Archivos modificados:** `main.dart`
- **Estado:** ✅ RESUELTO

### Link de Registro de Usuario (Septiembre 2025)
- **Problema:** Falta enlace para registro de nuevos usuarios
- **Solución:** Implementación de texto "Si tu correo no está registrado, regístralo aquí" con link funcional
- **Ubicación:** Debajo del botón "Ingresar" en página de login
- **Archivos modificados:** `main.dart` (imports flutter/gestures, url_launcher, función _launchRegistrationForm(), RichText)
- **URL destino:** https://docs.google.com/forms/d/e/1FAIpQLSfTWfH6tgPk9orGb8CUmAqHdtBFCRq-nlJLyJA2XVDr7OmCew/viewform?usp=sf_link
- **Estado:** ✅ RESUELTO

### Limpieza de Código Legacy (Septiembre 2025)
- **Problema:** Archivo `login_page.dart` sin referencias en el proyecto
- **Solución:** Eliminación del archivo no utilizado
- **Justificación:** Sin imports ni navegación hacia esa página en todo el codebase
- **Impacto:** Reducción de tamaño del proyecto y eliminación de confusión
- **Estado:** ✅ RESUELTO

### Ventana de Reservas 72 Horas (Septiembre 2025)
- **Problema:** Tenis y Pádel no implementaban ventana de 72 horas desde hora actual
- **Solución:** Implementación de `BookingTimeUtils` con slots predefinidos + filtrado cliente-side
- **Archivos modificados:** 
  - **NUEVO:** `lib/core/utils/booking_time_utils.dart`
  - **MODIFICADO:** `lib/presentation/providers/booking_provider.dart` (métodos agregados + `_generateAvailableDates()` actualizado)
  - **MODIFICADO:** `lib/presentation/pages/tennis_reservations_page.dart` (forzar regeneración fechas)
  - **MODIFICADO:** `lib/presentation/pages/paddle_reservations_page.dart` (forzar regeneración fechas)
- **Lógica implementada:** 
  - Golf mantiene 48 horas (sin cambios)
  - Tennis/Pádel: 72 horas con slots predefinidos según temporada
  - Invierno: 6 slots (9:00 a 16:30)
  - Verano: 8 slots (+ 18:00, 19:30)
- **Estado:** ✅ RESUELTO Y FUNCIONAL

### Envío de Emails para Modificaciones de Admin (Septiembre 2025)
- **Problema:** Cuando Admin agrega o remueve jugadores de slots incompletos, no se enviaban emails de notificación
- **Solución implementada:**
  - Integración con `EmailService.sendPlayerAddedNotification()` y nuevo método `sendPlayerRemovedNotification()`
  - Modificaciones en Firebase Functions (`functions/index.js`) para manejar nuevos tipos de email
  - Lógica de detección de cambios en `editBookingPlayers()` de `BookingProvider`
  - Plantillas de email diferenciadas para acciones de admin usando reemplazo de texto
- **Archivos modificados:**
  - **AGREGADO:** `lib/data/services/email_service.dart` - método `sendPlayerRemovedNotification()`
  - **MODIFICADO:** `lib/presentation/providers/booking_provider.dart` - método `_handleAdminPlayerChangesNotification()`
  - **MODIFICADO:** `functions/index.js` - manejo de `requestType` ('player_added'/'player_removed')
- **Funcionalidad:**
  - Admin agrega jugador → Email "Agregado a Reserva de [Deporte]" 
  - Admin remueve jugador → Email "Removido de Reserva de [Deporte]"
  - Usa estructura de `EmailService` existente (evita problemas CORS)
  - Subject y contenido específicos por tipo de acción
  - **NOTA TÉCNICA:** Implementación actual usa reemplazo de texto sobre plantillas existentes (solución temporal funcional). Requiere desarrollo de plantillas HTML específicas para admin en futuras iteraciones.
- **Estado:** ✅ RESUELTO Y FUNCIONAL (implementación temporal)

---

## Issues Pendientes

### **PRIORIDAD ALTA**

#### Mejoras Interfaz Administrador (Septiembre 2025)
- **Problema:** Panel de administración (`admin_reservations_page.dart`) con problemas de UX
- **Issues identificados:**
  - Texto sobrepuesto en elementos de UI
  - Overflow de contenido en pantallas pequeñas
  - Filtro de reservas en pantalla no funciona correctamente
  - Layout responsive deficiente
- **Archivos afectados:** 
  - `lib/presentation/pages/admin_reservations_page.dart`
  - Posible refactor de componentes de admin
- **Prioridad:** Alta (afecta operaciones diarias del club)

### **PRIORIDAD MEDIA**

#### Optimización de Performance - Logs Masivos (Septiembre 2025)
- **Problema:** Golf genera 1300+ líneas de log al cambiar fechas, causando performance lenta
- **Causa:** Debug prints en `_generateAvailableDates()` creando flood de logs
- **Impacto:** Performance degradada en navegación de fechas golf
- **Solución propuesta:** Remover debug prints de producción
- **Archivos afectados:** `booking_provider.dart`, páginas de tennis/pádel
- **Prioridad:** Media (sistema funciona, pero con performance subóptima)

#### Verificar Funcionalidad Link de Registro en Producción
- **Descripción:** Formulario de Google Forms requiere autenticación cuando antes funcionaba sin login
- **URL:** https://docs.google.com/forms/d/e/1FAIpQLSfTWfH6tgPk9orGb8CUmAqHdtBFCRq-nlJLyJA2XVDr7OmCew/viewform?usp=sf_link
- **Causa probable:** Cambio reciente en configuración o políticas de Google Forms
- **Estado:** Pendiente verificación en producción (funciona en localhost)
- **Solución temporal:** Si persiste, cambiar mensaje a contacto directo por email
- **Ubicación:** Implementado en `main.dart` clase `_SimpleLoginPageState`
- **Prioridad:** Media

#### Validación Backend Faltante
- **Descripción:** Sin validación para jugadores duplicados en reservas
- **Impacto:** Vulnerabilidad de integridad de datos
- **Solución propuesta:** Agregar validación en cloud functions
- **Prioridad:** Media

#### Mejora de Plantillas Email Admin
- **Descripción:** Crear plantillas HTML específicas para acciones de admin en lugar de usar reemplazo de texto
- **Beneficios:** Mejor diseño, consistencia visual, mantenibilidad
- **Archivos afectados:** `functions/index.js`
- **Estado:** Funcional con solución temporal
- **Prioridad:** Media

#### Problemas UI Menores
- **Descripción:** Estadísticas incorrectas, AppBar dinámico por sección
- **Impacto:** Experiencia de usuario
- **Prioridad:** Media

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

### Inmediato (Alta Prioridad)
1. **Mejorar interfaz de administrador**
   - Resolver problemas de layout y overflow
   - Implementar filtros funcionales de reservas
   - Optimizar para pantallas pequeñas

### Mediano Plazo (Media Prioridad)
2. **Limpieza de performance**
   - Remover debug prints de producción
   - Optimizar navegación de fechas en golf

3. **Mejora de plantillas email admin**
   - Desarrollar plantillas HTML específicas
   - Eliminar dependencia de reemplazo de texto

4. **Validaciones backend**
   - Jugadores duplicados
   - Integridad de datos

### Testing y Calidad
5. **Testing integral sistema completo**
   - Validar flujo completo reservas todos los deportes
   - Confirmar emails funcionando correctamente
   - Testing de regresión para cambios implementados
   - Validar funcionalidades admin en diferentes dispositivos

---

## Warnings y Consideraciones Importantes

### 🚨 Advertencias Técnicas

1. **Plantillas Email Admin**
   - Implementación actual es temporal usando reemplazo de texto
   - Funcional pero requiere desarrollo de plantillas específicas
   - Monitorear que los reemplazos sigan funcionando tras updates

2. **Formulario de Google Forms**
   - Puede requerir autenticación en producción
   - Monitorear funcionamiento tras deployment
   - Tener plan B de contacto directo preparado

3. **Performance Logs Golf**
   - Debug prints causan degradación de performance
   - Priorizar limpieza para mejorar experiencia usuario
   - No afecta funcionalidad pero sí UX

### 📋 Notas para el Cliente

1. **Funcionalidades Nuevas Implementadas**
   - Sistema de ventana 72 horas para Tennis/Pádel funcionando completamente
   - Emails automáticos cuando admin modifica jugadores (temporal pero funcional)
   - Canchas de tenis con nombres claros y colores únicos
   - Modal de pádel muestra nombres reales de canchas

2. **Sistema de Emails Completo**
   - Funcionando para los 3 deportes
   - Cobertura total: crear, cancelar, modificar por admin
   - Cada deporte tiene su plantilla personalizada

3. **Interfaz Admin Pendiente**
   - Funcional pero con problemas de UX
   - Requiere atención prioritaria para operaciones diarias

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
- `lib/data/services/email_service.dart`: Envío de emails centralizado
- `lib/presentation/pages/{sport}_reservations_page.dart`: UI por deporte

**Constantes y Configuración:**
- `lib/core/constants/app_constants.dart`: Mapeo nombres canchas
- `lib/core/constants/tennis_constants.dart`: Configuración tenis
- `lib/core/utils/booking_time_utils.dart`: Lógica ventana 72 horas
- `lib/presentation/widgets/enhanced_court_tab.dart`: Colores diferenciados

**Página Principal:**
- `lib/presentation/pages/main.dart`: Login y navegación principal (SimpleLoginPage)

### Estado Actual del Sistema (Septiembre 2025):

**✅ FUNCIONAL:** Sistema multi-deporte completo con ventana de tiempo diferenciada (48h golf, 72h tennis/pádel), emails automáticos para todas las acciones (crear, cancelar, modificar admin), y UI optimizada por deporte.

**⚠️ PENDIENTE:** Optimización interfaz admin, limpieza debug logs, mejora plantillas email admin.

El proyecto mantiene una arquitectura sólida y escalable, con separación clara de responsabilidades y funcionalidad completa para operación diaria del club.