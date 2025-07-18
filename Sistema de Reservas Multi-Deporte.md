# 📚 Documentación Completa del Sistema de Reservas Multi-Deporte
## Clean Architecture - 47 Archivos Dart

---

## 🏗️ **Arquitectura del Proyecto**

El sistema sigue **Clean Architecture** con las siguientes capas:

```
lib/
├── 📱 presentation/     # UI Layer - Widgets, Pages, Providers
├── 🏢 domain/          # Business Logic - Entities, Repositories (interfaces)
├── 💾 data/            # Data Layer - Models, Repository Implementations, Services
├── ⚙️ core/            # Cross-cutting - Services, Constants, DI, Theme
└── 🛠️ utils/           # Utilities - Helper functions
```

---

## 📱 **PRESENTATION LAYER (18 archivos)**

### **Pages (3 archivos)**

#### `lib/presentation/pages/home/home_page.dart`
**Propósito:** Página principal de la aplicación que actúa como punto de entrada después de la autenticación. Contiene la navegación principal y puede mostrar dashboard o información general del club.

**Motivo de Existencia:** Centraliza la navegación principal del sistema y proporciona una landing page consistente para todos los usuarios autenticados.

**Funciones Principales:**
- `HomePage` - Widget principal de la página de inicio
- `_buildWelcomeSection()` - Construye sección de bienvenida personalizada
- `_buildNavigationOptions()` - Crea opciones de navegación a diferentes módulos
- `_buildQuickStats()` - Muestra estadísticas rápidas del usuario
- `_handleNavigation()` - Maneja navegación a diferentes secciones
- `_loadUserData()` - Carga datos específicos del usuario actual

#### `lib/presentation/pages/reservations_page.dart`
**Propósito:** Página principal del sistema de reservas que muestra el calendario de disponibilidad, permite navegación entre fechas/canchas, y gestiona la creación de nuevas reservas.

**Motivo de Existencia:** Interface central donde los usuarios interactúan con el sistema de reservas. Integra todos los widgets de reservas en una experiencia cohesiva.

**Funciones Principales:**
- `ReservationsPage` - Widget principal de la página de reservas
- `_buildDateSelector()` - Construye selector de fechas con navegación
- `_buildCourtTabs()` - Crea tabs de canchas con colores diferenciados
- `_buildTimeSlotGrid()` - Genera grilla de horarios disponibles
- `_handleSlotSelection()` - Maneja selección de slots por usuario
- `_openBookingModal()` - Abre modal para crear nueva reserva
- `_refreshBookings()` - Refresca datos de reservas desde backend
- `_getSlotBackgroundColor()` - Determina colores según estado del slot

### **Providers (3 archivos)**

#### `lib/presentation/providers/app_provider.dart`
**Propósito:** Provider global de la aplicación que maneja el estado de configuración general, tema, y funcionalidades transversales que afectan toda la app.

**Motivo de Existencia:** Centraliza el estado global de la aplicación y proporciona configuraciones compartidas entre todas las pantallas.

**Funciones Principales:**
- `AppProvider` - Clase principal del provider usando ChangeNotifier
- `initializeApp()` - Inicializa configuraciones globales de la app
- `updateTheme()` - Cambia entre temas claro/oscuro
- `setLanguage()` - Configura idioma de la aplicación
- `updateUserPreferences()` - Actualiza preferencias del usuario
- `showGlobalLoading()` - Muestra indicador de carga global
- `hideGlobalLoading()` - Oculta indicador de carga global
- `handleGlobalError()` - Maneja errores globales de la aplicación

#### `lib/presentation/providers/booking_provider.dart`
**Propósito:** Provider especializado en gestionar todo el estado relacionado con reservas. Maneja operaciones CRUD, validaciones, y comunicación con los servicios de backend.

**Motivo de Existencia:** Abstrae la lógica de negocio de reservas de la UI, proporciona estado reactivo, y maneja validaciones complejas de reservas.

**Funciones Principales:**
- `BookingProvider` - Provider principal para gestión de reservas
- `createBooking()` - Crea nueva reserva con validaciones
- `createBookingWithEmails()` - Crea reserva y envía notificaciones automáticas
- `updateBooking()` - Actualiza reserva existente
- `cancelBooking()` - Cancela reserva y notifica a participantes
- `getBookingsForDate()` - Obtiene reservas para fecha específica
- `getBookingsForCourt()` - Obtiene reservas por cancha
- `validateBookingConflicts()` - Valida conflictos de horarios/usuarios
- `canCreateBooking()` - Verifica si se puede crear reserva
- `refreshBookings()` - Refresca datos de reservas desde servidor

#### `lib/presentation/providers/user_provider.dart`
**Propósito:** Provider dedicado a la gestión de usuarios, autenticación, perfiles, y búsqueda de usuarios para reservas.

**Motivo de Existencia:** Maneja toda la lógica relacionada con usuarios de manera centralizada, incluyendo autenticación y búsqueda para reservas.

**Funciones Principales:**
- `UserProvider` - Provider principal para gestión de usuarios
- `authenticateUser()` - Autentica usuario en el sistema
- `searchUsers()` - Busca usuarios para agregar a reservas
- `getCurrentUser()` - Obtiene datos del usuario actual
- `updateUserProfile()` - Actualiza perfil de usuario
- `loadAllUsers()` - Carga todos los usuarios del sistema
- `getUserBookings()` - Obtiene reservas de un usuario específico
- `validateUserPermissions()` - Valida permisos de usuario
- `logoutUser()` - Cierra sesión de usuario

### **Router (1 archivo)**

#### `lib/presentation/router/app_router.dart`
**Propósito:** Configuración centralizada de rutas y navegación de la aplicación. Define todas las rutas disponibles, guardias de navegación, y transiciones entre pantallas.

**Motivo de Existencia:** Proporciona navegación consistente, maneja autenticación de rutas, y centraliza la lógica de routing para facilitar mantenimiento.

**Funciones Principales:**
- `AppRouter` - Clase principal de configuración de rutas
- `generateRoute()` - Genera rutas dinámicamente según parámetros
- `navigateToHome()` - Navega a página principal
- `navigateToReservations()` - Navega a página de reservas
- `navigateToProfile()` - Navega a perfil de usuario
- `canNavigate()` - Verifica permisos para navegar a ruta
- `handleDeepLinks()` - Maneja enlaces profundos de la aplicación
- `getInitialRoute()` - Determina ruta inicial según estado de autenticación

### **Widgets (11 archivos)**

#### **Widgets Comunes (3 archivos)**

##### `lib/presentation/widgets/common/app_loading_indicator.dart`
**Propósito:** Widget reutilizable para mostrar indicadores de carga consistentes en toda la aplicación.

**Motivo de Existencia:** Estandariza la presentación de estados de carga y proporciona UX consistente durante operaciones asíncronas.

**Funciones Principales:**
- `AppLoadingIndicator` - Widget principal de carga
- `buildCircularIndicator()` - Crea indicador circular personalizado
- `buildLinearIndicator()` - Crea indicador linear para progreso
- `buildCustomSpinner()` - Crea spinner personalizado con branding
- `showWithMessage()` - Muestra indicador con mensaje personalizado

##### `lib/presentation/widgets/common/compact_header.dart`
**Propósito:** Header compacto y responsive que se adapta a diferentes tamaños de pantalla, especialmente optimizado para dispositivos móviles.

**Motivo de Existencia:** Maximiza espacio vertical en dispositivos móviles mientras mantiene funcionalidad de navegación y branding.

**Funciones Principales:**
- `CompactHeader` - Widget principal del header compacto
- `buildLogo()` - Construye logo del club optimizado para espacio reducido
- `buildNavigationIcons()` - Crea iconos de navegación minimalistas
- `buildUserAvatar()` - Muestra avatar de usuario en formato compacto
- `adaptToScreenSize()` - Adapta contenido según tamaño de pantalla

##### `lib/presentation/widgets/common/date_navigation_header.dart`
**Propósito:** Header especializado para navegación de fechas con controles intuitivos para cambiar días, semanas o meses.

**Motivo de Existencia:** Proporciona navegación temporal consistente y intuitiva para el sistema de reservas.

**Funciones Principales:**
- `DateNavigationHeader` - Widget principal de navegación de fechas
- `buildDateSelector()` - Construye selector de fecha interactivo
- `buildPreviousButton()` - Botón para navegar a fecha anterior
- `buildNextButton()` - Botón para navegar a fecha siguiente
- `buildTodayButton()` - Botón rápido para ir a fecha actual
- `formatDateDisplay()` - Formatea fecha para mostrar de manera amigable
- `handleDateChange()` - Maneja cambios de fecha y notifica a parent

#### **Widgets de Booking (8 archivos)**

##### `lib/presentation/widgets/booking/animated_compact_stats.dart`
**Propósito:** Widget que muestra estadísticas de reservas con animaciones compactas, ideal para dashboards móviles.

**Motivo de Existencia:** Proporciona feedback visual animado de estadísticas de uso en formato optimizado para espacios reducidos.

**Funciones Principales:**
- `AnimatedCompactStats` - Widget principal con estadísticas animadas
- `buildStatsCard()` - Crea tarjetas de estadísticas individuales
- `animateCounters()` - Anima contadores de números
- `buildProgressBars()` - Crea barras de progreso animadas
- `updateStats()` - Actualiza estadísticas con animaciones

##### `lib/presentation/widgets/booking/compact_court_tabs.dart`
**Propósito:** Tabs compactos para selección de canchas optimizados para pantallas pequeñas con indicadores visuales de disponibilidad.

**Motivo de Existencia:** Permite selección rápida de canchas en dispositivos móviles sin sacrificar información visual importante.

**Funciones Principales:**
- `CompactCourtTabs` - Widget principal de tabs compactos
- `buildTabButton()` - Construye botón individual de cancha
- `buildAvailabilityIndicator()` - Indica disponibilidad de cancha
- `handleCourtSelection()` - Maneja selección de cancha
- `updateCourtStatus()` - Actualiza estado visual de canchas

##### `lib/presentation/widgets/booking/compact_stats.dart`
**Propósito:** Versión compacta de estadísticas de reservas sin animaciones, ideal para mostrar información rápida.

**Motivo de Existencia:** Proporciona información estadística esencial en formato ultra-compacto para dispositivos con limitaciones de espacio.

**Funciones Principales:**
- `CompactStats` - Widget principal de estadísticas compactas
- `buildStatItem()` - Construye elemento individual de estadística
- `buildStatsRow()` - Crea fila de estadísticas múltiples
- `formatStatValue()` - Formatea valores estadísticos para display

##### `lib/presentation/widgets/booking/court_tab_button.dart`
**Propósito:** Botón individualizado para selección de canchas con estado visual, colores diferenciados, y indicadores de disponibilidad.

**Motivo de Existencia:** Proporciona interface consistente para selección de canchas con feedback visual claro del estado de cada cancha.

**Funciones Principales:**
- `CourtTabButton` - Widget principal del botón de cancha
- `buildButtonContent()` - Construye contenido interno del botón
- `buildAvailabilityBadge()` - Crea badge de disponibilidad
- `buildCourtName()` - Muestra nombre de cancha formateado
- `handleTap()` - Maneja selección de cancha
- `updateButtonState()` - Actualiza estado visual del botón

##### `lib/presentation/widgets/booking/date_selector.dart`
**Propósito:** Selector de fechas especializado para reservas con calendario visual, navegación rápida, y validación de fechas disponibles.

**Motivo de Existencia:** Proporciona selección de fechas intuitiva específicamente diseñada para el contexto de reservas deportivas.

**Funciones Principales:**
- `DateSelector` - Widget principal del selector de fechas
- `buildCalendarView()` - Construye vista de calendario interactivo
- `buildQuickDateButtons()` - Crea botones para fechas comunes (hoy, mañana)
- `buildDatePicker()` - Integra date picker nativo del sistema
- `validateSelectedDate()` - Valida que fecha seleccionada sea válida para reservas
- `handleDateSelection()` - Procesa selección de fecha y notifica
- `highlightAvailableDates()` - Resalta fechas con disponibilidad

##### `lib/presentation/widgets/booking/enhanced_court_tabs.dart`
**Propósito:** Versión mejorada de los tabs de canchas con información adicional, estadísticas de uso, y estados avanzados.

**Motivo de Existencia:** Proporciona información rica sobre cada cancha para ayudar a usuarios a tomar decisiones informadas sobre reservas.

**Funciones Principales:**
- `EnhancedCourtTabs` - Widget principal de tabs mejorados
- `buildEnhancedTab()` - Construye tab individual con información extendida
- `buildUsageIndicator()` - Muestra indicador de uso de la cancha
- `buildCourtDetails()` - Muestra detalles adicionales de cancha
- `buildAvailabilityChart()` - Crea gráfico de disponibilidad
- `updateCourtMetrics()` - Actualiza métricas de uso de canchas

##### `lib/presentation/widgets/booking/reservation_form_modal.dart`
**Propósito:** Modal principal para crear y editar reservas. Maneja selección de jugadores, validaciones de conflictos, auto-completado, y envío de datos.

**Motivo de Existencia:** Interface crítica para creación de reservas que debe manejar validaciones complejas, búsqueda de usuarios, y orquestar todo el proceso de reserva.

**Funciones Principales:**
- `ReservationFormModal` - Widget principal del modal de reservas
- `initializeOrganizer()` - Auto-completa organizador desde URL/sesión
- `buildPlayerSelection()` - Construye interface de selección de jugadores
- `buildUserSearch()` - Crea buscador de usuarios con autocompletado
- `buildSelectedPlayers()` - Muestra jugadores seleccionados
- `validateReservation()` - Valida toda la reserva antes de envío
- `createReservation()` - Crea reserva en backend con emails
- `handleConflictValidation()` - Maneja validaciones de conflictos en tiempo real
- `showValidationErrors()` - Muestra errores de validación al usuario
- `mapPlayerPhones()` - Mapea teléfonos desde base de datos a jugadores

##### `lib/presentation/widgets/booking/reservation_webview.dart`
**Propósito:** WebView integrado para mostrar reservas en formato web, posiblemente para integración con sistema legacy GAS o visualización alternativa.

**Motivo de Existencia:** Proporciona fallback o integración con sistemas web existentes, manteniendo compatibilidad con interfaces legacy.

**Funciones Principales:**
- `ReservationWebView` - Widget principal del WebView
- `loadWebContent()` - Carga contenido web específico
- `injectJavaScript()` - Inyecta JavaScript para comunicación
- `handleWebMessages()` - Maneja mensajes entre Flutter y web
- `setupBridge()` - Configura bridge de comunicación bidireccional

##### `lib/presentation/widgets/booking/time_slot_block.dart`
**Propósito:** Bloque individual para mostrar slots de tiempo con estado visual, información de reserva, y acciones disponibles.

**Motivo de Existencia:** Representa visualmente cada slot de tiempo disponible con toda la información relevante y acciones posibles.

**Funciones Principales:**
- `TimeSlotBlock` - Widget principal del bloque de tiempo
- `buildSlotContent()` - Construye contenido interno del slot
- `buildSlotHeader()` - Crea header con hora y estado
- `buildPlayersList()` - Muestra lista de jugadores si está reservado
- `buildActionButtons()` - Crea botones de acción disponibles
- `getSlotColor()` - Determina color según estado del slot
- `handleSlotTap()` - Maneja interacciones del usuario con el slot

### **Widgets Raíz (3 archivos)**

#### `lib/presentation/widgets/court_tab_button.dart`
**Propósito:** Versión base del botón de selección de canchas, posiblemente la implementación original antes de las versiones compactas y mejoradas.

**Motivo de Existencia:** Mantiene compatibilidad con implementaciones existentes mientras se desarrollan versiones mejoradas.

**Funciones Principales:**
- `CourtTabButton` - Widget base del botón de cancha
- `buildButton()` - Construye estructura básica del botón
- `handleSelection()` - Maneja selección básica de cancha

#### `lib/presentation/widgets/time_slot_block.dart`
**Propósito:** Implementación base del bloque de tiempo, posiblemente versión original antes de mejoras específicas para booking.

**Motivo de Existencia:** Mantiene funcionalidad base mientras se desarrollan versiones especializadas.

**Funciones Principales:**
- `TimeSlotBlock` - Widget base del slot de tiempo
- `buildSlot()` - Construye estructura básica del slot
- `updateSlotState()` - Actualiza estado básico del slot

#### `lib/presentation/widgets/user_selector_widget.dart`
**Propósito:** Widget especializado para selección de usuarios con búsqueda, filtros, y selección múltiple para reservas.

**Motivo de Existencia:** Proporciona interface avanzada para búsqueda y selección de usuarios, especialmente importante para formar grupos de reserva.

**Funciones Principales:**
- `UserSelectorWidget` - Widget principal de selección de usuarios
- `buildSearchBar()` - Construye barra de búsqueda de usuarios
- `buildUserList()` - Muestra lista de usuarios filtrada
- `buildSelectedUsers()` - Muestra usuarios ya seleccionados
- `handleUserSelection()` - Maneja selección/deselección de usuarios
- `filterUsers()` - Aplica filtros de búsqueda
- `validateSelection()` - Valida selección de usuarios (máximos, mínimos)

---

## 🏢 **DOMAIN LAYER (7 archivos)**

### **Entities (4 archivos)**

#### `lib/domain/entities/booking.dart`
**Propósito:** Entidad de dominio que representa una reserva en el sistema. Define la estructura pura de datos de negocio sin dependencias de frameworks externos.

**Motivo de Existencia:** Encapsula la lógica de negocio central de reservas, independiente de detalles de implementación, siguiendo principios de Clean Architecture.

**Funciones Principales:**
- `Booking` - Clase entidad principal de reserva
- `createBooking()` - Factory method para crear reservas válidas
- `validateBooking()` - Valida reglas de negocio de reservas
- `addPlayer()` - Agrega jugador con validaciones de negocio
- `removePlayer()` - Remueve jugador con validaciones
- `isComplete()` - Verifica si reserva está completa según reglas
- `canBeCancelled()` - Determina si reserva puede ser cancelada
- `getDuration()` - Calcula duración de la reserva
- `conflictsWith()` - Verifica conflictos con otra reserva

#### `lib/domain/entities/court.dart`
**Propósito:** Entidad que representa una cancha deportiva con sus características, disponibilidad, y reglas específicas.

**Motivo de Existencia:** Modela las canchas como entidades de negocio con sus propias reglas y características independientes de la implementación.

**Funciones Principales:**
- `Court` - Clase entidad principal de cancha
- `isAvailable()` - Verifica disponibilidad en horario específico
- `getCapacity()` - Obtiene capacidad máxima de jugadores
- `validateReservation()` - Valida que reserva sea compatible con cancha
- `getMaintenanceWindows()` - Obtiene ventanas de mantenimiento
- `isUnderMaintenance()` - Verifica si está en mantenimiento

#### `lib/domain/entities/settings.dart`
**Propósito:** Entidad que encapsula configuraciones y reglas del sistema de reservas a nivel de dominio.

**Motivo de Existencia:** Centraliza reglas de negocio configurables que pueden cambiar sin afectar la lógica core del sistema.

**Funciones Principales:**
- `Settings` - Clase entidad de configuraciones
- `getBookingRules()` - Obtiene reglas de reservas configurables
- `getTimeSlotDuration()` - Obtiene duración estándar de slots
- `getMaxAdvanceBooking()` - Obtiene máximo tiempo de anticipación
- `getMinCancellationTime()` - Obtiene tiempo mínimo para cancelar
- `isHolidayBookingAllowed()` - Verifica si se permiten reservas en feriados

#### `lib/domain/entities/user.dart`
**Propósito:** Entidad de dominio que representa un usuario/socio del club con sus características, roles, y reglas de negocio específicas.

**Motivo de Existencia:** Modela usuarios como entidades de negocio con reglas específicas del dominio del club, independiente de autenticación o persistencia.

**Funciones Principales:**
- `User` - Clase entidad principal de usuario
- `canMakeReservation()` - Verifica si usuario puede hacer reservas
- `getReservationLimits()` - Obtiene límites de reservas por usuario
- `isActiveMember()` - Verifica si es socio activo
- `hasRole()` - Verifica roles específicos del usuario
- `canCancelReservation()` - Determina si puede cancelar reservas
- `getContactInfo()` - Obtiene información de contacto validada

### **Repositories (3 archivos)**

#### `lib/domain/repositories/booking_repository.dart`
**Propósito:** Contrato/interfaz que define operaciones de persistencia para reservas sin especificar implementación concreta.

**Motivo de Existencia:** Abstrae operaciones de datos siguiendo Dependency Inversion Principle, permitiendo diferentes implementaciones de persistencia.

**Funciones Principales:**
- `BookingRepository` - Interfaz abstracta del repositorio
- `createBooking()` - Contrato para crear reservas
- `getBookings()` - Contrato para obtener reservas con filtros
- `updateBooking()` - Contrato para actualizar reservas
- `deleteBooking()` - Contrato para eliminar reservas
- `getBookingsByUser()` - Contrato para obtener reservas por usuario
- `getBookingsByDate()` - Contrato para obtener reservas por fecha
- `getBookingsByTimeRange()` - Contrato para obtener reservas por rango temporal

#### `lib/domain/repositories/court_repository.dart`
**Propósito:** Interfaz que define operaciones de persistencia para canchas y su gestión.

**Motivo de Existencia:** Abstrae operaciones de datos de canchas permitiendo diferentes fuentes de datos (Firebase, API, local).

**Funciones Principales:**
- `CourtRepository` - Interfaz abstracta del repositorio de canchas
- `getCourts()` - Contrato para obtener todas las canchas
- `getCourtById()` - Contrato para obtener cancha específica
- `updateCourtStatus()` - Contrato para actualizar estado de cancha
- `getAvailableCourts()` - Contrato para obtener canchas disponibles
- `getCourtSchedule()` - Contrato para obtener horarios de cancha

#### `lib/domain/repositories/user_repository.dart`
**Propósito:** Interfaz que define operaciones de persistencia y búsqueda de usuarios del sistema.

**Motivo de Existencia:** Abstrae operaciones de usuarios permitiendo diferentes implementaciones de autenticación y almacenamiento.

**Funciones Principales:**
- `UserRepository` - Interfaz abstracta del repositorio de usuarios
- `getUserById()` - Contrato para obtener usuario por ID
- `getUserByEmail()` - Contrato para obtener usuario por email
- `searchUsers()` - Contrato para búsqueda de usuarios
- `getAllUsers()` - Contrato para obtener todos los usuarios
- `updateUser()` - Contrato para actualizar datos de usuario
- `syncUsers()` - Contrato para sincronización de usuarios

---

## 💾 **DATA LAYER (9 archivos)**

### **Models (3 archivos)**

#### `lib/data/models/booking_model.dart`
**Propósito:** Modelo de datos que implementa serialización/deserialización de reservas para comunicación con Firebase y APIs externas.

**Motivo de Existencia:** Maneja conversión entre entidades de dominio y formatos de datos externos, encapsulando lógica de mapeo.

**Funciones Principales:**
- `BookingModel` - Clase modelo para serialización de reservas
- `fromJson()` - Convierte JSON de Firebase a modelo
- `toJson()` - Convierte modelo a JSON para Firebase
- `fromEntity()` - Convierte entidad de dominio a modelo
- `toEntity()` - Convierte modelo a entidad de dominio
- `copyWith()` - Crea copias modificadas del modelo
- `validateModel()` - Valida integridad de datos del modelo

#### `lib/data/models/court_model.dart`
**Propósito:** Modelo de datos para canchas que maneja serialización y conversión entre formatos de Firebase y entidades de dominio.

**Motivo de Existencia:** Abstrae detalles de persistencia de canchas y proporciona conversiones seguras entre capas.

**Funciones Principales:**
- `CourtModel` - Clase modelo para serialización de canchas
- `fromFirestore()` - Convierte documento Firestore a modelo
- `toFirestore()` - Convierte modelo a documento Firestore
- `fromEntity()` - Convierte entidad de dominio a modelo
- `toEntity()` - Convierte modelo a entidad de dominio
- `updateFromMap()` - Actualiza modelo desde Map genérico

#### `lib/data/models/user_model.dart`
**Propósito:** Modelo de datos para usuarios que maneja la estructura híbrida español/inglés de Firebase y conversiones a entidades de dominio.

**Motivo de Existencia:** Gestiona la complejidad de la migración de nomenclatura y proporciona interface consistente para entidades de usuario.

**Funciones Principales:**
- `UserModel` - Clase modelo para serialización de usuarios
- `fromFirebase()` - Convierte datos Firebase a modelo (maneja español/inglés)
- `toFirebase()` - Convierte modelo a formato Firebase
- `fromEntity()` - Convierte entidad de dominio a modelo
- `toEntity()` - Convierte modelo a entidad de dominio
- `mapSpanishToEnglish()` - Mapea campos de nomenclatura española a inglesa
- `validateUserData()` - Valida integridad y completitud de datos

### **Repository Implementations (3 archivos)**

#### `lib/data/repositories/booking_repository_impl.dart`
**Propósito:** Implementación concreta del repositorio de reservas que utiliza Firebase Firestore como backend de persistencia.

**Motivo de Existencia:** Implementa el contrato definido en domain layer usando Firebase, manejando detalles específicos de Firestore.

**Funciones Principales:**
- `BookingRepositoryImpl` - Implementación concreta del repositorio
- `createBooking()` - Implementa creación en Firestore con transacciones
- `getBookings()` - Implementa queries complejas en Firestore
- `updateBooking()` - Implementa actualización con validaciones
- `deleteBooking()` - Implementa eliminación segura
- `getBookingsByUser()` - Implementa consultas por usuario específico
- `getBookingsByDateRange()` - Implementa consultas por rango de fechas
- `_handleFirestoreErrors()` - Maneja errores específicos de Firestore
- `_buildQuery()` - Construye queries complejas para Firestore

#### `lib/data/repositories/court_repository_impl.dart`
**Propósito:** Implementación del repositorio de canchas usando Firebase Firestore para persistencia y consultas.

**Motivo de Existencia:** Proporciona implementación concreta para operaciones de canchas con optimizaciones específicas de Firestore.

**Funciones Principales:**
- `CourtRepositoryImpl` - Implementación concreta del repositorio de canchas
- `getCourts()` - Implementa obtención de canchas desde Firestore
- `getCourtById()` - Implementa búsqueda por ID específico
- `updateCourtStatus()` - Implementa actualización de estado de canchas
- `getAvailableCourts()` - Implementa consulta de disponibilidad
- `_cacheCourtData()` - Implementa caché local para performance

#### `lib/data/repositories/user_repository_impl.dart`
**Propósito:** Implementación del repositorio de usuarios que integra Firebase Firestore con sincronización automática de Google Sheets.

**Motivo de Existencia:** Implementa gestión completa de usuarios incluyendo sincronización con sistema legacy y búsquedas optimizadas.

**Funciones Principales:**
- `UserRepositoryImpl` - Implementación concreta del repositorio de usuarios
- `getUserById()` - Implementa búsqueda por ID en Firestore
- `getUserByEmail()` - Implementa búsqueda por email optimizada
- `searchUsers()` - Implementa búsqueda con filtros múltiples
- `getAllUsers()` - Implementa carga completa con caché
- `syncUsers()` - Implementa sincronización con Google Sheets
- `_optimizeSearch()` - Optimiza consultas de búsqueda para performance

### **Services (3 archivos)**

#### `lib/data/services/email_service.dart`
**Propósito:** Servicio para gestión de emails automáticos del sistema incluyendo confirmaciones de reserva, cancelaciones, y notificaciones. Integra con Firebase Functions para envío.

**Motivo de Existencia:** Centraliza toda la lógica de emails del sistema, abstrae la comunicación con backend de emails, y maneja diferentes tipos de notificaciones.

**Funciones Principales:**
- `EmailService` - Clase principal del servicio de emails
- `sendBookingConfirmation()` - Envía confirmación de reserva a todos los jugadores
- `sendCancellationNotification()` - Envía notificación de cancelación a participantes
- `sendReminderEmail()` - Envía recordatorios antes de reservas
- `generateBookingEmail()` - Genera contenido HTML para emails de reserva
- `generateCancellationEmail()` - Genera contenido para emails de cancelación
- `validateEmailAddresses()` - Valida direcciones de email antes de envío
- `handleEmailErrors()` - Maneja errores de envío de emails
- `trackEmailDelivery()` - Rastrea entrega exitosa de emails

#### `lib/data/services/firestore_service.dart`
**Propósito:** Servicio de bajo nivel para operaciones directas con Firebase Firestore. Maneja conexiones, transacciones, y operaciones CRUD básicas.

**Motivo de Existencia:** Abstrae la complejidad de Firestore y proporciona una API limpia para operaciones de base de datos con manejo robusto de errores.

**Funciones Principales:**
- `FirestoreService` - Clase principal del servicio Firestore
- `createDocument()` - Crea documentos con validaciones
- `updateDocument()` - Actualiza documentos existentes
- `deleteDocument()` - Elimina documentos con verificaciones
- `getDocument()` - Obtiene documento específico
- `getCollection()` - Obtiene colección completa con filtros
- `performTransaction()` - Ejecuta transacciones atómicas
- `setupRealTimeListener()` - Configura listeners en tiempo real
- `handleConnectionErrors()` - Maneja errores de conectividad
- `optimizeQueries()` - Optimiza queries para performance

#### `lib/data/services/ics_generator.dart`
**Propósito:** Servicio especializado para generar archivos ICS (iCalendar) que permiten a usuarios agregar reservas a sus calendarios personales.

**Motivo de Existencia:** Proporciona integración con calendarios externos, mejora UX permitiendo que usuarios gestionen reservas en sus apps de calendario preferidas.

**Funciones Principales:**
- `ICSGenerator` - Clase principal del generador ICS
- `generateBookingICS()` - Genera archivo ICS para reserva específica
- `generateMultipleBookingsICS()` - Genera ICS para múltiples reservas
- `formatDateTime()` - Formatea fechas para formato ICS estándar
- `addReminders()` - Agrega recordatorios al evento de calendario
- `setRecurrence()` - Configura eventos recurrentes
- `validateICSFormat()` - Valida que ICS generado sea válido
- `generateDownloadLink()` - Crea enlace de descarga para archivo ICS

---

## ⚙️ **CORE LAYER (11 archivos)**

### **Constants (2 archivos)**

#### `lib/core/constants/app_constants.dart`
**Propósito:** Definiciones centralizadas de constantes utilizadas en toda la aplicación incluyendo colores, configuraciones de tiempo, límites, y textos estáticos.

**Motivo de Existencia:** Centraliza valores que pueden cambiar, facilita mantenimiento, asegura consistencia visual y funcional en toda la aplicación.

**Funciones Principales:**
- `AppConstants` - Clase con constantes globales de la aplicación
- `AppColors` - Constantes de colores por estado y cancha
- `TimeSlotConstants` - Configuraciones de horarios y duración
- `BookingLimits` - Límites de reservas y validaciones
- `UIConstants` - Constantes de interfaz de usuario
- `TextConstants` - Textos estáticos y etiquetas
- `ValidationRules` - Reglas de validación del sistema

#### `lib/core/constants/firebase_constants.dart`
**Propósito:** Constantes específicas para configuración y operaciones de Firebase incluyendo nombres de colecciones, campos, y configuraciones.

**Motivo de Existencia:** Centraliza configuraciones de Firebase, evita strings hardcodeados, y facilita cambios en estructura de base de datos.

**Funciones Principales:**
- `FirebaseConstants` - Clase con constantes de Firebase
- `Collections` - Nombres de colecciones de Firestore
- `Fields` - Nombres de campos de documentos
- `Indexes` - Configuraciones de índices requeridos
- `SecurityRules` - Referencias a reglas de seguridad
- `FunctionNames` - Nombres de Cloud Functions

### **Dependency Injection (1 archivo)**

#### `lib/core/di/injection_container.dart`
**Propósito:** Configuración de inyección de dependencias usando get_it para registrar y resolver dependencias de servicios, repositorios, y providers.

**Motivo de Existencia:** Implementa Dependency Inversion Principle, facilita testing con mocks, y centraliza configuración de dependencias.

**Funciones Principales:**
- `InjectionContainer` - Clase principal para configuración DI
- `init()` - Inicializa y registra todas las dependencias
- `registerRepositories()` - Registra implementaciones de repositorios
- `registerServices()` - Registra servicios del sistema
- `registerProviders()` - Registra providers de estado
- `registerUseCases()` - Registra casos de uso del dominio
- `reset()` - Resetea container para testing

### **Enums (1 archivo)**

#### `lib/core/enums/user_role.dart`
**Propósito:** Definición de roles de usuarios del sistema con sus permisos y capacidades específicas.

**Motivo de Existencia:** Tipifica roles de manera segura, centraliza lógica de permisos, y facilita expansión del sistema de roles.

**Funciones Principales:**
- `UserRole` - Enum principal de roles de usuario
- `getPermissions()` - Obtiene permisos específicos por rol
- `canMakeReservation()` - Verifica si rol puede hacer reservas
- `canCancelReservation()` - Verifica si rol puede cancelar
- `canViewAllReservations()` - Verifica permisos de visualización
- `isAdminRole()` - Determina si es rol administrativo

### **Services (3 archivos)**

#### `lib/core/services/firebase_user_service.dart`
**Propósito:** Servicio especializado para gestionar usuarios en Firebase con enfoque en la estructura específica del proyecto y sincronización con Google Sheets.

**Motivo de Existencia:** Abstrae complejidad específica de usuarios en Firebase, maneja migración de nomenclatura, y proporciona API optimizada para búsquedas.

**Funciones Principales:**
- `FirebaseUserService` - Clase principal del servicio
- `getAllUsers()` - Carga todos los usuarios con estructura completa
- `searchUsersByEmail()` - Búsqueda optimizada por email
- `getUserByEmail()` - Obtiene usuario específico por email
- `syncUsersFromSheets()` - Sincroniza usuarios desde Google Sheets
- `validateUserStructure()` - Valida estructura de datos de usuario
- `mapUserFields()` - Mapea campos entre nomenclaturas
- `handleFallbackUsers()` - Maneja usuarios de desarrollo/testing
- `optimizeUserCache()` - Optimiza caché local de usuarios

#### `lib/core/services/schedule_service.dart`
**Propósito:** Servicio para gestión de horarios, disponibilidad de slots, y cálculos relacionados con planificación de reservas.

**Motivo de Existencia:** Centraliza lógica compleja de horarios, maneja zonas horarias, y proporciona cálculos de disponibilidad optimizados.

**Funciones Principales:**
- `ScheduleService` - Clase principal del servicio de horarios
- `getAvailableTimeSlots()` - Obtiene slots disponibles para fecha/cancha
- `calculateSlotAvailability()` - Calcula disponibilidad considerando reservas existentes
- `validateTimeSlot()` - Valida que slot sea válido para reservas
- `getBusinessHours()` - Obtiene horarios de operación del club
- `checkHolidaySchedule()` - Verifica horarios especiales en feriados
- `calculateDuration()` - Calcula duración entre horarios
- `formatTimeDisplay()` - Formatea horarios para visualización
- `handleTimeZoneConversion()` - Maneja conversiones de zona horaria

#### `lib/core/services/user_service.dart`
**Propósito:** Servicio de alto nivel para operaciones de usuarios que combina datos de Firebase con lógica de negocio específica del sistema.

**Motivo de Existencia:** Abstrae lógica de negocio de usuarios, maneja casos especiales (usuarios VISITA), y proporciona API unificada para la capa de presentación.

**Funciones Principales:**
- `UserService` - Clase principal del servicio
- `searchUsers()` - Búsqueda avanzada con filtros múltiples
- `getCurrentUser()` - Obtiene usuario actual con contexto de sesión
- `validateUserForBooking()` - Valida que usuario pueda hacer reservas
- `formatUserName()` - Formatea nombres consistentemente
- `checkUserConflicts()` - Verifica conflictos de horarios para usuario
- `handleSpecialUsers()` - Maneja usuarios especiales (VISITA, temporal)
- `cacheUserData()` - Gestiona caché local de usuarios frecuentes
- `getFallbackUsers()` - Proporciona usuarios de desarrollo cuando es necesario

### **Theme (1 archivo)**

#### `lib/core/theme/app_theme.dart`
**Propósito:** Configuración centralizada del tema visual de la aplicación incluyendo colores, tipografías, espaciados, y estilos consistentes.

**Motivo de Existencia:** Asegura consistencia visual en toda la aplicación, facilita cambios de tema, y centraliza decisiones de diseño.

**Funciones Principales:**
- `AppTheme` - Clase principal de configuración de tema
- `getLightTheme()` - Configuración de tema claro
- `getDarkTheme()` - Configuración de tema oscuro
- `getColorScheme()` - Esquema de colores de la aplicación
- `getTextTheme()` - Configuración de tipografías
- `getButtonTheme()` - Estilos de botones consistentes
- `getCardTheme()` - Estilos de tarjetas y containers
- `getInputDecorationTheme()` - Estilos de campos de entrada

---

## 🛠️ **UTILS LAYER (1 archivo)**

#### `lib/utils/firebase_seeder.dart`
**Propósito:** Utilidad para poblar Firebase con datos de desarrollo, testing, y configuraciones iniciales del sistema.

**Motivo de Existencia:** Facilita setup inicial del proyecto, proporciona datos consistentes para desarrollo, y automatiza configuración de entorno.

**Funciones Principales:**
- `FirebaseSeeder` - Clase principal del seeder
- `seedInitialData()` - Puebla datos iniciales en Firestore
- `createTestUsers()` - Crea usuarios de prueba para desarrollo
- `createSampleBookings()` - Crea reservas de ejemplo
- `setupCourts()` - Configura canchas iniciales
- `seedSettings()` - Configura ajustes iniciales del sistema
- `cleanDatabase()` - Limpia datos de testing
- `validateSeededData()` - Valida integridad de datos sembrados

---

## 🔧 **ARCHIVOS RAÍZ (2 archivos)**

#### `lib/firebase_options.dart`
**Propósito:** Configuraciones auto-generadas de Firebase para diferentes plataformas (Web, Android, iOS) con claves y endpoints específicos.

**Motivo de Existencia:** Archivo generado por Firebase CLI que contiene configuraciones específicas por plataforma para conectar con proyectos Firebase.

**Funciones Principales:**
- `DefaultFirebaseOptions` - Clase con configuraciones por plataforma
- `currentPlatform` - Obtiene configuración para plataforma actual
- `web` - Configuraciones específicas para Flutter Web
- `android` - Configuraciones para Android (si aplica)
- `ios` - Configuraciones para iOS (si aplica)

#### `lib/main.dart`
**Propósito:** Punto de entrada principal de la aplicación Flutter. Inicializa Firebase, configura providers globales, maneja parámetros de URL, y arranca la aplicación.

**Motivo de Existencia:** Archivo requerido por Flutter como entry point. Configura el entorno global de la aplicación y establece la arquitectura base.

**Funciones Principales:**
- `main()` - Función principal que inicializa y ejecuta la aplicación
- `MyApp` - Widget raíz que configura tema, routing, y providers
- `initializeApp()` - Inicializa Firebase y configuraciones globales
- `setupProviders()` - Configura providers de estado globales
- `handleUrlParameters()` - Procesa parámetros de URL para integración GAS
- `configureRouting()` - Establece routing y navegación inicial
- `handleDeepLinks()` - Maneja enlaces profundos de la aplicación

---

## 📊 **ANÁLISIS DE ARQUITECTURA**

### **Adherencia a Clean Architecture:**
```
✅ SEPARACIÓN DE CAPAS: Presentation, Domain, Data, Core claramente definidas
✅ DEPENDENCY INVERSION: Domain no depende de implementaciones concretas
✅ SINGLE RESPONSIBILITY: Cada archivo tiene responsabilidad específica
✅ OPEN/CLOSED PRINCIPLE: Extensible sin modificar código existente
✅ INTERFACE SEGREGATION: Repositorios con interfaces específicas
```

### **Patterns Implementados:**
- **Repository Pattern**: Abstrae persistencia de datos
- **Provider Pattern**: Gestión de estado reactivo
- **Service Pattern**: Lógica de negocio encapsulada
- **Factory Pattern**: Creación de entidades con validación
- **Dependency Injection**: Desacoplamiento de dependencias

### **Archivos Críticos (Top 20):**
1. `lib/main.dart` - Entry point y configuración global
2. `lib/presentation/pages/reservations_page.dart` - Página principal de reservas
3. `lib/presentation/widgets/booking/reservation_form_modal.dart` - Modal crítico de reservas
4. `lib/presentation/providers/booking_provider.dart` - Estado de reservas
5. `lib/domain/entities/booking.dart` - Entidad core de negocio
6. `lib/data/repositories/booking_repository_impl.dart` - Persistencia de reservas
7. `lib/core/services/firebase_user_service.dart` - Gestión de usuarios Firebase
8. `lib/data/services/firestore_service.dart` - Servicio base de datos
9. `lib/presentation/providers/user_provider.dart` - Estado de usuarios
10. `lib/core/services/user_service.dart` - Lógica de negocio usuarios
11. `lib/data/models/booking_model.dart` - Serialización de reservas
12. `lib/core/constants/app_constants.dart` - Configuraciones centrales
13. `lib/presentation/router/app_router.dart` - Navegación y routing
14. `lib/domain/entities/user.dart` - Entidad de usuario de dominio
15. `lib/data/services/email_service.dart` - Sistema de notificaciones
16. `lib/presentation/widgets/booking/time_slot_block.dart` - UI slots de tiempo
17. `lib/core/di/injection_container.dart` - Inyección de dependencias
18. `lib/data/repositories/user_repository_impl.dart` - Persistencia usuarios
19. `lib/core/services/schedule_service.dart` - Lógica de horarios
20. `lib/presentation/widgets/common/date_navigation_header.dart` - Navegación fechas

### **Flujos de Datos Principales:**

#### **Flujo Creación de Reserva:**
```
User Input → ReservationFormModal → BookingProvider → BookingRepository → FirestoreService → Firebase
                ↓
EmailService ← BookingProvider (after creation)
```

#### **Flujo Búsqueda de Usuarios:**
```
Search Input → UserSelectorWidget → UserProvider → UserService → FirebaseUserService → Firebase
```

#### **Flujo Navegación:**
```
User Action → AppRouter → Page Widget → Provider → Repository → Service → Firebase
```

---

## 📋 **PRÓXIMOS PASOS PARA SESIÓN 2**

### **Archivos para Documentación Detallada:**
1. **Críticos (Sesión 2):**
   - `reservation_form_modal.dart` - Lógica compleja de reservas
   - `booking_provider.dart` - Estado central del sistema
   - `firebase_user_service.dart` - Servicio core de usuarios
   - `booking_repository_impl.dart` - Persistencia crítica
   - `user_service.dart` - Lógica de negocio usuarios

2. **Importantes (Sesión 3):**
   - Resto de widgets de booking
   - Servicios de email e ICS
   - Modelos de datos
   - Configuraciones y constantes

### **Comentarios en Código a Agregar:**
- Headers descriptivos en cada archivo
- Documentación JSDoc para funciones principales
- Ejemplos de uso para servicios complejos
- TODOs para mejoras futuras

¿Te parece bien esta estructura? ¿Hay algún archivo específico que quieras que priorice para la documentación detallada en la siguiente sesión? 