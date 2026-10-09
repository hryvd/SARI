/// Domain entity – store_profile table.
/// No Flutter imports. Pure Dart data class.
class StoreProfile {
  const StoreProfile({
    required this.id,
    required this.storeType,
    required this.storeName,
    required this.ownerName,
    this.googleEmail,
    this.pinHash,
    this.latitude,
    this.longitude,
    this.permitDocsJson,
    required this.createdAt,
  });

  final String id;
  final String storeType;
  final String storeName;
  final String ownerName;
  final String? googleEmail;
  final String? pinHash;
  final double? latitude;
  final double? longitude;
  final String? permitDocsJson;
  final DateTime createdAt;

  StoreProfile copyWith({
    String? id,
    String? storeType,
    String? storeName,
    String? ownerName,
    String? googleEmail,
    String? pinHash,
    double? latitude,
    double? longitude,
    String? permitDocsJson,
    DateTime? createdAt,
  }) {
    return StoreProfile(
      id: id ?? this.id,
      storeType: storeType ?? this.storeType,
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      googleEmail: googleEmail ?? this.googleEmail,
      pinHash: pinHash ?? this.pinHash,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      permitDocsJson: permitDocsJson ?? this.permitDocsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'store_type': storeType,
        'store_name': storeName,
        'owner_name': ownerName,
        'google_email': googleEmail,
        'pin_hash': pinHash,
        'latitude': latitude,
        'longitude': longitude,
        'permit_docs_json': permitDocsJson,
        'created_at': createdAt.toIso8601String(),
      };

  factory StoreProfile.fromMap(Map<String, dynamic> m) => StoreProfile(
        id: m['id'] as String,
        storeType: m['store_type'] as String? ?? 'sari_sari',
        storeName: m['store_name'] as String? ?? 'My Store',
        ownerName: m['owner_name'] as String? ?? 'Owner',
        googleEmail: m['google_email'] as String?,
        pinHash: m['pin_hash'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        permitDocsJson: m['permit_docs_json'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime.now(),
      );
}
