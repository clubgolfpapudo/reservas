// lib/domain/entities/settings.dart
import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD PRINCIPAL: APP SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

class AppSettings extends Equatable {
  final String id;
  final SyncSettings sync;
  final BookingSettings booking;
  final ApplicationSettings application;

  const AppSettings({
    required this.id,
    required this.sync,
    required this.booking,
    required this.application,
  });

  @override
  List<Object> get props => [id, sync, booking, application];

  AppSettings copyWith({
    String? id,
    SyncSettings? sync,
    BookingSettings? booking,
    ApplicationSettings? application,
  }) {
    return AppSettings(
      id: id ?? this.id,
      sync: sync ?? this.sync,
      booking: booking ?? this.booking,
      application: application ?? this.application,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: SYNC SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

class SyncSettings extends Equatable {
  final bool sheetsToFirebaseEnabled;
  final int syncIntervalMinutes;
  final int lastSyncAt;
  final SyncStatus syncStatus;

  const SyncSettings({
    required this.sheetsToFirebaseEnabled,
    required this.syncIntervalMinutes,
    required this.lastSyncAt,
    required this.syncStatus,
  });

  factory SyncSettings.fromMap(Map<String, dynamic> map) {
    return SyncSettings(
      sheetsToFirebaseEnabled: map['sheetsToFirebaseEnabled'] ?? true,
      syncIntervalMinutes: map['syncIntervalMinutes'] ?? 5,
      lastSyncAt: map['lastSyncAt'] ?? 0,
      syncStatus: SyncStatus.fromString(map['syncStatus'] ?? 'ok'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sheetsToFirebaseEnabled': sheetsToFirebaseEnabled,
      'syncIntervalMinutes': syncIntervalMinutes,
      'lastSyncAt': lastSyncAt,
      'syncStatus': syncStatus.value,
    };
  }

  @override
  List<Object> get props => [
        sheetsToFirebaseEnabled,
        syncIntervalMinutes,
        lastSyncAt,
        syncStatus,
      ];

  SyncSettings copyWith({
    bool? sheetsToFirebaseEnabled,
    int? syncIntervalMinutes,
    int? lastSyncAt,
    SyncStatus? syncStatus,
  }) {
    return SyncSettings(
      sheetsToFirebaseEnabled: sheetsToFirebaseEnabled ?? this.sheetsToFirebaseEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: BOOKING SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

class BookingSettings extends Equatable {
  final int maxDaysInAdvance;
  final int maxBookingsPerUserPerDay;
  final bool requireVerification;
  final bool automaticCancellationEnabled;

  const BookingSettings({
    required this.maxDaysInAdvance,
    required this.maxBookingsPerUserPerDay,
    required this.requireVerification,
    required this.automaticCancellationEnabled,
  });

  factory BookingSettings.fromMap(Map<String, dynamic> map) {
    return BookingSettings(
      maxDaysInAdvance: map['maxDaysInAdvance'] ?? 4,
      maxBookingsPerUserPerDay: map['maxBookingsPerUserPerDay'] ?? 3,
      requireVerification: map['requireVerification'] ?? false,
      automaticCancellationEnabled: map['automaticCancellationEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxDaysInAdvance': maxDaysInAdvance,
      'maxBookingsPerUserPerDay': maxBookingsPerUserPerDay,
      'requireVerification': requireVerification,
      'automaticCancellationEnabled': automaticCancellationEnabled,
    };
  }

  @override
  List<Object> get props => [
        maxDaysInAdvance,
        maxBookingsPerUserPerDay,
        requireVerification,
        automaticCancellationEnabled,
      ];

  BookingSettings copyWith({
    int? maxDaysInAdvance,
    int? maxBookingsPerUserPerDay,
    bool? requireVerification,
    bool? automaticCancellationEnabled,
  }) {
    return BookingSettings(
      maxDaysInAdvance: maxDaysInAdvance ?? this.maxDaysInAdvance,
      maxBookingsPerUserPerDay: maxBookingsPerUserPerDay ?? this.maxBookingsPerUserPerDay,
      requireVerification: requireVerification ?? this.requireVerification,
      automaticCancellationEnabled: automaticCancellationEnabled ?? this.automaticCancellationEnabled,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENTIDAD: APPLICATION SETTINGS
// ═══════════════════════════════════════════════════════════════════════════════

class ApplicationSettings extends Equatable {
  final bool maintenanceMode;
  final String version;
  final String requiredClientVersion;
  final String announcementMessage;
  final bool showAnnouncement;

  const ApplicationSettings({
    required this.maintenanceMode,
    required this.version,
    required this.requiredClientVersion,
    required this.announcementMessage,
    required this.showAnnouncement,
  });

  factory ApplicationSettings.fromMap(Map<String, dynamic> map) {
    return ApplicationSettings(
      maintenanceMode: map['maintenanceMode'] ?? false,
      version: map['version'] ?? '1.0.0',
      requiredClientVersion: map['requiredClientVersion'] ?? '1.0.0',
      announcementMessage: map['announcementMessage'] ?? '',
      showAnnouncement: map['showAnnouncement'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'version': version,
      'requiredClientVersion': requiredClientVersion,
      'announcementMessage': announcementMessage,
      'showAnnouncement': showAnnouncement,
    };
  }

  @override
  List<Object> get props => [
        maintenanceMode,
        version,
        requiredClientVersion,
        announcementMessage,
        showAnnouncement,
      ];

  ApplicationSettings copyWith({
    bool? maintenanceMode,
    String? version,
    String? requiredClientVersion,
    String? announcementMessage,
    bool? showAnnouncement,
  }) {
    return ApplicationSettings(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      version: version ?? this.version,
      requiredClientVersion: requiredClientVersion ?? this.requiredClientVersion,
      announcementMessage: announcementMessage ?? this.announcementMessage,
      showAnnouncement: showAnnouncement ?? this.showAnnouncement,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum SyncStatus {
  ok('ok'),
  error('error'),
  paused('paused');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'ok':
        return SyncStatus.ok;
      case 'error':
        return SyncStatus.error;
      case 'paused':
        return SyncStatus.paused;
      default:
        return SyncStatus.ok;
    }
  }
}