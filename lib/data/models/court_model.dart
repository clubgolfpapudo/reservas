// lib/data/models/court_model.dart
class CourtModel extends Court {
  const CourtModel({
    required super.id,
    required super.number,
    required super.name,
    required super.status,
    required super.metadata,
  });

  factory CourtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CourtModel(
      id: doc.id,
      number: data['number'] ?? 0,
      name: data['name'] ?? '',
      status: CourtStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => CourtStatus.inactive,
      ),
      metadata: CourtMetadataModel.fromMap(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'number': number,
      'name': name,
      'status': status.name,
      'metadata': {
        'createdAt': metadata.createdAt,
        'updatedAt': metadata.updatedAt,
      },
    };
  }
}

class CourtMetadataModel extends CourtMetadata {
  const CourtMetadataModel({
    required super.createdAt,
    required super.updatedAt,
  });

  factory CourtMetadataModel.fromMap(Map<String, dynamic> data) {
    return CourtMetadataModel(
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
    );
  }
}