class ProfileInformation {
  final String userId;
  final String shortBio;
  final String hobbies;
  final String? governmentIdUrl;
  final String? drivingLicenseUrl;
  final DateTime updatedAt;

  ProfileInformation({
    required this.userId,
    required this.shortBio,
    required this.hobbies,
    this.governmentIdUrl,
    this.drivingLicenseUrl,
    required this.updatedAt,
  });

  factory ProfileInformation.fromJSON(Map<String, dynamic> doc) {
    return ProfileInformation(
      userId: doc['userId'] ?? '',
      shortBio: doc['shortBio'] ?? '',
      hobbies: doc['hobbies'] ?? '',
      governmentIdUrl: doc['governmentIdUrl'],
      drivingLicenseUrl: doc['drivingLicenseUrl'],
      updatedAt: _parseDateTime(doc['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shortBio': shortBio,
      'hobbies': hobbies,
      'governmentIdUrl': governmentIdUrl,
      'drivingLicenseUrl': drivingLicenseUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
