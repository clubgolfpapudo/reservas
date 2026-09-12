# Sistema de Reservas Multi-Deporte - Club de Golf Papudo

## Información General del Proyecto

**Última actualización:** 12 de septiembre de 2026 (Chile)

**URL de Producción:** https://cgpreservas.web.app (Firebase Hosting)

**URL de Desarrollo:** https://cgpreservas--dev-uw52qzyg.web.app (Canal DEV)

**Estado actual:** Sistema multi-deporte funcional con persistencia de sesión, reportes administrativos, sistema de cancelación protegido contra prefetching, y bloqueos administrativos de horarios para actividades recurrentes y mantenciones de cancha.

**Usuarios activos:** 519+ socios sincronizados automáticamente

**Cliente:** Club de Golf Papudo

**Stack principal:** Flutter Web + Firebase (Firestore, Authentication, Functions)

**Desarrollo:** Felipe García B + Claude

> **Nota de mantenimiento de este documento:** este archivo es la fuente única de verdad del estado del proyecto. Debe actualizarse después de cada cambio significativo, agregando la entrada nueva al **final** de la sección "Registro de Cambios" (orden cronológico ascendente). El 12.09.2026 se reorganizó completo el documento: antes mezclaba entradas fuera de orden cronológico, repetía el mismo fix dos veces con distinto nivel de detalle, y tenía números de versión y fechas de "última actualización" contradictorias entre secciones. Ver detalle de la limpieza al final del documento.

---

## Stack Tecnológico

- **Framework:** Flutter 3.x
- **Lenguaje:** Dart
- **Backend:** Firebase (Firestore, Authentication, Functions)
- **Arquitectura:** Clean Architecture
- **Hosting:** Firebase Hosting con canales de desarrollo
- **Deployment Producción:** `firebase deploy --only hosting`
- **Deployment Desarrollo:** `firebase hosting:channel:deploy dev`
- **Testing Local:** `firebase serve --only hosting`
- **Email System:** Firebase Functions con plantillas HTML personalizadas
- **Sincronización:** Google Sheets API con service account automático
- **Persistencia Web:** localStorage nativo del navegador
- **Exportación de datos:** Librería Excel 4.0.3 para generación de reportes
- **Runtime:** Node.js 20 (Firebase Functions Gen2)

---

## Historial de Versiones (resumen)

| Versión | Fecha | Resumen |
|---|---|---|
| v1.0 | Septiembre 2025 | Migración inicial a Firebase |
| — | 1 de octubre de 2025 | Ajuste horarios Pádel/Tenis, UI modal Golf, fix email multi-deporte |
| v1.1 | 5 de octubre de 2025 | Persistencia de sesión (localStorage) |
| v1.2 | 13 de octubre de 2025 | Sistema de reportes y estadísticas (Excel) |
| v2.1.2 | 30 de octubre de 2025 | Corrección integral: ventanas de reserva dinámicas, navegación, títulos |
| v2.1.3 | 2 de noviembre de 2025 | Fix bug email prefetching (`cancelBookingConfirm`), upgrade Node.js 20 |
| — | 19 de noviembre de 2025 | Fix bug error 404 en cancelación (llave de cierre faltante en `functions/index.js`) |
| v2.1.4 | 21 de noviembre de 2025 | Validación 4 horas al unirse a reserva existente + fix inicialización primera carga |
| v2.2.0 | 1-2 de enero de 2026 | Sistema de bloqueos administrativos de horarios (escuelitas/torneos) + extensión horario golf a 18:00 |
| v2.2.1 | 2 de enero de 2026 | Bloqueo adicional Pádel LILEN (febrero 2026) |
| v2.2.2 | 3-10 de abril de 2026 | Bloqueo mantención antegreens Hoyo 1 (6-16 abril) |
| v2.2.3 | 10 de abril de 2026 | Desbloqueo temporal manual Hoyo 10 (durante mantención Hoyo 1) |
| v2.2.4 | 14 de abril de 2026 | Lógica automática de fechas para desbloqueo Hoyo 10 + planificación mantención Hoyo 10 |
| — | 11 de agosto de 2026 | Migración de facturación y acceso a cuenta `puntocom.cl` (administrativo, sin cambios de código) |
| v2.2.5 | 12 de septiembre de 2026 (efectivo desde el 14.09.2026) | Extensión del último horario de Pádel/Tenis de 16:30 a 18:00 |

---

## Registro de Cambios

### v1.0 — Septiembre 2025 — Migración inicial a Firebase

Migración del sistema original (Google Apps Script + Calendly) a Flutter Web + Firebase (Firestore, Authentication, Functions). Base arquitectónica sobre la que se construyen todas las versiones siguientes.

---

### 1 de octubre de 2025 — Ajustes de horarios y UI

#### Configuración de Horarios Pádel y Tenis

- **Problema:** Horarios extendidos hasta 21:00 desde octubre, necesitaban volver a 16:30
- **Solución implementada:** Ajuste de configuración en archivos de constantes
- **Archivos modificados:**
  - `lib/core/constants/app_constants.dart` (líneas 47, 54, 78-88)
  - `lib/core/utils/booking_time_utils.dart` (líneas 9-11)
- **Configuración actual:**
  - Horario de verano: 09:00 - 16:30 (último slot)
  - Horario de invierno: 09:00 - 16:30 (último slot)
  - Slots eliminados: 18:00, 19:30, 21:00
- **Estado:** ✅ Implementado y funcional

#### Mejora UI Modal Golf — Botón Cancelar Destacado

- **Problema:** Botón "Cancelar" tenía menos presencia visual que "Confirmar Reserva"
- **Solución implementada:**
  - Botón "Cancelar" con fondo rojo (#D32F2F) y texto blanco
  - Mismo tamaño y peso visual que "Confirmar Reserva"
  - Mejora en distribución espacial de botones
- **Archivo modificado:** `lib/presentation/pages/golf_reservations_page.dart` (método `_handleSlotTap`)
- **Beneficio:** Usuarios pueden salir del modal fácilmente sin confirmar reserva
- **Estado:** ✅ Implementado y funcional

#### Corrección Email Multi-Deporte — Notificación de Cancelación

- **Problema crítico:** Email de cancelación hardcodeado para "Pádel" en todas las reservas
- **Impacto:** Reservas de Golf/Tenis mostraban texto incorrecto ("Pádel") al cancelar
- **Solución implementada:**
  - Detección automática de deporte por `courtId`
  - Texto dinámico según deporte (Golf/Tenis/Pádel)
  - Nombres de cancha correctos por deporte
  - Colores de header específicos por deporte
  - Emojis apropiados (⛳ Golf, 🎾 Tenis, 🏸 Pádel)
- **Archivo modificado:** `functions/index.js` (función `sendCancellationNotification`)
- **Ejemplo de corrección:**
  - **ANTES:** "se retiró de la reserva de Pádel" (incorrecto para Golf)
  - **DESPUÉS:** "se retiró de la reserva de Golf" (correcto dinámicamente)
- **Estado:** ✅ Corregido y funcional

---

### v1.1 — 5 de octubre de 2025 — Persistencia de Sesión

**Problema identificado:**
- El sistema antiguo (GAS + Calendly) recordaba las credenciales del usuario
- El nuevo sistema Flutter obligaba a ingresar el email en cada sesión
- Usuarios reportaban molestia, especialmente en dispositivos móviles (iPhone y Android)

**Enfoque de solución:**

**Primera aproximación fallida:** SharedPreferences
- Agregada dependencia `shared_preferences: ^2.2.2`
- Problema: No funciona consistentemente en Flutter Web
- Limitación detectada: SharedPreferences tiene comportamiento irregular en navegadores web

**Solución final implementada:** localStorage nativo de JavaScript
- Creado servicio `WebStorageService` que usa `dart:html`
- Acceso directo a `window.localStorage` del navegador
- Tres valores persistidos:
  - `cgp_user_email`: Email del usuario
  - `cgp_user_name`: Nombre completo del usuario
  - `cgp_is_logged_in`: Flag booleano de sesión activa

**Archivos creados/modificados:**
- **NUEVO:** `lib/core/services/web_storage_service.dart` - Servicio de localStorage
- **MODIFICADO:** `lib/presentation/providers/auth_provider.dart` - Integración con localStorage
  - Método `saveSession()`: Guarda credenciales en localStorage
  - Método `checkAutoLogin()`: Lee sesión guardada al iniciar app
  - Método `logout()`: Limpia sesión de localStorage
  - Validación contra Firebase para verificar que usuario aún existe

**Funcionamiento:**
1. Usuario ingresa email por primera vez
2. Sistema valida contra Firestore (519+ usuarios)
3. Si es válido, guarda email y nombre en localStorage
4. Al volver a abrir la app:
   - Lee localStorage
   - Si encuentra sesión válida, verifica contra Firebase
   - Auto-login automático sin pedir credenciales

**Estado en el momento de implementación:**
- ✅ Funcional en ambiente de desarrollo (DEV)
- ✅ Probado en Chrome Desktop con éxito
- ✅ Probado en Firefox con éxito
- Validación exhaustiva en dispositivos móviles completada posteriormente (ver Roadmap)

**Limitaciones conocidas:**
- Modo incógnito: localStorage se borra al cerrar navegador (comportamiento estándar web)
- Android Chrome: Forzar cierre de app puede borrar localStorage en algunos casos
- Solución recomendada: Instalar como PWA (Progressive Web App) para mejor persistencia

---

### v1.2 — 13 de octubre de 2025 — Sistema de Reportes y Estadísticas

**Funcionalidad implementada:**

Nueva página administrativa para exportar datos de reservas y estadísticas a archivos Excel.

**Archivos creados:**

1. **`lib/core/services/export_service.dart`** - Servicio de exportación de datos
   - Consulta a Firestore por rango de fechas
   - Filtrado por deporte (Golf/Tenis/Pádel)
   - Generación de archivos Excel con múltiples hojas
   - Detección inteligente de deportes por `courtId`

2. **`lib/features/admin/presentation/pages/admin_reports_page.dart`** - Interfaz de reportes
   - Selector de rango de fechas con DatePicker
   - Filtro por deporte específico
   - Dos opciones de exportación:
     - Reservas Detalladas
     - Estadísticas Resumidas

**Características del sistema de reportes:**

✅ **Exportación de Reservas Detalladas:**
- Todas las reservas del período seleccionado
- Columnas: ID Reserva, Fecha, Hora, Deporte, Cancha, Jugadores (1-4), Email Principal, Estado, Fecha Creación
- Ordenamiento por fecha y hora
- Filtrado opcional por deporte

✅ **Exportación de Estadísticas (3 hojas):**
1. **Resumen por Deporte:** Total de reservas y porcentaje por cada deporte
2. **Horarios Populares:** Slots más reservados con porcentajes
3. **Usuarios Activos (Top 50):** Ranking de usuarios con más reservas, destacando Top 3 en amarillo

**Detección inteligente de deportes:**

El sistema identifica el deporte basándose en el `courtId`:
- `golf_tee_1`, `golf_tee_10` → **Golf** (Cancha: "Tee 1", "Tee 10")
- `tennis_court_1` → **Tenis** (Cancha: "Tenis 1")
- `Pádel_court_1` → **Pádel** (Cancha: "Pádel 1")

**Formato de fechas en Firestore:**

⚠️ **Importante:** Las fechas se almacenan como **String** en formato `YYYY-MM-DD` (no Timestamp)
- Ejemplo: `"2025-10-08"`
- Las consultas usan comparación de strings
- El formateo en Excel muestra `DD/MM/YYYY`

**Integración en menú admin:**
- Ruta: `/admin/reports`
- Accesible desde el dashboard administrativo
- Ya configurado en `admin_constants.dart`
- Navegación implementada en `admin_dashboard_page.dart`

**Dependencias agregadas:**
```yaml
dependencies:
  excel: ^4.0.3  # Generación de archivos Excel
  intl: ^0.18.0  # Formateo de fechas (ya existente)
```

**Estado:** ✅ Completado y desplegado a producción

---

### v2.1.2 — 30 de octubre de 2025 — Corrección Integral Sistema de Reservas

**Tag Git:** `v2.1.2`

#### 🐛 Problemas Identificados y Corregidos

1. **CRÍTICO - Ventanas de Reserva Incorrectas**
   - **Problema:** Lógica hardcoded con hora fija (16:00) no se ajustaba a cambios de horario
   - **Solución:** Implementación de verificación dinámica de slots disponibles
   - **Impacto:** Golf mostraba días incorrectos, Pádel/Tenis no mostraban reservas del día actual después de las 16:00

2. **Header de Tenis Mostraba "Pádel"**
   - **Problema:** Título hardcodeado incorrectamente
   - **Solución:** Corregido a "Tenis" en `tennis_reservations_page.dart`

3. **Navegación Entre Deportes**
   - **Problema:** Al cambiar de deporte, mantenía estado del deporte anterior
   - **Solución:** Reset de provider al cargar cada página de deporte

4. **Botón Retroceso Congelaba App**
   - **Problema:** `DateNavigationHeader` usaba `Navigator.pop()` hardcodeado
   - **Solución:** Implementar callbacks `onBackPressed` correctamente

#### ⚙️ Cambios Técnicos Implementados

**1. Ventanas de Tiempo Dinámicas (`booking_provider.dart`)**
```dart
// ANTES: Lógica hardcoded
bool hasSlotsToday = now.hour < 16; // ❌ Fijo a 16:00

// DESPUÉS: Verificación dinámica
final todaySlots = AppConstants.getTimeSlotsForSport(sport, today);
bool hasSlotsToday = todaySlots.any((timeSlot) {
  // Verifica si hay slots después de la hora actual
  return slotTimeInMinutes > currentTimeInMinutes;
});
```

**Lógica de Ventanas:**
- **Golf:** 48 horas desde ahora
  - Si la ventana cae dentro del horario de golf de un día → ese día se muestra completo
  - Ejemplo: 30.10 08:13 → muestra 30.10, 31.10, 01.11
- **Pádel/Tenis:** 72 horas desde ahora
  - Similar a Golf pero con ventana de 3 días
  - Ejemplo: 30.10 17:20 → muestra 30.10 (slots 18:00, 19:30), 31.10, 01.11, 02.11

**2. Ajuste de Horarios**

Archivos modificados:
- `lib/core/constants/app_constants.dart`
- `lib/core/utils/booking_time_utils.dart`

Cambio: Horario final de Pádel/Tenis extendido de 16:30 a 19:30

**3. Corrección Header de Navegación**

Archivo: `lib/presentation/widgets/date_navigation_header.dart`
```dart
// ANTES: Siempre usaba Navigator.pop()
IconButton(
  onPressed: () => Navigator.of(context).pop(), // ❌
  ...
)

// DESPUÉS: Usa callback proporcionado
IconButton(
  onPressed: onBackPressed ?? () => Navigator.of(context).pop(), // ✅
  ...
)
```

#### 🧪 Casos de Prueba Validados

**Escenario 1: 30.10.2025 a las 08:00**
- Golf: ✅ Muestra 30.10, 31.10
- Pádel/Tenis: ✅ Muestra 30.10, 31.10, 01.11

**Escenario 2: 30.10.2025 a las 17:20**
- Golf: ✅ Muestra 31.10, 01.11 (sin slots disponibles hoy)
- Pádel/Tenis: ✅ Muestra 30.10 (18:00, 19:30), 31.10, 01.11, 02.11

**Escenario 3: 30.10.2025 a las 20:00**
- Golf: ✅ Muestra 31.10, 01.11
- Pádel/Tenis: ✅ Muestra 31.10, 01.11, 02.11 (sin HOY)

**Escenario 4: Navegación Entre Deportes**
- ✅ Pádel → Tenis: Cambia correctamente sin estado residual
- ✅ Botón "←" vuelve al hub sin congelarse
- ✅ Cada deporte muestra su título correcto

#### 📊 Archivos Modificados

- `lib/presentation/providers/booking_provider.dart` - Lógica ventanas dinámicas
- `lib/presentation/pages/tennis_reservations_page.dart` - Corrección título
- `lib/core/constants/app_constants.dart` - Horarios hasta 19:30
- `lib/core/utils/booking_time_utils.dart` - Utilidades horarios
- `lib/presentation/widgets/date_navigation_header.dart` - Fix navegación
- `lib/core/services/firebase_user_service.dart` - Ajustes menores
- `lib/data/services/firestore_service.dart` - Ajustes menores
- `lib/presentation/widgets/booking/enhanced_court_tabs.dart` - Mejoras UI

#### 🎯 Resultado Final

Sistema de reservas funcionando correctamente con:
- ✅ Ventanas de tiempo dinámicas (48h Golf, 72h Pádel/Tenis)
- ✅ Visualización correcta de slots disponibles HOY
- ✅ Navegación fluida entre deportes
- ✅ Títulos correctos en headers
- ✅ Horarios extendidos hasta 19:30 para Pádel/Tenis

#### 🔄 Proceso de Rollback (si necesario)
```bash
git checkout v2.1.1
# O revertir este commit específico
git revert [hash del commit v2.1.2]
```

**Responsables:** Desarrollo: Claude + Felipe García B · Testing: validado en ambiente de desarrollo · Deploy: Firebase Hosting

---

### v2.1.3 — 2 de noviembre de 2025 — Bug de Eliminación Automática de Jugadores (Email Prefetching)

**Prioridad:** 🔴 CRÍTICA · **Tag Git:** `v2.1.3`

**Problema identificado:**

Cuando un organizador o admin agregaba un jugador a una reserva, el jugador aparecía correctamente agregado y recibía su email de confirmación. Sin embargo, aproximadamente 30 segundos después, el jugador era **eliminado automáticamente** sin intervención humana, y el resto de jugadores recibían un email notificando la cancelación.

**Síntomas específicos:**
- ✅ Jugador agregado correctamente
- ✅ Email de confirmación enviado
- ⏱️ 30-60 segundos de espera
- ❌ Jugador eliminado automáticamente
- 📧 Email de cancelación enviado a otros jugadores
- ⚠️ Comportamiento aleatorio (afectaba a algunos jugadores, no todos) — ~15-20% de reservas afectadas
- ✅ NO ocurría cuando el jugador se agregaba a sí mismo

**Causa raíz identificada:**

**Email Link Prefetching** por servidores de Gmail, Outlook y otros clientes de email.

Los servidores de email modernos (especialmente Gmail y Microsoft Outlook) implementan sistemas de seguridad que hacen **GET requests automáticos** a todos los links en los emails para:
1. Detectar malware y phishing
2. Verificar que los links sean seguros
3. Generar previews de las páginas
4. Escanear contenido peligroso

El sistema enviaba emails de confirmación con este botón:
```html
<a href="https://us-central1-cgpreservas.cloudfunctions.net/cancelBooking?id=XXX&email=YYY">
  ❌ Cancelar mi Participación
</a>
```

Cuando Gmail/Outlook "pre-cargaban" este link para verificar seguridad (sin que el usuario hiciera click):
1. Hacían un **GET request** automático al URL
2. Esto **disparaba la Cloud Function** `cancelBooking`
3. La función **cancelaba al jugador** automáticamente
4. Se **enviaban emails** de notificación a todos los jugadores restantes

**Evidencia que confirmó el diagnóstico:**

| Observación | Explicación |
|-------------|-------------|
| Solo ocurría cuando "otro" agregaba al jugador | Se enviaba email externo → Gmail procesaba el link |
| NO ocurría cuando el jugador se agregaba a sí mismo | No había email externo → No había prefetching |
| Comportamiento aleatorio | Dependía del servidor de email (Gmail más agresivo) |
| Timing consistente (~30 segundos) | Tiempo que tarda Gmail en procesar y verificar links |
| Se enviaban ambos emails | Confirmación primero, 30s después prefetching causaba cancelación |

**Solución implementada:**

Se implementó una **landing page intermedia de confirmación** que requiere un click manual del usuario. Los sistemas de prefetching solo hacen GET requests pasivos, **NO hacen clicks en botones JavaScript ni interactúan con elementos de la página**.

1. **Nueva Cloud Function: `cancelBookingConfirm`**
   - Archivo: `functions/index.js` (+250 líneas)
   - Función que muestra landing page de confirmación
   - Solo procesa cancelación si viene con parámetro `?confirm=true`
   - Reutiliza toda la lógica existente de `cancelBooking`

2. **Actualización de Templates de Email**
   - Modificados: `generateGolfEmailTemplate`, `generateTennisEmailTemplate`, `generatePadelEmailTemplate`
   - Cambio: Link de cancelación ahora apunta a `/cancelBookingConfirm` en lugar de `/cancelBooking`

3. **Landing Page de Confirmación** — `generateCancellationConfirmationPageNew()` (+150 líneas)
   - Diseño responsive con branding del club
   - Muestra detalles completos de la reserva
   - Advertencia clara sobre la acción
   - Botón "Sí, Cancelar mi Participación" (requiere click manual)
   - Confirmación adicional con JavaScript `confirm()`
   - Botón secundario "Volver al Sistema de Reservas"

4. **Página de Éxito Post-Cancelación** — `generateCancellationSuccessPageNew()` (+80 líneas)
   - Confirmación visual de cancelación exitosa
   - Notificación de que otros jugadores fueron informados
   - Link de retorno al sistema

5. **Actualización de Runtime**
   - `firebase.json`: Runtime actualizado de Node.js 18 a Node.js 20
   - Cumplimiento con decomisión de Node.js 18 (30 de octubre, 2025)

**Flujo corregido:**

**ANTES (con bug):**
```
1. Admin agrega a Jugador X
2. Sistema envía email a Jugador X
3. Email llega a Gmail
4. Gmail hace GET automático (prefetching)
5. ❌ GET dispara cancelBooking → Jugador X eliminado
6. Otros jugadores reciben email de cancelación
```

**DESPUÉS (solución):**
```
1. Admin agrega a Jugador X
2. Sistema envía email a Jugador X
3. Email llega a Gmail
4. Gmail hace GET automático (prefetching)
5. ✅ GET muestra landing page de confirmación (NO cancela)
6. Jugador X hace click en link del email
7. ✅ Ve página pidiendo confirmación
8. Jugador X hace click en "Sí, Cancelar"
9. Solo ENTONCES se ejecuta la cancelación
```

**Archivos modificados:**

- `functions/index.js`:
  - Nueva función `exports.cancelBookingConfirm`
  - Nueva función `generateCancellationConfirmationPageNew()`
  - Nueva función `generateCancellationSuccessPageNew()`
  - Actualización en `generateGolfEmailTemplate()` (cambio de URL)
  - Actualización en `generateTennisEmailTemplate()` (cambio de URL)
  - Actualización en `generatePadelEmailTemplate()` (cambio de URL)
- `firebase.json`: Runtime `"nodejs18"` → `"nodejs20"`

**Testing realizado:**

✅ **Test 1: No eliminación automática** — Reserva creada con jugador agregado por admin; jugador permanece después de 2 minutos — PASADO
✅ **Test 2: Landing page de confirmación** — Click en botón del email muestra página de confirmación (no cancela directamente) — PASADO
✅ **Test 3: Cancelación manual funciona** — Click en "Sí, Cancelar" → cancelación exitosa + notificaciones — PASADO
✅ **Test 4: Logs correctos** — Flujo de confirmación registrado correctamente en Firebase Functions logs — PASADO

**Logs de ejemplo (funcionalidad correcta):**
```
🔵 === CANCEL BOOKING CONFIRM ===
🔵 Booking ID: golf_tee_10-2025-11-03-1000
🔵 Player Email: jugador@example.com
🔵 Confirm: undefined
🔵 Mostrando página de confirmación
```
Después del click en "Sí, Cancelar":
```
🔵 Confirm: true
🔵 Procesando cancelación confirmada...
✅ Reserva encontrada por búsqueda alternativa
👤 Jugador que cancela: NOMBRE JUGADOR
📧 === ENVIANDO NOTIFICACIONES DE CANCELACIÓN ===
✅ Notificación enviada a: otrojugador@example.com
✅ Jugador removido. Quedan 2 jugadores
```

**Deployment:**
- Fecha: 2 de noviembre, 2025 - 20:30 hrs (Chile)
- Método: `firebase deploy --only functions`
- Región: us-central1
- Funciones desplegadas: `cancelBooking` (actualizada, mantenida para compatibilidad) · `cancelBookingConfirm` (nueva) ⭐

**Impacto en usuarios:**

| Antes (con bug) | Después (solucionado) |
|-----------------|----------------------|
| ~15-20% jugadores eliminados automáticamente | 0% eliminaciones automáticas |
| Usuarios confundidos (2 emails contradictorios) | Experiencia clara y profesional |
| Pérdida de confianza en el sistema | Sistema confiable |
| Soporte constante por el issue | Sin reportes del problema |

**Documentación adicional generada en su momento:** `RESUMEN_EJECUTIVO_BUG.md`, `SOLUCION_BUG_EMAIL_PREFETCH.js`, `GUIA_IMPLEMENTACION_PASO_A_PASO.md`, `CODIGO_A_AGREGAR.js`

**Prevención futura:**
- Evitar usar GET requests para acciones destructivas
- Siempre usar landing pages de confirmación para acciones críticas
- Considerar tokens de un solo uso para máxima seguridad
- Documentar comportamiento de email clients en el equipo

**Referencias técnicas:**
- [Google Safe Browsing & Link Prefetching](https://support.google.com/mail/answer/1384)
- [OWASP: Safe HTTP Methods](https://owasp.org/www-community/attacks/csrf)
- [Firebase Functions Best Practices](https://firebase.google.com/docs/functions/best-practices)

**Responsables:** Desarrollo: Claude + Felipe García B · Testing: validado en producción · Deploy: Firebase Functions Gen2 - Node.js 20

---

### 19 de noviembre de 2025 — Bug Error 404 en Cancelación de Reservas

**Prioridad:** 🔴 CRÍTICA - PRODUCCIÓN

**Problema identificado:**

Cuando un usuario hacía click en el botón "Cancelar mi Participación" desde el email de confirmación, aparecía un error 404 "Page not found" en lugar de mostrar la landing page de confirmación de cancelación introducida en v2.1.3.

**Síntomas específicos:**
- ✅ Email de confirmación enviado correctamente
- ✅ Botón "Cancelar mi Participación" presente en email
- ❌ Click en botón → Error 404 "Page not found"
- ❌ Imposibilidad de cancelar reservas desde el email
- ⚠️ 100% de usuarios afectados al intentar cancelar

**Causa raíz identificada:**

**Error de sintaxis JavaScript en `functions/index.js`**

La función `generateErrorHtml` (línea 2076) no tenía su llave de cierre `}` correctamente posicionada:

```javascript
// ANTES (INCORRECTO):
function generateErrorHtml(errorMessage) {
  return `
    <!DOCTYPE html>
    <!-- ... contenido HTML ... -->
  `;
  // ❌ FALTABA UN } AQUÍ

  // === PLANTILLAS PARA ACCIONES DE ADMIN ===
  function generateGolfPlayerAddedTemplate(...) { }
  function generateTennisPlayerAddedTemplate(...) { }
  // ... más funciones ...
  exports.cancelBookingConfirm = onRequest(...) { }

} // ← Este cierre estaba al final (línea 2703)
```

Esto causó que **600+ líneas de código** (incluyendo `exports.cancelBookingConfirm`) quedaran **dentro del scope** de `generateErrorHtml` en lugar de estar al nivel raíz del módulo.

**Consecuencias:**
1. `exports.cancelBookingConfirm` no se exportaba correctamente
2. Firebase Functions no podía encontrar la función
3. Resultado: Error 404 cuando se intentaba acceder a la URL de cancelación

**Solución implementada:**

Se corrigió el cierre de la función y la indentación del código:

```javascript
// DESPUÉS (CORRECTO):
function generateErrorHtml(errorMessage) {
  return `
    <!DOCTYPE html>
    <!-- ... contenido HTML ... -->
  `;
} // ✅ Cierre agregado aquí

// === PLANTILLAS PARA ACCIONES DE ADMIN ===
function generateGolfPlayerAddedTemplate(...) { }
function generateTennisPlayerAddedTemplate(...) { }
// ... más funciones ...
exports.cancelBookingConfirm = onRequest(...) { } // ✅ Ahora al nivel raíz
```

**Cambios técnicos realizados:**

1. **Corrección de sintaxis en `functions/index.js`:**
   - Línea 2100: Agregado cierre de función `}`
   - Líneas 2101-2702: Removida indentación incorrecta (2 espacios)
   - Línea 2703: Eliminada llave de cierre duplicada

2. **Validación de sintaxis:**
   - Ejecutado `node --check functions/index.js`
   - Confirmada estructura correcta de exports

3. **Verificación de exports:**
   ```bash
   grep -n "^exports\." index.js

   137:exports.dailyUserSync = onSchedule(
   389:exports.sendBookingEmailHTTP = onRequest(
   606:exports.cancelBooking = onRequest(
   837:exports.getUsers = onRequest(
   917:exports.verifyGoogleSheetsAPI = onRequest(
   2171:exports.cancelBookingConfirm = onRequest(  # ✅ Ahora sin indentación
   ```

**Testing realizado:**

✅ **Test 1: Validación de sintaxis** — `node --check functions/index.js` — sin errores
✅ **Test 2: Acceso directo a función** — `https://us-central1-cgpreservas.cloudfunctions.net/cancelBookingConfirm?id=test&email=test@test.com` → página HTML de confirmación — PASADO
✅ **Test 3: Flow completo desde email** — Crear reserva → Email enviado → Click en botón → landing page de confirmación (no error 404) — PASADO
✅ **Test 4: Cancelación completa** — Click en "Sí, Cancelar mi Participación" → cancelación exitosa + notificaciones enviadas — PASADO

**Deployment:**
- Fecha: 19 de noviembre, 2025
- Método: `firebase deploy --only functions`
- Región: us-central1
- Función actualizada: `cancelBookingConfirm`
- Estado: Operativa al 100%

**Impacto en usuarios:**

| Antes (con bug) | Después (corregido) |
|-----------------|----------------------|
| ❌ Error 404 al cancelar (100%) | ✅ Cancelación funcional (100%) |
| ❌ Usuarios no podían cancelar | ✅ Cancelación desde email operativa |
| ❌ Función no accesible | ✅ Función exportada correctamente |
| ❌ Experiencia de usuario rota | ✅ Experiencia profesional y fluida |

**Archivos modificados:**
- `functions/index.js`: línea 2100 (cierre agregado), líneas 2101-2702 (indentación corregida), línea 2703 (llave duplicada eliminada). Total: 602 líneas modificadas.

**Lecciones aprendidas:**
1. Importancia de validación de sintaxis: aunque el código compilaba, el scope incorrecto causaba que exports no funcionaran
2. Testing de endpoints: siempre verificar que las Cloud Functions sean accesibles después del deploy
3. Documentación detallada: mantener registro preciso de cambios para debugging futuro

**Monitoreo post-corrección:** logs de Firebase Functions sin errores 404 · 100% de cancelaciones exitosas · 0 reportes de usuarios sobre problemas de cancelación

---

### v2.1.4 — 21 de noviembre de 2025 — Validación 4 Horas al Unirse a Reserva + Fix Inicialización

**Fecha de Deploy:** 21 de noviembre, 2025 - 18:45 hrs (Chile)

#### 1️⃣ Corrección Principal: Validación de 4 Horas al Unirse a Reserva Existente

**Prioridad:** 🔴 CRÍTICA - BUG DE LÓGICA DE NEGOCIO

**Problema identificado:**

Los usuarios podían agregarse a reservas existentes mediante el modal "Unirse a Reserva" sin validar la regla de 4 horas entre reservas del mismo deporte. Esto permitía que un jugador pudiera estar en múltiples reservas simultáneas o con menos de 4 horas de diferencia.

**Síntomas específicos:**
- ✅ Validación funcionaba al CREAR nueva reserva
- ✅ Validación funcionaba al agregar acompañantes
- ❌ Validación NO funcionaba al unirse a reserva existente (modal)
- ❌ Usuario podía estar en 2 reservas con 12 minutos de diferencia
- ⚠️ 100% de usuarios afectados al usar función "Unirse a Reserva"

**Escenario de fallo:**
1. Juan crea reserva Golf 10:00 con Pedro como acompañante → ✅ Funciona
2. Manuel crea reserva Golf 10:12 → ✅ Funciona
3. Manuel intenta agregar a Pedro al crear → ❌ Sistema bloquea (correcto)
4. **Pedro abre reserva de Manuel y hace clic en "Unirse a Reserva"** → ✅ Sistema permite (INCORRECTO)
5. Resultado: Pedro en ambas reservas (10:00 y 10:12)

**Causa raíz identificada:**

**Falta de validación en `addPlayerToBooking()`**

La validación de conflictos de 4 horas solo se ejecutaba en:
- ✅ `createBooking()` - al crear nueva reserva
- ✅ `createBookingWithEmails()` - al crear con acompañantes

Pero NO se ejecutaba en:
- ❌ `addPlayerToBooking()` - cuando usuario se une a reserva existente

El método `addPlayerToBooking()` agregaba directamente a Firestore sin ninguna validación previa.

**Solución implementada:**

**1. Nuevo Método de Validación Centralizada**

Archivo: `lib/presentation/providers/booking_provider.dart`, después de `_hasConflictingReservation` (~línea 500)

```dart
Future<ValidationResult> validatePlayerForBooking({
  required String playerEmail,
  required String bookingDate,
  required String bookingTimeSlot,
  required String bookingCourtId,
}) async
```

Características:
- ✅ Valida conflictos de 4 horas con otras reservas del jugador
- ✅ Solo valida dentro del mismo deporte (Golf ≠ Pádel ≠ Tenis)
- ✅ Excluye usuarios genéricos "VISITA" (sin restricciones)
- ✅ Retorna `ValidationResult` con mensaje de error específico
- ✅ Manejo robusto de errores (niega operación si falla consulta)

**2. Actualización de `addPlayerToBooking()`**

Cambios realizados:
1. Agregado 4º parámetro: `String playerEmail`
2. Obtiene datos de la reserva objetivo (courtId, date, timeSlot)
3. Ejecuta `validatePlayerForBooking()` ANTES de agregar
4. Lanza excepción si hay conflicto
5. Solo agrega si pasa validación

Nueva firma:
```dart
Future<void> addPlayerToBooking(
  String bookingId,
  String playerId,
  String playerName,
  String playerEmail, // ← NUEVO PARÁMETRO
) async
```

**3. Actualización en UI - `golf_reservations_page.dart`**

Línea 1051 - try-catch completo:
```dart
try {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? userEmail;
  await provider.addPlayerToBooking(booking.id!, userId, userName, userEmail);

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Te has agregado exitosamente a la reserva'),
        backgroundColor: Colors.green,
      ),
    );
  }
} catch (e) {
  if (mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('No puedes agregarte'),
          ],
        ),
        content: Text(
          e.toString().replaceAll('Exception: ', ''),
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
```

Línea 875 - actualización de parámetros:
```dart
await provider.addPlayerToBooking(
  booking.id!,
  selectedPlayer.id,
  selectedPlayer.name,
  selectedPlayer.email ?? '' // ← AGREGADO
);
```

**Archivos modificados:**

| Archivo | Cambios Realizados | Líneas |
|---------|-------------------|---------|
| `booking_provider.dart` | Nuevo método `validatePlayerForBooking()` | ~500 |
| `booking_provider.dart` | Modificado `addPlayerToBooking()` con validación | ~548 |
| `golf_reservations_page.dart` | Agregado try-catch | 1047-1095 |
| `golf_reservations_page.dart` | Agregado email | 875 |

**Reglas de validación implementadas:**

**SÍ valida (usuarios normales):**
- ✅ Usuario se une a reserva existente mediante modal "Unirse a Reserva"
- ✅ Verifica ventana de 4 horas en el mismo deporte
- ✅ Muestra error claro y específico al usuario

**NO valida (casos especiales):**
- ⚪ Usuarios genéricos "VISITA" (pueden tener múltiples reservas)
- ⚪ Admin agregando jugadores vía `editBookingPlayers()` (flexibilidad admin)
- ⚪ Reservas en deportes diferentes (Golf vs Pádel vs Tenis)

**Usuarios VISITA sin restricciones:**
```
Golf:   GOLF VISITA 1, GOLF VISITA 2, GOLF VISITA 3, GOLF VISITA 4
Pádel:  PADEL1 VISITA, PADEL2 VISITA, PADEL3 VISITA, PADEL4 VISITA
Tenis:  TENIS VISITA 1, TENIS VISITA 2, TENIS VISITA 3, TENIS VISITA 4
```

**Testing realizado:**

✅ **Test 1: Conflicto mismo horario** — usuario con reserva 15:48 intenta unirse a otra 15:48 → bloqueado con mensaje "Ya tienes una reserva de GOLF a las 15:48"
✅ **Test 2: Conflicto < 4 horas** — reserva 15:48, intenta unirse a otra 16:00 (12 min diferencia) → bloqueado con mensaje específico
✅ **Test 3: Sin conflicto > 4 horas** — reserva 10:00, se une a otra 15:00 (5h diferencia) → permitido
✅ **Test 4: Usuario VISITA sin restricciones** — GOLF VISITA 1 en reserva 15:48, se agrega a otra 16:00 → permitido
✅ **Test 5: Deportes diferentes** — reserva Pádel 15:48, se une a reserva Golf 16:00 → permitido
✅ **Test 6: UI - Mensaje de error** — diálogo modal con mensaje claro y específico
✅ **Test 7: UI - Mensaje de éxito** — SnackBar verde con confirmación

**Métricas:**
- Cobertura de validación: 50% → 100% (+50%)
- Métodos validados: 2/4 → 3/4 (+1 método crítico)
- Casos de uso protegidos: 2 → 3

**Filosofía de diseño:**
- **Usuarios normales:** reglas estrictas de validación, prevención de conflictos accidentales, mensajes de error educativos
- **Administradores:** flexibilidad total sin validaciones, pueden resolver casos especiales manualmente, override disponible cuando sea necesario

**Lecciones aprendidas:**
1. Validación completa: asegurar que todas las vías de modificación de datos pasen por validaciones de negocio
2. Consistencia: mismas reglas deben aplicar independiente del punto de entrada (crear vs unirse)
3. UX de errores: fundamental mostrar mensajes claros cuando se bloquean operaciones
4. Testing exhaustivo: probar todos los flujos de usuario, no solo el "happy path"

#### 2️⃣ Corrección Adicional: Bug de Inicialización en Primera Carga

**Problema identificado:**

Al cargar la aplicación, las reservas del primer día disponible no se mostraban. Era necesario navegar a otro día y regresar para visualizarlas.

**Causa:**

Race condition: `_loadBookings()` se ejecutaba antes de que `_generateAvailableDates()` completara la configuración de `_selectedDate`.

**Solución:**
- Agregado `notifyListeners()` al final de `_generateAvailableDates()`
- Agregado delay de 50ms en `_initializeProvider()` antes de cargar bookings

**Archivos modificados:**
- `lib/presentation/providers/booking_provider.dart` (líneas ~517, ~680)

#### Testing completo de ambas correcciones

**Inicialización:**
- ✅ Reservas se muestran en primera carga
- ✅ Navegación entre días correcta
- ✅ Funcionamiento en desktop y móvil

**Impacto general de v2.1.4:**

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Cobertura validación | 50% | 100% | +50% |
| Bugs críticos | 2 | 0 | -100% |
| UX primera carga | Rota | Correcta | ✅ |
| Experiencia usuario | Inconsistente | Profesional | ✅ |

**Deployment:**
```bash
flutter clean
flutter pub get
flutter build web --release
firebase deploy --only hosting
```
URL Producción: https://cgpreservas.web.app

**Monitoreo post-deploy:**
- ✅ 0 errores de compilación
- ✅ 0 errores en consola del navegador
- ✅ 100% de validaciones funcionando
- ✅ Carga inicial correcta en todos los dispositivos
- ✅ Navegación fluida entre fechas

**Responsables:** Desarrolladores: Felipe García B + Claude · Tiempo total: ~3 horas · Líneas modificadas: ~200 · Archivos afectados: 2 · Severidad: 🔴 CRÍTICA

---

### v2.2.0 — 1-2 de enero de 2026 — Sistema de Bloqueos de Horarios y Extensión Golf

**Hora de Deploy a Producción:** 2 de enero, 2026 - 23:30 hrs (Chile)

#### 📋 Resumen Ejecutivo

Se implementó un sistema completo de bloqueos de horarios para actividades recurrentes (escuelitas, torneos) y se extendieron los horarios de golf hasta las 18:00. La solución utiliza "reservas administrativas" en lugar de una colección separada para mantener compatibilidad con el código Flutter existente.

**Impacto:**
- ✅ ~424 horarios bloqueados automáticamente
- ✅ Extensión de horarios golf (+2 horas)
- ✅ Sistema funcional sin modificar código Flutter
- ✅ Backup completo de 1,835 reservas antes de operación

#### 1️⃣ Sistema de Bloqueos de Horarios

**Problema identificado:**

Se necesitaba bloquear horarios específicos para actividades administrativas:
- **Escuelita Tenis:** Lunes, Miércoles, Viernes 09:00-12:00
- **Escuelita Pádel:** Martes, Jueves 09:00-12:00
- **Torneo Golf Menores:** 6 y 13 de Enero, 10:12-18:00

**Solución implementada — Estrategia: Reservas Administrativas**

En lugar de crear una colección `court_blocks` separada (que requeriría modificar Flutter), se optó por crear reservas "falsas" con jugadores administrativos que ocupan todos los slots disponibles.

Ventajas de esta solución:
- ✅ Funciona inmediatamente sin modificar código Flutter
- ✅ Sistema existente maneja bloqueos como reservas completas
- ✅ Usuarios ven slots ocupados naturalmente
- ✅ No requiere cambios en UI/UX
- ✅ Compatible con sistema de validaciones actual

Estructura de reserva administrativa:
```javascript
{
  courtId: "tennis_court_1",
  date: "2026-01-06",
  timeSlot: "09:00",
  status: "complete",
  players: [
    {
      name: "ESCUELITA TENIS",
      email: "reservaspapudo1@gmail.com",
      id: "timestamp_random",
      isConfirmed: true,
      phone: null
    },
    // ... 3 jugadores más para llenar el slot
  ],
  createdAt: serverTimestamp,
  updatedAt: serverTimestamp
}
```

**Scripts Node.js desarrollados**

Ubicación: `C:\Users\fgarc\flutter_projects\cgp-court-blocks\`

1. **`backup_bookings.js`** - Backup de Seguridad
   - Descarga todas las reservas de Firestore a JSON local
   - Incluye estadísticas por cancha y fecha
   - Convierte Timestamps a formato ISO
   - Ejecutar: `npm run backup`

   Resultado del backup realizado:
   - Total reservas respaldadas: 1,835
   - Tamaño archivo: 1.48 MB
   - Distribución: golf_tee_1: 1,142 · golf_tee_10: 476 · padel_court_1: 67 · tennis_court_1: 48 · padel_court_2: 39 · padel_court_3: 34 · Otros: 29

2. **`crear_bloqueo_reservas.js`** - Generador Base, configurable:
   ```javascript
   const BLOQUEO = {
     cancha: 'tennis_court_1',
     fechaInicio: '2026-01-01',
     fechaFin: '2026-02-28',
     diasSemana: [1, 3, 5], // Lun, Mié, Vie
     horarios: ['09:00', '10:30', '12:00'],
     textoBloqueo: 'ESCUELITA TENIS',
     cantidadJugadores: 4
   };
   ```

3. **`bloqueo_padel.js`** - Escuelita Pádel: cancha padel_court_3, Martes/Jueves, Enero-Febrero 2026, 09:00/10:30/12:00 — **~104 bloqueos**

4. **`bloqueo_golf.js`** - Torneo Menores: canchas golf_tee_1 + golf_tee_10, 6 y 13 de Enero 2026, 10:12-18:00 (41 slots cada 12 min), 4 jugadores por slot — **~164 bloqueos** (2 canchas × 2 días × 41 slots)

5. **`eliminar_bloqueos_golf.js`** - Limpieza Selectiva: elimina solo reservas de "TORNEO MENORES" por nombre de jugador, con confirmación antes de eliminar. Usado para corregir bloqueos con 2 jugadores → 4 jugadores.

**Configuración Firebase**

Índice compuesto creado:
- Colección: `bookings`
- Campos: `courtId` (Asc) + `date` (Asc) + `__name__` (Asc)
- Estado: Habilitado
- Propósito: Permitir búsquedas eficientes para eliminar conflictos

`package.json` - Scripts NPM:
```json
{
  "scripts": {
    "backup": "node backup_bookings.js",
    "restore": "node restore_bookings.js",
    "bloqueo-tenis": "node crear_bloqueo_reservas.js",
    "bloqueo-padel": "node bloqueo_padel.js",
    "bloqueo-golf": "node bloqueo_golf.js",
    "eliminar-golf": "node eliminar_bloqueos_golf.js"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
```

**Bloqueos implementados**

| Deporte | Cancha | Días | Período | Horarios | Jugadores | Total |
|---|---|---|---|---|---|---|
| Tenis | tennis_court_1 | Lun/Mié/Vie | Ene-Feb 2026 | 09:00, 10:30, 12:00 | ESCUELITA TENIS (4) | ~156 |
| Pádel | padel_court_3 | Mar/Jue | Ene-Feb 2026 | 09:00, 10:30, 12:00 | ESCUELITA PADEL (4) | ~104 |
| Golf | golf_tee_1 + golf_tee_10 | 6 y 13 Ene (2 fechas) | — | 10:12-18:00 (41 slots/día) | TORNEO MENORES (4) | ~164 |

**Total general:** ~424 bloqueos administrativos creados

**Emails administrativos utilizados:**
```
reservaspapudo1@gmail.com
reservaspapudo2@gmail.com
reservaspapudo3@gmail.com
reservaspapudo4@gmail.com
```
Estos emails son genéricos y permiten identificar fácilmente las reservas administrativas.

#### 2️⃣ Extensión de Horarios de Golf

**Archivo:** `lib/core/constants/app_constants.dart`

Antes:
```dart
'golf': {
  'startTime': '08:00',
  'winterEndTime': '16:00',
  'summerEndTime': '16:00',
  'intervalMinutes': 12,
  'customSlots': false,
},
```

Después:
```dart
'golf': {
  'startTime': '08:00',
  'winterEndTime': '18:00',  // ✅ CAMBIADO
  'summerEndTime': '18:00',  // ✅ CAMBIADO
  'intervalMinutes': 12,
  'customSlots': false,
},
```

Horarios nuevos agregados: `16:12, 16:24, 16:36, 16:48, 17:00, 17:12, 17:24, 17:36, 17:48, 18:00` — **10 slots adicionales por día**

Testing:
- ✅ Ambiente de desarrollo (`flutter run -d chrome`): slots 16:12-18:00 visibles, sistema de reservas funciona en nuevos horarios, validación de 4 horas correcta
- ✅ Deploy a producción: `flutter clean && flutter pub get && flutter build web --release && firebase deploy --only hosting`

#### 3️⃣ Proceso de Implementación Completo

**Fase 1: Preparación y Backup (30 min)**
1. Setup de scripts Node.js: `mkdir cgp-court-blocks && cd cgp-court-blocks && npm install firebase-admin@^12.0.0`
2. Descarga de `serviceAccountKey.json` (Firebase Console → Configuración → Cuentas de servicio)
3. Backup de seguridad: `npm run backup` → 1,835 reservas respaldadas en `backup-bookings-2026-01-01_23-04.json`

**Fase 2: Configuración Firebase (5 min)**
- Creación de índice compuesto (URL auto-generada por error de Firebase): `courtId + date + __name__`, ~2 minutos de construcción

**Fase 3: Ejecución de Bloqueos (15 min)**
1. Tenis (ejecutado primero - testing): `node crear_bloqueo_reservas.js` → 156 reservas creadas
2. Pádel: `node bloqueo_padel.js` → 104 reservas creadas
3. Golf (con corrección): primera ejecución con 2 jugadores (error) → `node eliminar_bloqueos_golf.js` → re-ejecución con 4 jugadores → 164 reservas creadas

**Fase 4: Cambio de Horarios Golf (10 min)**
1. Modificación de `app_constants.dart`: 16:00 → 18:00
2. Testing local: `flutter clean && flutter pub get && flutter run -d chrome` — verificado slots hasta 18:00
3. Deploy a producción: `flutter build web --release && firebase deploy --only hosting`

#### 4️⃣ Archivos Modificados y Creados

**Flutter modificados:**

| Archivo | Cambio | Líneas |
|---------|--------|--------|
| `lib/core/constants/app_constants.dart` | Horarios golf 16:00→18:00 | ~150 |

**Scripts Node.js creados:**

| Archivo | Propósito | Líneas |
|---------|-----------|--------|
| `backup_bookings.js` | Backup de reservas | ~150 |
| `restore_bookings.js` | Restaurar backup | ~120 |
| `crear_bloqueo_reservas.js` | Generador base configurable | ~180 |
| `bloqueo_padel.js` | Bloqueos pádel | ~150 |
| `bloqueo_golf.js` | Bloqueos golf | ~160 |
| `eliminar_bloqueos_golf.js` | Limpieza selectiva | ~130 |
| `package.json` | Configuración npm | ~25 |

Total archivos nuevos: 7 · Total líneas código: ~915

#### 5️⃣ Verificación Post-Implementación

**Firebase Console:**
- Total documentos en `bookings`: 1,835 + 424 = 2,259
- Reservas administrativas identificables por: nombres ("ESCUELITA TENIS", "ESCUELITA PADEL", "TORNEO MENORES"), emails `reservaspapudo1-4@gmail.com`, status "complete", 4 jugadores por slot

**Aplicación web:**
- ✅ Tenis (tennis_court_1): Lunes 6 y Miércoles 8 Enero, slots 09:00/10:30/12:00 ocupados, usuarios no pueden reservar
- ✅ Pádel (padel_court_3): Martes 7 y Jueves 9 Enero, slots 09:00/10:30/12:00 ocupados
- ✅ Golf (ambos hoyos): 6 y 13 Enero, 10:12-18:00 bloqueados en tee_1 y tee_10; nuevos slots 16:12-18:00 visibles y funcionales

#### 6️⃣ Comandos de Gestión de Bloqueos

Ver Apéndice B — "Sistema de Bloqueos Administrativos de Horarios" para la referencia completa de comandos, personalización y troubleshooting (reutilizados también en v2.2.1, v2.2.2 y v2.2.3).

#### 7️⃣ Consideraciones Futuras (evaluadas en esta sesión)

**Limitaciones identificadas en el enfoque de reservas administrativas:**
1. Gestión manual: bloqueos deben crearse/eliminarse vía scripts
2. Sin interfaz admin: no hay UI para gestionar bloqueos desde la app
3. Identificación visual: bloqueos se ven como reservas normales
4. Edición: requiere eliminar y recrear bloqueos

**Mejoras propuestas (no implementadas):**

*Opción A: Sistema `court_blocks` (profesional)* — crear colección separada en Firebase, modificar Flutter para leer ambas colecciones, UI diferenciada para bloqueos vs reservas. Ventaja: separación limpia de datos. Desventaja: requiere modificar código Flutter.

*Opción B: Panel de administración* — interfaz web para gestionar bloqueos, CRUD completo desde la app, calendario visual. Ventaja: fácil para administradores. Desventaja: desarrollo adicional requerido.

#### 8️⃣ Métricas de Implementación

| Métrica | Valor |
|---------|-------|
| Tiempo total implementación | ~4 horas |
| Reservas respaldadas | 1,835 |
| Bloqueos creados | 424 |
| Archivos nuevos | 7 scripts |
| Líneas código nuevas | ~915 |
| Archivos Flutter modificados | 1 |
| Downtime | 0 minutos |
| Errores en producción | 0 |
| Testing previo | ✅ Completo |

#### 🎯 Estado Final

**Sistema:** ✅ OPERATIVO AL 100% · **Backup:** ✅ Completado (1,835 reservas) · **Bloqueos:** ✅ Activos (424 horarios) · **Horarios Golf:** ✅ Extendidos hasta 18:00 · **Producción:** ✅ Deploy exitoso · **Verificación:** ✅ Todos los tests pasados

URL Producción: https://cgpreservas.web.app

**Responsables:** Felipe García B + Claude · Tiempo total: ~4 horas · Complejidad: Media · Severidad: 🟡 MEJORA OPERATIVA

---

### v2.2.1 — 2 de enero de 2026 — Bloqueo Adicional Pádel LILEN (Febrero 2026)

**Hora de Ejecución:** 2 de enero, 2026 - 20:43 hrs (Chile)

#### 📋 Resumen

Se agregó un bloqueo adicional de Escuelita Pádel en la cancha LILEN (padel_court_2) para el mes de Febrero 2026, complementando el bloqueo existente en PALO (padel_court_3, parte de v2.2.0).

**Cambios:**
- ✅ 24 horarios adicionales bloqueados en LILEN
- ✅ Período: Solo Febrero 2026
- ✅ Mismo horario y días que PALO (Mar/Jue 09:00-12:00)

#### 🏓 Bloqueo Implementado: Pádel LILEN

**Configuración:**
```
Cancha:     padel_court_2 (LILEN)
Días:       Martes, Jueves
Período:    Febrero 2026 (completo)
Horarios:   09:00, 10:30, 12:00
Jugadores:  ESCUELITA PADEL (4 jugadores)
Total:      24 bloqueos
```

**Fechas específicas — Febrero 2026:**
- Martes: 3, 10, 17, 24 (4 días)
- Jueves: 5, 12, 19, 26 (4 días)
- Total: 8 días × 3 horarios = 24 bloqueos

**Script utilizado:** `bloqueo_padel_lilen.js`
```javascript
const BLOQUEO = {
  cancha: 'padel_court_2',
  fechaInicio: '2026-02-01',
  fechaFin: '2026-02-28',
  diasSemana: [2, 4], // Martes, Jueves
  horarios: ['09:00', '10:30', '12:00'],
  textoBloqueo: 'ESCUELITA PADEL',
  cantidadJugadores: 4
};
```

**Ejecución:**
```powershell
cd C:\Users\fgarc\flutter_projects\cgp-court-blocks
node bloqueo_padel_lilen.js
```
Resultado: ✅ 24 bloqueos creados exitosamente · ✅ Sin errores · ✅ Tiempo de ejecución: ~5 segundos

#### 📊 Actualización de Totales de Bloqueos (Tenis + Pádel + Golf, consolidado a esta fecha)

| Deporte | Cancha | Período | Días | Horarios | Total |
|---------|--------|---------|------|----------|-------|
| **Tenis** | tennis_court_1 | Ene-Feb | Lun/Mié/Vie | 09:00-12:00 | ~78 |
| **Pádel** | padel_court_3 (PALO) | Ene-Feb | Mar/Jue | 09:00-12:00 | ~51 |
| **Pádel** | padel_court_2 (LILEN) | Feb | Mar/Jue | 09:00-12:00 | **24** ✅ |
| **Golf** | tee_1 + tee_10 | 6 y 13 Ene | 2 fechas | 10:12-18:00 | ~164 |
| **TOTAL** | | | | | **~317** |

**Desglose Pádel (ambas canchas):**
```
Pádel PALO (court_3):
- Enero 2026: ~27 bloqueos (9 días × 3 horarios)
- Febrero 2026: ~24 bloqueos (8 días × 3 horarios)
- Subtotal: ~51 bloqueos

Pádel LILEN (court_2):
- Febrero 2026: 24 bloqueos (8 días × 3 horarios)
- Subtotal: 24 bloqueos

Total Pádel: ~75 bloqueos
```

**Verificación en Firebase Console:**
```
Colección: bookings
Filtro: courtId == "padel_court_2"
Fecha: 2026-02-03 a 2026-02-26
Jugadores: "ESCUELITA PADEL"
```
Resultado esperado: 24 documentos

**Script de verificación:** `contar_bloqueos_padel.js`
```powershell
node contar_bloqueos_padel.js
```
Output esperado:
```
🏓 padel_court_2 (LILEN): 24 bloqueos
   Febrero 2026: 24 bloqueos

🏓 padel_court_3 (PALO): ~51 bloqueos
   Enero 2026: ~27 bloqueos
   Febrero 2026: ~24 bloqueos

📊 TOTAL GENERAL: ~75 bloqueos de ESCUELITA PADEL
```

**Archivos nuevos:**

| Archivo | Propósito | Líneas |
|---------|-----------|--------|
| `bloqueo_padel_lilen.js` | Bloqueo Pádel LILEN Febrero | ~150 |
| `contar_bloqueos_padel.js` | Verificación de bloqueos | ~80 |

Total archivos scripts (acumulado): 9 (7 de v2.2.0 + 2 nuevos)

#### ⏱️ Métricas

| Métrica | Valor |
|---------|-------|
| Tiempo de implementación | ~10 minutos |
| Bloqueos creados | 24 |
| Errores encontrados | 0 |
| Testing | ✅ Completo |
| Deploy requerido | ❌ No (solo Firebase) |

#### 🎯 Estado Final

**Sistema:** ✅ OPERATIVO AL 100% · **Bloqueos Pádel:** ✅ 75 total (~51 PALO + 24 LILEN) · **Verificación:** ✅ Exitosa en Firebase Console · **Producción:** ✅ Sin cambios de código necesarios

**Responsables:** Felipe García B + Claude · Tiempo total: ~10 minutos · Complejidad: Baja (script reutilizado)

---

### v2.2.2 — 3-10 de abril de 2026 — Bloqueo Mantención Hoyo 1

**Fecha de Ejecución:** 3 de abril, 2026 · **Documentado:** 10 de abril, 2026

#### 📋 Resumen

Se ejecutó exitosamente el script de bloqueo para mantención de antegreens en el Hoyo 1 (golf_tee_1) durante el período 6-16 de Abril 2026.

**Impacto:**
- ✅ 451 horarios bloqueados exitosamente
- ✅ Hoyo 1 completamente reservado con "Mantencion Antegreens"
- ✅ Período: 11 días completos (6-16 Abril 2026)
- ✅ Hoyo 10 desbloqueado temporalmente como alternativa (ver v2.2.3)

#### 🏌️ Bloqueo Implementado

**Script ejecutado:** `bloqueo_golf_hoyo1_reparacion.js`

```
Cancha:     golf_tee_1 (Hoyo 1 ÚNICAMENTE)
Período:    6 al 16 de Abril 2026 (11 días)
Horario:    08:00 a 16:00 (invierno - 41 slots por día)
Texto:      "Mantencion Antegreens"
Total:      451 bloqueos
```

Fechas específicas: Domingo 6, Lunes 7, Martes 8, Miércoles 9, Jueves 10, Viernes 11, Sábado 12, Domingo 13, Lunes 14, Martes 15, Miércoles 16 de Abril 2026.

**Configuración del script** — `C:\Users\fgarc\flutter_projects\cgp-court-blocks\bloqueo_golf_hoyo1_reparacion.js`:
```javascript
const horariosCompletos = [
  '08:00', '08:12', '08:24', '08:36', '08:48',
  '09:00', '09:12', '09:24', '09:36', '09:48',
  '10:00', '10:12', '10:24', '10:36', '10:48',
  '11:00', '11:12', '11:24', '11:36', '11:48',
  '12:00', '12:12', '12:24', '12:36', '12:48',
  '13:00', '13:12', '13:24', '13:36', '13:48',
  '14:00', '14:12', '14:24', '14:36', '14:48',
  '15:00', '15:12', '15:24', '15:36', '15:48',
  '16:00'
];

const fechas = [
  '2026-04-06', '2026-04-07', '2026-04-08', '2026-04-09',
  '2026-04-10', '2026-04-11', '2026-04-12', '2026-04-13',
  '2026-04-14', '2026-04-15', '2026-04-16'
];

const BLOQUEO = {
  cancha: 'golf_tee_1', // SOLO Hoyo 1
  fechas: fechas,
  horarios: horariosCompletos,
  textoBloqueo: 'Mantencion Antegreens',
  cantidadJugadores: 4
};
```

**Ejecución:**
```powershell
cd C:\Users\fgarc\flutter_projects\cgp-court-blocks
node bloqueo_golf_hoyo1_reparacion.js
```

Resultado:
```
⛳ BLOQUEO GOLF HOYO 1 - MANTENCION ANTEGREENS
======================================================================
CONFIGURACIÓN:
  Cancha: golf_tee_1 (Hoyo 1 ÚNICAMENTE)
  Período: 2026-04-06 a 2026-04-16
  Total de días: 11 días
  Horario: 08:00 a 16:00 (INVIERNO)
  Slots por día: 41
  Texto: "Mantencion Antegreens"

📊 RESUMEN:
  Días a bloquear: 11
  Horarios por día: 41
  Total de reservas a crear: 451

🔄 Creando bloqueos...
[... 11 días procesados, 41 slots bloqueados cada uno ...]
======================================================================
✅ ¡BLOQUEO HOYO 1 COMPLETADO!
======================================================================
Total de reservas creadas: 451
```

**Estructura de reservas creadas:**
```javascript
{
  courtId: "golf_tee_1",
  date: "2026-04-06",
  timeSlot: "08:00",
  status: "complete",
  players: [
    {
      name: "Mantencion Antegreens",
      email: "reservaspapudo1@gmail.com",
      id: "timestamp_random",
      isConfirmed: true,
      phone: null
    },
    // ... 3 jugadores más
  ],
  createdAt: serverTimestamp,
  updatedAt: serverTimestamp
}
```

**Verificación en Producción:** https://cgpreservas.web.app
- ✅ Hoyo 1 muestra todos los horarios bloqueados con "Mantencion Antegreens"
- ✅ 451 reservas visibles en Firebase Console
- ✅ Distribución: 11 días × 41 slots = 451 bloqueos
- ✅ Hoyo 10 operando normalmente (con bloqueo temporal desactivado, ver v2.2.3)

Consulta Firebase: colección `bookings`, filtros `courtId == "golf_tee_1"`, `date >= "2026-04-06"`, `date <= "2026-04-16"`, `players[0].name == "Mantencion Antegreens"` → Resultado: 451 documentos

---

### v2.2.3 — 10 de abril de 2026 — Desbloqueo Temporal Hoyo 10

**Fecha de Implementación:** 10 de abril, 2026

#### 📋 Resumen

Durante la mantención del Hoyo 1 (6-16 Abril 2026, v2.2.2), se desactivó temporalmente el bloqueo sistémico del Hoyo 10 para permitir que los golfistas puedan usar todos los horarios disponibles de este hoyo como alternativa.

**Contexto:**
- El Hoyo 10 tiene un bloqueo sistémico permanente de horarios 10:12-12:48
- Al bloquearse el Hoyo 1 completamente (mantención), se necesitaba habilitar el Hoyo 10 al 100%
- El bloqueo está implementado en 2 lugares diferentes del código Flutter

**Cambios realizados:**
- ✅ Desactivado bloqueo temporal en Hoyo 10
- ✅ Horarios 10:12-12:48 ahora disponibles para reservar
- ✅ Cambios documentados con comentarios para reversión

#### 🏌️ Bloqueo Sistémico del Hoyo 10 (contexto — preexistente)

El Hoyo 10 (golf_tee_10) tiene un bloqueo permanente de horarios específicos:

Horarios bloqueados normalmente: `10:12, 10:24, 10:36, 10:48, 11:00, 11:12, 11:24, 11:36, 11:48, 12:00, 12:12, 12:24, 12:36, 12:48` — Total: 14 slots bloqueados por día

Razón del bloqueo: operativa del club, no especificada en documentación original.

**Implementación del bloqueo (2 lugares):**

*Lugar 1:* `lib/presentation/providers/booking_provider.dart` (líneas 404-416) — filtrado de slots durante generación de vista de reservas
```dart
// Horarios bloqueados para golf_tee_10 (10:12 a 12:48)
final blockedSlotsForTee10 = [
  '10:12', '10:24', '10:36', '10:48',
  '11:00', '11:12', '11:24', '11:36', '11:48',
  '12:00', '12:12', '12:24', '12:36', '12:48',
];

for (final timeSlot in visibleTimeSlots) {
  for (final court in courts) {
    // Saltar horarios bloqueados para golf_tee_10
    if (court == 'golf_tee_10' && blockedSlotsForTee10.contains(timeSlot)) {
      continue;
    }
```

*Lugar 2:* `lib/presentation/pages/golf_reservations_page.dart` (líneas 311-316) — filtrado de slots disponibles específicamente para Hoyo 10
```dart
// Filtrar horarios suspendidos para Hoyo 10
List<String> availableSlots = timeSlots;
if (isHoyo10) {
  availableSlots = timeSlots.where((slot) => !GolfConstants.isHoyo10Suspended(slot)).toList();
  // availableSlots = timeSlots; // Sin filtro por ahora
}
```

Función auxiliar en `app_constants.dart` (líneas 236-245):
```dart
static bool isHoyo10Suspended(String timeSlot) {
  const suspensionStart = '10:12';
  const suspensionEnd = '12:48';
  final time = DateTime.parse('2024-01-01 $timeSlot:00');
  final suspensionStartTime = DateTime.parse('2024-01-01 $suspensionStart:00');
  final suspensionEndTime = DateTime.parse('2024-01-01 $suspensionEnd:00');
  return time.isAtSameMomentAs(suspensionStartTime) ||
         time.isAtSameMomentAs(suspensionEndTime) ||
         (time.isAfter(suspensionStartTime) && time.isBefore(suspensionEndTime));
}
```

#### ✅ Cambios Realizados para Desbloqueo Temporal

**Cambio 1 — `booking_provider.dart` (líneas 413-416):**

ANTES:
```dart
    // Saltar horarios bloqueados para golf_tee_10
    if (court == 'golf_tee_10' && blockedSlotsForTee10.contains(timeSlot)) {
      continue;
    }
```

DESPUÉS:
```dart
    // TEMPORALMENTE DESHABILITADO - Mantención Hoyo 1 (desde 6 Abril 2026)
    // Saltar horarios bloqueados para golf_tee_10
    // if (court == 'golf_tee_10' && blockedSlotsForTee10.contains(timeSlot)) {
    //   continue;
    // }
```

**Cambio 2 — `golf_reservations_page.dart` (líneas 311-316):**

ANTES:
```dart
    // Filtrar horarios suspendidos para Hoyo 10
    List<String> availableSlots = timeSlots;
    if (isHoyo10) {
      availableSlots = timeSlots.where((slot) => !GolfConstants.isHoyo10Suspended(slot)).toList();
      // availableSlots = timeSlots; // Sin filtro por ahora
    }
```

DESPUÉS:
```dart
    // TEMPORALMENTE DESHABILITADO - Mantención Hoyo 1 (6-16 Abril 2026)
    // Filtrar horarios suspendidos para Hoyo 10
    List<String> availableSlots = timeSlots;
    if (isHoyo10) {
      // availableSlots = timeSlots.where((slot) => !GolfConstants.isHoyo10Suspended(slot)).toList();
      availableSlots = timeSlots; // Sin filtro - TODOS los slots disponibles
    }
```

#### 🔄 Deploy Realizado

```powershell
cd C:\Users\fgarc\flutter_projects\cgp_reservas

# Modificar archivos
code lib/presentation/providers/booking_provider.dart
code lib/presentation/pages/golf_reservations_page.dart

# Rebuild
flutter clean
flutter build web --release

# Re-autenticación Firebase (si necesario)
firebase login --reauth

# Deploy
firebase deploy --only hosting
```
Resultado: `✔ Deploy complete!` — Hosting URL: https://cgpreservas.web.app

Verificación: Horarios 10:12-12:48 ahora aparecen disponibles en Hoyo 10 ✅

#### 🔙 Procedimiento de Vuelta Atrás (histórico — reemplazado por la lógica automática de v2.2.4)

> Este procedimiento manual de reversión quedó obsoleto el 14 de abril de 2026, cuando v2.2.4 reemplazó estos comentarios manuales por lógica condicional basada en fechas. Se conserva aquí como registro histórico de cómo se operó esta mantención puntual.

Cuándo ejecutar: después de que termine la mantención del Hoyo 1 (posterior al 16 de abril de 2026).

**Paso 1:** Reactivar bloqueo en `booking_provider.dart` (líneas 413-416) — descomentar el código.
**Paso 2:** Reactivar filtro en `golf_reservations_page.dart` (líneas 311-316) — revertir cambios.
**Paso 3:** Guardar archivos (Ctrl+S en ambos).
**Paso 4:** Rebuild y deploy:
```powershell
cd C:\Users\fgarc\flutter_projects\cgp_reservas
flutter clean
flutter build web --release
firebase deploy --only hosting
```
**Paso 5:** Verificar en producción — ir a https://cgpreservas.web.app, navegar a Golf → Hoyo 10, confirmar que NO aparezcan los horarios 10:12-12:48.

#### 📊 Resumen de Archivos Afectados

| Archivo | Líneas Modificadas | Tipo de Cambio |
|---|---|---|
| `booking_provider.dart` | 413-416 | Comentar/Descomentar bloqueo |
| `golf_reservations_page.dart` | 311-316 | Comentar/Descomentar filtro |

Total archivos: 2 · Complejidad: Baja (solo comentarios) · Impacto: Temporal durante mantención Hoyo 1

#### ⚠️ Notas Importantes (vigentes en el momento, resueltas por v2.2.4)

- **Bloqueo dual:** el bloqueo está implementado en 2 lugares diferentes. Ambos debían modificarse para que el desbloqueo funcionara.
- **Caché del navegador:** después del deploy, podía ser necesario limpiar caché (`Ctrl+Shift+R` o borrado manual).
- **Reversión crítica:** no olvidar reactivar el bloqueo después de la mantención del Hoyo 1 — riesgo que motivó la automatización de v2.2.4.

#### 📝 Lecciones Aprendidas

1. **Bloqueos múltiples:** el bloqueo del Hoyo 10 estaba implementado en 2 lugares diferentes (provider + página), lo que requirió modificar ambos para que funcione.
2. **Debugging sistemático:** uso de scripts PowerShell para buscar todas las referencias a `golf_tee_10`, `10:12`, y `blockedSlots` fue crucial para encontrar todos los puntos de bloqueo.
3. **Documentación crítica:** este bloqueo sistémico NO estaba documentado previamente, lo que causó confusión durante el debugging.
4. **Testing en producción:** después del primer deploy, el bloqueo seguía activo debido al segundo filtro en `golf_reservations_page.dart`. Siempre verificar en producción.

#### 🎯 Estado Final

**Sistema:** ✅ OPERATIVO AL 100% · **Hoyo 10:** ✅ Completamente disponible (temporal) · **Horarios desbloqueados:** ✅ 10:12-12:48 disponibles · **Producción:** ✅ Deploy exitoso · **Reversión:** reemplazada por lógica automática en v2.2.4 (no se requirió ejecutar manualmente)

**Responsables:** Felipe García B + Claude · Tiempo total: ~45 minutos (incluye debugging) · Complejidad: Media (bloqueo en múltiples lugares)

---

### v2.2.4 — 14 de abril de 2026 — Lógica Automática de Desbloqueo + Planificación Hoyo 10

**Hora de Deploy a Producción:** 14 de abril, 2026 - 20:30 hrs (Chile)

#### 📋 Resumen

Se implementó lógica automática basada en fechas para el desbloqueo temporal del Hoyo 10, eliminando la necesidad de intervención manual introducida en v2.2.3. Adicionalmente, se preparó script para nueva mantención del Hoyo 10 programada para 20 abril - 1 mayo 2026.

**Cambios realizados:**
- ✅ Lógica automática de fechas para desbloqueo Hoyo 10
- ✅ Eliminación de intervención manual requerida
- ✅ Script preparado para bloqueo Hoyo 10 (492 bloqueos)
- ✅ Sincronización perfecta entre mantenciones

#### 🔄 Mejora: Lógica Automática de Fechas

**Problema identificado:**

La v2.2.3 implementó desbloqueo temporal del Hoyo 10 mediante **comentarios manuales** en el código, lo que requería:
- ⚠️ Recordar descomentar el código después del 16 de abril
- ⚠️ Rebuild y deploy manual el viernes 17
- ⚠️ Riesgo de olvido → Hoyo 10 permanentemente desbloqueado

**Contexto crítico:**

El sistema permite ver reservas 2 días adelante. El miércoles 15, los usuarios verían el viernes 17 y necesitaban ver:
- ✅ Hoyo 1: Disponible (mantención terminada)
- ✅ Hoyo 10: Slots 10:12-12:48 bloqueados nuevamente

#### ✅ Solución Implementada

Reemplazo de comentarios manuales por **lógica condicional basada en fechas** que activa/desactiva el bloqueo automáticamente.

**Implementación en `booking_provider.dart` (líneas 403-425):**
```dart
    // Horarios bloqueados para golf_tee_10 (10:12 a 12:48)
    final blockedSlotsForTee10 = [
      '10:12', '10:24', '10:36', '10:48',
      '11:00', '11:12', '11:24', '11:36', '11:48',
      '12:00', '12:12', '12:24', '12:36', '12:48',
    ];

    // Verificar si Hoyo 1 está en mantención (desbloquear Hoyo 10 solo durante este período)
    final now = DateTime.now();
    final inicioMantencionHoyo1 = DateTime(2026, 4, 6);
    final finMantencionHoyo1 = DateTime(2026, 4, 17); // 17 de abril (no incluido)
    final hoyo1EnMantencion = now.isAfter(inicioMantencionHoyo1) &&
                              now.isBefore(finMantencionHoyo1);

    for (final timeSlot in visibleTimeSlots) {
      for (final court in courts) {

        // Saltar horarios bloqueados para golf_tee_10 SOLO si Hoyo 1 NO está en mantención
        if (court == 'golf_tee_10' &&
            !hoyo1EnMantencion &&
            blockedSlotsForTee10.contains(timeSlot)) {
          continue;
        }
```

Lógica:
- **6-16 Abril:** `hoyo1EnMantencion = true` → Bloqueo NO se aplica (Hoyo 10 disponible)
- **17 Abril en adelante:** `hoyo1EnMantencion = false` → Bloqueo SÍ se aplica (Hoyo 10 bloqueado 10:12-12:48)

**Implementación en `golf_reservations_page.dart` (líneas 305-320):**
```dart
  Widget _buildHoyoTimeSlots(BuildContext context, BookingProvider provider, String hoyoId,
                          List<String> timeSlots, bool isHoyo10) {
    final now = DateTime.now();
    final selectedDate = provider.selectedDate;
    final isToday = selectedDate.year == now.year &&
                    selectedDate.month == now.month &&
                    selectedDate.day == now.day;

    // Verificar si Hoyo 1 está en mantención
    final inicioMantencionHoyo1 = DateTime(2026, 4, 6);
    final finMantencionHoyo1 = DateTime(2026, 4, 17);
    final hoyo1EnMantencion = now.isAfter(inicioMantencionHoyo1) &&
                              now.isBefore(finMantencionHoyo1);

    // Filtrar horarios suspendidos para Hoyo 10 (excepto durante mantención Hoyo 1)
    List<String> availableSlots = timeSlots;
    if (isHoyo10 && !hoyo1EnMantencion) {
      availableSlots = timeSlots.where((slot) => !GolfConstants.isHoyo10Suspended(slot)).toList();
    }
```

#### 🔄 Deploy Realizado

```powershell
cd C:\Users\fgarc\flutter_projects\cgp_reservas

# Editar archivos
code lib/presentation/providers/booking_provider.dart
code lib/presentation/pages/golf_reservations_page.dart

# Build y deploy
flutter clean
flutter build web --release
firebase deploy --only hosting
```

Resultado:
```
√ Built build\web
i  hosting[cgpreservas]: found 48 files in build/web
+  Deploy complete!
Hosting URL: https://cgpreservas.web.app
```

#### 📊 Timeline Automático

```
Martes 14 Abril (20:30 hrs):
  ✅ Deploy con lógica automática

Miércoles 15 Abril (00:00 hrs en adelante):
  ✅ Usuarios pueden ver viernes 17
  ✅ Hoyo 1: Sin bloqueos (automático - Firebase expira el 16)
  ✅ Hoyo 10: Slots 10:12-12:48 bloqueados (automático - lógica de fechas)

Viernes 17 Abril:
  ✅ Hoyo 1: Completamente disponible
  ✅ Hoyo 10: Bloqueo sistémico reactivado automáticamente
  ✅ Sin intervención manual requerida
```

#### 🏌️ Planificación: Nuevo Bloqueo Hoyo 10

**Contexto:** se planificó nueva mantención de antegreens en Hoyo 10 para el período 20 abril - 1 mayo 2026.

```
Cancha:     golf_tee_10 (Hoyo 10)
Período:    20 Abril - 1 Mayo 2026 (12 días)
Horarios:   08:00 - 16:00 (41 slots completos, invierno)
Texto:      "Mantencion Antegreens"
Total:      492 bloqueos
```

Fechas específicas: Domingo 20, Lunes 21, Martes 22, Miércoles 23, Jueves 24, Viernes 25, Sábado 26, Domingo 27, Lunes 28, Martes 29, Miércoles 30 de Abril, Jueves 1 de Mayo.

**Script preparado:** `bloqueo_golf_hoyo10_reparacion_CORREGIDO.js` en `C:\Users\fgarc\flutter_projects\cgp-court-blocks\`:
```javascript
const horariosCompletos = [
  '08:00', '08:12', '08:24', '08:36', '08:48',
  '09:00', '09:12', '09:24', '09:36', '09:48',
  '10:00', '10:12', '10:24', '10:36', '10:48',
  '11:00', '11:12', '11:24', '11:36', '11:48',
  '12:00', '12:12', '12:24', '12:36', '12:48',
  '13:00', '13:12', '13:24', '13:36', '13:48',
  '14:00', '14:12', '14:24', '14:36', '14:48',
  '15:00', '15:12', '15:24', '15:36', '15:48',
  '16:00'
]; // 41 slots completos

const fechas = [
  '2026-04-20', '2026-04-21', '2026-04-22', '2026-04-23',
  '2026-04-24', '2026-04-25', '2026-04-26', '2026-04-27',
  '2026-04-28', '2026-04-29', '2026-04-30', '2026-05-01'
]; // 12 días

const BLOQUEO = {
  cancha: 'golf_tee_10',
  fechas: fechas,
  horarios: horariosCompletos,
  textoBloqueo: 'Mantencion Antegreens',
  cantidadJugadores: 4
};
```
Total estimado: 12 días × 41 slots = 492 bloqueos

**Nota sobre bloqueo dual:** los slots 10:12-12:48 estarían **doblemente bloqueados** durante esta mantención: (1) el bloqueo sistémico en código (permanente, activo excepto durante mantención Hoyo 1) y (2) el bloqueo administrativo en Firebase (temporal 20 abril - 1 mayo, reservas "Mantencion Antegreens", eliminadas al finalizar). Esto es intencional: al terminar la mantención se eliminan las reservas de Firebase y el bloqueo sistémico continúa funcionando normalmente.

**Estado de la ejecución (al 14.04.2026):** script preparado, **NO ejecutado aún**. Fecha prevista de ejecución: 19 de abril, 2026 (día previo al bloqueo).
```powershell
cd C:\Users\fgarc\flutter_projects\cgp-court-blocks
node bloqueo_golf_hoyo10_reparacion_CORREGIDO.js
```

> **Seguimiento pendiente:** este documento no registra si `bloqueo_golf_hoyo10_reparacion_CORREGIDO.js` llegó a ejecutarse el 19 de abril de 2026. Confirmar estado real en Firebase Console (`bookings`, `courtId == "golf_tee_10"`, rango 2026-04-20 a 2026-05-01) antes de asumir que la mantención quedó bloqueada.

#### 📁 Archivos Modificados y Creados

**Flutter modificados:**

| Archivo | Cambio | Líneas |
|---------|--------|--------|
| `booking_provider.dart` | Lógica automática fechas | 403-425 |
| `golf_reservations_page.dart` | Lógica automática fechas | 305-320 |

**Scripts creados:**

| Archivo | Propósito | Estado |
|---------|-----------|--------|
| `bloqueo_golf_hoyo10_reparacion_CORREGIDO.js` | Bloqueo Hoyo 10 (20 abr - 1 may) | ✅ Preparado, ejecución pendiente de confirmar |

#### ⏱️ Métricas de Implementación

| Métrica | Valor |
|---------|-------|
| Tiempo de desarrollo | ~2 horas |
| Archivos modificados | 2 |
| Complejidad | Media (lógica condicional) |
| Testing | ✅ Build exitoso |
| Deploy | ✅ Exitoso (48 archivos) |
| Intervención manual requerida | ❌ Ninguna |

#### 🎯 Ventajas de la Lógica Automática

1. ✅ Cero intervención manual: sistema se ajusta automáticamente según fechas
2. ✅ Sin riesgo de olvido: no requiere recordar descomentar código
3. ✅ Código limpio: lógica clara y auto-documentada
4. ✅ Escalable: fácil ajustar fechas para futuras mantenciones
5. ✅ Testing sencillo: comportamiento predecible basado en fecha del sistema

#### 📝 Lecciones Aprendidas

1. **Lógica condicional > Comentarios manuales:** la lógica basada en fechas elimina errores humanos y simplifica mantenimiento.
2. **Testing de build crítico:** error de variable duplicada (`now`) detectado en build. Siempre verificar compilación completa antes de deploy.
3. **Visibilidad anticipada:** sistema permite ver 2 días adelante, lo que requiere que cambios automáticos estén deployados con anticipación.
4. **Sincronización de mantenciones:** mantención Hoyo 1 (6-16 abril) y Hoyo 10 (20 abril - 1 mayo) perfectamente coordinadas.

#### 🎯 Estado Final

**Sistema:** ✅ OPERATIVO AL 100% · **Lógica automática:** ✅ Implementada y funcionando · **Hoyo 10 (14 abril):** ✅ Desbloqueado (mantención Hoyo 1 activa) · **Hoyo 10 (17 abril):** ✅ Se bloqueó automáticamente (sin intervención) · **Script Hoyo 10:** ✅ Preparado, ejecución el 19 abril sin confirmar en este documento · **Producción:** ✅ Deploy exitoso

**Responsables:** Felipe García B + Claude · Tiempo total: ~2 horas · Complejidad: Media (lógica condicional + debugging)

---

### 11 de agosto de 2026 — Migración de Facturación y Acceso (consolidación bajo puntocom.cl)

**Prioridad:** 🟡 ADMINISTRATIVA (sin cambios de código ni deploy)

#### 📋 Contexto

A raíz de un incidente de facturación en el proyecto `notas-venta-prod` (bloqueo temporal por disputa de cobro en la cuenta de facturación "Felipe Garcia"), se aprovechó para hacer una limpieza general de cuentas de facturación y proyectos de Google Cloud, incluyendo `cgpreservas`.

`cgpreservas` estaba facturado con la cuenta personal "Felipe Garcia" (`018F4B-DA7C20-3CE2AB`, sin organización asociada) y el proyecto en sí pertenecía a la cuenta Google `paddlepapudo@gmail.com`, sin acceso directo desde `fgarcia@puntocom.cl`.

#### ✅ Cambios Realizados

**1. Facturación migrada:**
- De: cuenta "Felipe Garcia" (`018F4B-DA7C20-3CE2AB`)
- A: cuenta "Pago de Firebase" (`0167FB-C927E6-F676C0`), bajo la organización `puntocom.cl`
- Comando ejecutado (autenticado como `fgarcia@puntocom.cl`, tras recibir permiso):
```powershell
gcloud billing projects link cgpreservas --billing-account=0167FB-C927E6-F676C0
```

**2. Acceso otorgado a `fgarcia@puntocom.cl`** (ejecutado desde `paddlepapudo@gmail.com`, dueño original del proyecto):
```powershell
gcloud projects add-iam-policy-binding cgpreservas --member="user:fgarcia@puntocom.cl" --role="roles/billing.projectManager"
gcloud projects add-iam-policy-binding cgpreservas --member="user:fgarcia@puntocom.cl" --role="roles/editor"
gcloud projects add-iam-policy-binding cgpreservas --member="user:fgarcia@puntocom.cl" --role="roles/firebase.admin"
```

Resultado: `fgarcia@puntocom.cl` puede ahora hacer `firebase login`, deploys, y administrar Firestore/Hosting/Functions del proyecto sin depender de `paddlepapudo@gmail.com`. Sigue siendo necesario `paddlepapudo@gmail.com` (rol Owner) para gestionar permisos de terceros o eliminar el proyecto — ese rol no se transfirió (requiere flujo de invitación por correo, no ejecutado en esta sesión).

**3. Proyecto huérfano eliminado:**
- `peppy-caster-461702-p2` ("My First Project", creado 02.06.2025, propiedad de `paddlepapudo@gmail.com`) — proyecto por defecto sin uso, vinculado también a la cuenta "Felipe Garcia". Eliminado con `gcloud projects delete`.

**4. Cuenta de facturación "Felipe Garcia" cerrada:**
- Verificado 0 proyectos vinculados (`gcloud billing projects list --billing-account=018F4B-DA7C20-3CE2AB`) antes de cerrar desde la consola web.

#### 🎯 Estado Final

- ✅ `cgpreservas` facturado desde "Pago de Firebase" (puntocom.cl)
- ✅ `fgarcia@puntocom.cl` con acceso operativo completo (editor + firebase.admin + billing.projectManager)
- ✅ Cuenta de facturación "Felipe Garcia" cerrada, sin proyectos dependientes
- ⚠️ **Pendiente:** el proyecto sigue bajo la cuenta Google `paddlepapudo@gmail.com` como Owner (no se migró la organización en Cloud Resource Manager, solo facturación y acceso operativo)

**Responsables:** Ejecución: Felipe García B + Claude · Contexto: limpieza derivada del incidente de facturación en `notas-venta-prod` (proyecto Teja Azul)

---

### v2.2.5 — 12 de septiembre de 2026 — Extensión Horario Pádel/Tenis (efectivo desde el 14.09.2026)

**Prioridad:** 🟢 MEJORA OPERATIVA, solicitada por el club

#### 📋 Contexto

El club pidió extender el último horario reservable de Pádel y Tenis de **16:30 a 18:00**, a partir del **lunes 14 de septiembre de 2026**. Antes de implementar, se auditó el código porque existen varios archivos con horarios de Pádel/Tenis hardcodeados — la mayoría resultaron ser código muerto, no alcanzable desde la navegación real de la app.

**Archivo que realmente controla el horario (confirmado siguiendo el flujo de navegación real: `AuthWrapper` → `SimpleSportHub` → `Navigator.pushNamed('/tennis-reservations' | '/paddle-reservations')` → `TennisReservationsPage`/`PaddleReservationsPage` → `BookingProvider.getAvailableTimeSlotsForDate()` → `AppConstants.getTimeSlotsForSport()`):**
- `lib/core/constants/app_constants.dart` — listas `winterTimeSlots`/`summerTimeSlots` (último horario real antes de este cambio: **16:30**, no 16:00).

**Archivos con horarios de Pádel/Tenis hardcodeados que se auditaron y resultaron ser código muerto (no reciben tráfico desde la navegación real de la app, por lo que NO se modificaron):**
- `lib/core/constants/tennis_constants.dart` (`END_TIME_WINTER = "16:00"`) — solo se usa para nombres de cancha (`COURT_NAMES`), no para horarios.
- `lib/presentation/providers/user_provider.dart` (`allowedTimeSlots`, mock) — solo lo consume `home_page.dart`, que depende de `app_router.dart` (go_router), un router distinto al que realmente registra `main.dart` (`MaterialApp` con `home: AuthWrapper()`). `HomePage` no es alcanzable desde el login real.
- `lib/presentation/screens/reservation_screen.dart` (texto "Invierno: hasta 16:00") — solo la referencia `landing_page.dart`, que a su vez no tiene ninguna referencia desde el resto de la app.
- `lib/presentation/providers/booking_provider.dart`: `_hasAvailableSlotsToday()` (lista hardcodeada con último slot `16:30`) y `getFilteredTimeSlots()` (que delega en `BookingTimeUtils.getAvailableTimeSlots()`) — ambos métodos están definidos pero ningún otro archivo los invoca.

#### ✅ Solución Implementada

Se agregó un corte por fecha directamente en `AppConstants.getTimeSlotsForSport()`, siguiendo el mismo patrón ya usado en v2.2.4 para el desbloqueo automático del Hoyo 10 (lógica condicional por fecha en vez de un flag manual a recordar).

**Archivo modificado:** `lib/core/constants/app_constants.dart`

```dart
// Fecha desde la cual se extiende el último horario de Pádel/Tenis de 16:30 a 18:00.
static final DateTime _extensionHorarioPadelTenis = DateTime(2026, 9, 14);

static List<String> getTimeSlotsForSport(String sport, [DateTime? date]) {
  final isSummer = _isSummerSeason(date);

  switch (sport.toLowerCase()) {
    case 'padel':
    case 'tennis':
      final baseSlots = isSummer ? summerTimeSlots : winterTimeSlots;
      final referenceDate = date ?? DateTime.now();
      // A partir del 14.09.2026 se agrega el slot 18:00.
      if (!referenceDate.isBefore(_extensionHorarioPadelTenis)) {
        return [...baseSlots, '18:00'];
      }
      return baseSlots;
    case 'golf':
      return _generateGolfTimeSlots(isSummer);
    default:
      return winterTimeSlots;
  }
}
```

Las listas base `winterTimeSlots`/`summerTimeSlots` (que terminaban en 16:30) no se modificaron — el slot 18:00 se agrega solo condicionalmente según la fecha del día que se está consultando, no de "hoy". Esto es deliberado: como la ventana de reservas de Pádel/Tenis es deslizante (72 horas), al momento de este deploy (12.09.2026) ya se podían ver días dentro del rango 13-15 de septiembre — el corte por fecha asegura que el 12 y 13 de septiembre sigan mostrando hasta las 16:30, y que el 14 de septiembre en adelante (incluyendo días futuros ya visibles por la ventana de 72h) muestren hasta las 18:00, sin depender de cuándo se hizo el deploy. No requiere reversión manual a futuro — es un cambio permanente, a diferencia de las mantenciones temporales de v2.2.2-v2.2.4.

También se agregaron comentarios en `sportScheduleConfig['padel']`/`['tennis']` aclarando que esos campos (`winterEndTime`/`summerEndTime`) son decorativos para estos dos deportes — nunca se leen en código, porque `customSlots: true` hace que el horario real salga de las listas `winterTimeSlots`/`summerTimeSlots` + el corte de fecha, no de un generador por intervalo (ese generador solo se usa para Golf).

**Golf no se tocó** — `sportScheduleConfig['golf']` y `_generateGolfTimeSlots()` quedaron exactamente iguales.

#### 🧪 Verificación

- `flutter analyze --no-pub lib/core/constants/app_constants.dart` → 0 issues nuevos (2 infos preexistentes de `prefer_const_constructors`, sin relación con este cambio).
- No fue posible correr `flutter test` para una verificación en runtime: el proyecto tiene un desajuste de SDK preexistente (el Flutter instalado en la máquina usa la feature experimental `dot-shorthands` del lenguaje Dart, que el código de `package:flutter` ya usa internamente pero que no está habilitada para el proyecto) — error no relacionado con este cambio, pendiente de resolver aparte si se quiere volver a tener `flutter test` funcional.
- Se revisó manualmente la lógica con casos borde (11, 12, 13, 14, 15 de septiembre de 2026, y enero de 2027 en temporada de verano): el corte de fecha compara por día calendario, así que el 14.09.2026 exactamente ya incluye el slot 18:00, y los días previos lo excluyen correctamente.

#### ⚠️ Nota sobre el estado del repositorio al momento de este cambio

Al revisar `git status` antes de este ajuste, ya existían cambios sin commitear en `lib/presentation/pages/golf_reservations_page.dart` y `lib/presentation/providers/booking_provider.dart` (y en `.firebase/hosting.*.cache`) que **no fueron generados por este cambio** — estaban presentes en el árbol de trabajo desde antes. No se tocaron ni se incluyen en este registro; quedan pendientes de que Felipe los revise y decida si commitearlos por separado.

#### 🎯 Estado Final

**Código:** ✅ Modificado y verificado con `flutter analyze` · **Deploy:** ⏳ Pendiente (no se hizo build ni `firebase deploy` como parte de este cambio — falta decidir si se prueba primero en DEV) · **Efectivo desde:** 14 de septiembre de 2026 (una vez deployado)

**Responsables:** Felipe García B + Claude

---

## Apéndices

### A. Flujo de Desarrollo Seguro

#### Entornos Separados

El sistema opera con 2 ambientes independientes:

**DESARROLLO (DEV):** https://cgpreservas--dev-uw52qzyg.web.app
- Para probar cambios antes de producción
- Completamente independiente de usuarios reales
- Expira cada 30 días (renovable)
- Ideal para validar nuevas funcionalidades

**PRODUCCIÓN (PROD):** https://cgpreservas.web.app
- Para usuarios finales del club
- Solo se actualiza cuando cambios están validados en DEV

#### Procedimiento para Cambios en la App

1. **Hacer cambios en el código** — editar archivos `.dart` en VSCode
2. **Probar localmente (opcional pero recomendado):**
   ```powershell
   flutter run -d chrome --web-port=8080
   ```
3. **Build de producción:**
   ```powershell
   flutter build web --release
   ```
4. **Deploy a DEV primero:**
   ```powershell
   firebase hosting:channel:deploy dev
   ```
5. **Probar en DEV exhaustivamente** — URL: https://cgpreservas--dev-uw52qzyg.web.app. Validar funcionalidad, verificar sin errores en consola.
6. **Si todo OK → Deploy a PROD:**
   ```powershell
   firebase deploy --only hosting
   ```

#### Procedimiento para Cambios en Cloud Functions

1. Editar `functions/index.js`
2. Testing local (recomendado): `firebase emulators:start --only functions`
3. Deploy a producción: `firebase deploy --only functions`
4. Monitorear logs: `firebase functions:log --only nombreFuncion`

#### Consideraciones Importantes

- ✅ Siempre probar en DEV antes de PROD
- ✅ Verificar logs de Firebase después de deploy
- ✅ Mantener backup del código antes de cambios mayores
- ✅ Documentar todos los cambios en este archivo
- ✅ Usar Node.js 20 para Cloud Functions (Node.js 18 decomisionado desde el 30 de octubre de 2025)

---

### B. Sistema de Bloqueos Administrativos de Horarios — Referencia de Scripts

Esta referencia cubre el patrón de "reservas administrativas" introducido en v2.2.0 y reutilizado en v2.2.1, v2.2.2 y v2.2.3/v2.2.4. Ubicación de todos los scripts: `C:\Users\fgarc\flutter_projects\cgp-court-blocks\`.

#### Backup y Restauración
```bash
npm run backup    # Crear backup
npm run restore   # Restaurar desde backup
```

#### Crear Bloqueos
```bash
# Tenis (editar parámetros en crear_bloqueo_reservas.js)
node crear_bloqueo_reservas.js

# Pádel
npm run bloqueo-padel

# Golf
npm run bloqueo-golf
```

#### Eliminar Bloqueos
```bash
# Eliminar bloqueos de golf (selectivo)
npm run eliminar-golf

# Para otros deportes, modificar el script
```

#### Personalización de Bloqueos

Para crear nuevos bloqueos, editar `crear_bloqueo_reservas.js`:
```javascript
const BLOQUEO = {
  cancha: 'ID_CANCHA',           // ej: 'padel_court_2'
  fechaInicio: 'YYYY-MM-DD',     // ej: '2026-03-01'
  fechaFin: 'YYYY-MM-DD',        // ej: '2026-03-31'
  diasSemana: [0,1,2,3,4,5,6],   // 0=Dom, 6=Sáb
  horarios: ['HH:mm', ...],      // ej: ['15:00', '16:30']
  textoBloqueo: 'TEXTO',         // ej: 'TORNEO MENSUAL'
  cantidadJugadores: 4           // Siempre 4 para bloqueo completo
};
```

#### Troubleshooting

**Error: "Cannot find module firebase-admin"**
```bash
cd cgp-court-blocks
npm install
```

**Error: "The query requires an index"**
- Copiar URL del error
- Abrir en navegador
- Click en "Crear índice"
- Esperar 1-2 minutos

**Bloqueos no aparecen en la app:**
- Verificar en Firebase Console que existan
- Revisar que `courtId` sea correcto
- Verificar formato de fecha (YYYY-MM-DD)
- Confirmar que status sea "complete"

**Eliminar bloqueo específico:**
- Firebase Console → Firestore → `bookings`
- Buscar por jugador (ej. "ESCUELITA TENIS")
- Eliminar manualmente

---

### C. Roadmap Futuro

> Lista heredada del documento original. No se ha confirmado en ninguna entrada posterior del Registro de Cambios si los items sin marcar siguen vigentes — revisar con el club antes de planificar sobre esta base.

**Q4 2025**

Prioridad Alta:
- [x] ~~Validación completa móvil de auto-login~~ ✅ Completado
- [x] ~~Deploy de reportes a producción~~ ✅ Completado
- [x] ~~Corrección bug email prefetching~~ ✅ Completado (v2.1.3, 2 nov 2025)
- [ ] Implementar Gestión de Usuarios admin
- [ ] Implementar Gestión de Canchas admin

Prioridad Media:
- [ ] Sistema de notificaciones push
- [ ] Integración con calendarios nativos
- [ ] Reportes con gráficos visuales
- [ ] Filtros avanzados en reportes

Prioridad Baja:
- [ ] Modo offline mejorado
- [ ] Service Worker optimizado
- [ ] Caché inteligente de datos
- [ ] Animaciones de transición

**Q1 2026**

Funcionalidades Avanzadas:
- [ ] Dashboard con métricas en tiempo real
- [ ] Sistema de puntos/gamificación
- [ ] Reservas recurrentes
- [ ] Lista de espera automática
- [ ] Integración con sistema de pagos

Optimizaciones:
- [ ] Performance móvil mejorado
- [ ] Reducción de bundle size
- [ ] Lazy loading de módulos
- [ ] Optimización de imágenes

---

### D. Referencia Técnica: Caracteres Especiales

Caracteres corruptos identificados (mojibake por codificación incorrecta, útil para diagnosticar problemas similares a futuro):

- `🔥` → `Ã°Å¸"Â¥` (fuego)
- `🚀` → `Ã°Å¸Å¡â‚¬` (cohete)
- `📁` → `Ã°Å¸"` (carpeta)
- `⚠️` → `Ã¢Å¡ Ã¯Â¸` (advertencia)
- `❌` → `Ã¢Å'` (X roja)
- `📅` → `Ã°Å¸"` (calendario)
- `📄` → `Ã°Å¸"â€ž` (documento)
- `🎨` → `Ã°Å¸Å½Â¨` (paleta de pintor)
- `🔑` → `Ã°Å¸"'` (llave)
- `📊` → `Ã°Å¸"Å ` (gráfico de barras)
- `📱` → `Ã°Å¸"Â±` (teléfono móvil)
- `🔧` → `Ã°Å¸"Â§` (llave inglesa)
- `🔔` → `Ã°Å¸""` (campana)
- `⛳` → `Ã°Å¸Å'Ã¯Â¸` (bandera de golf)

---

### E. Créditos y Contacto

**Proyecto:** Sistema de Reservas Multi-Deporte
**Cliente:** Club de Golf Papudo
**Stack Principal:** Flutter Web + Firebase
**Documentación mantenida por:** Felipe García B, con asistencia de Claude

---

### F. Nota sobre la reorganización de este documento (12.09.2026)

El documento original (previo a esta limpieza) tenía los siguientes problemas, corregidos en esta reorganización:

1. **Orden cronológico roto:** las entradas saltaban de enero 2026 a noviembre 2025, a octubre 2025, a agosto 2026, sin un criterio consistente. Ahora el "Registro de Cambios" va estrictamente del más antiguo (v1.0, sep. 2025) al más reciente (migración de facturación, ago. 2026).
2. **Fechas de "última actualización" contradictorias:** el encabezado decía 11 de agosto de 2026, el pie decía 14 de abril de 2026, y la sección de créditos decía 2 de noviembre de 2025. Ahora solo hay una fecha de "última actualización", en el encabezado, y corresponde a la entrada más reciente del registro.
3. **Numeración de versión duplicada/inconsistente:** "Versión Documento: 2.2.2" se usó tanto para el bloqueo de mantención del Hoyo 1 como (por error) para el desbloqueo temporal del Hoyo 10. Se renombró esta segunda entrada a **v2.2.3**, dejando v2.2.4 (lógica automática) como ya estaba.
4. **Contenido duplicado:** el bug de validación de 4 horas (nov. 2025) y el bug de email prefetching (nov. 2025) estaban documentados dos veces cada uno, con distinto nivel de detalle y en secciones separadas del documento. Se consolidó cada uno en una sola entrada, usando la versión más completa y agregando cualquier detalle único de la versión corta (ej. conteo de líneas agregadas por función).
5. **Instrucciones de prompt filtradas al documento:** había un bloque literal "## INSTRUCCIONES: 1. Cambiar línea 5... 2. Agregar esta sección..." (presumiblemente un prompt usado para generar una actualización anterior) que quedó pegado en el cuerpo del documento. Se eliminó.
6. **Material de referencia mezclado con el changelog:** secciones de uso permanente (flujo de desarrollo, comandos de gestión de bloqueos, troubleshooting, roadmap, stack tecnológico, caracteres especiales) estaban intercaladas entre entradas de cambios fechados. Se movieron a la sección "Apéndices" al final, separadas del registro cronológico.

**Punto abierto que esta limpieza NO pudo resolver por falta de información en el documento original:** no quedó registro de si el script `bloqueo_golf_hoyo10_reparacion_CORREGIDO.js` (planificado para el 19 de abril de 2026, ver v2.2.4) se ejecutó efectivamente. Verificar en Firebase Console antes de asumir su estado.
