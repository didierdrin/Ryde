/// Stub replacements for Firestore types (no Firebase). Use DateTime where possible.

class Timestamp {
  final DateTime _d;
  Timestamp.fromDate(DateTime d) : _d = d;
  DateTime toDate() => _d;
  int compareTo(Timestamp other) => _d.compareTo(other._d);
  static Timestamp now() => Timestamp.fromDate(DateTime.now());
}

class GeoPoint {
  final double latitude;
  final double longitude;
  GeoPoint(this.latitude, this.longitude);
  static GeoPoint fromDynamic(dynamic v) {
    if (v == null) return GeoPoint(0, 0);
    if (v is GeoPoint) return v;
    if (v is Map) return GeoPoint((v['latitude'] as num?)?.toDouble() ?? 0, (v['longitude'] as num?)?.toDouble() ?? 0);
    return GeoPoint(0, 0);
  }
}

/// Placeholder for DocumentSnapshot - use data() to get map.
abstract class DocumentSnapshot {
  Map<String, dynamic> data();
  String get id;
  bool get exists => true;
}

class _SimpleDocumentSnapshot extends DocumentSnapshot {
  final Map<String, dynamic> _data;
  @override final String id;
  @override final bool exists;
  _SimpleDocumentSnapshot([Map<String, dynamic>? data, this.id = '', this.exists = true]) : _data = data ?? {};
  @override Map<String, dynamic> data() => _data;
}

/// Stub for FirebaseFirestore (no Firebase).
class FirebaseFirestore {
  FirebaseFirestore._();
  static final instance = FirebaseFirestore._();
  _CollectionReference collection(String path) => _CollectionReference(path);
}

class _CollectionReference {
  final String path;
  _CollectionReference(this.path);
  Future<_DocumentReference> add(Map<String, dynamic> data) async => _DocumentReference('');
  _DocumentReference doc([String? id]) => _DocumentReference(id ?? '');
  _Query where(String field, {dynamic isEqualTo, dynamic isNotEqualTo, dynamic arrayContains, dynamic isGreaterThanOrEqualTo, dynamic isLessThanOrEqualTo}) => _Query();
  _Query orderBy(String field, {bool descending = false}) => _Query();
  Future<_QuerySnapshot> get() async => _QuerySnapshot(<DocumentSnapshot>[]);
  Stream<_QuerySnapshot> snapshots() => Stream.value(_QuerySnapshot(<DocumentSnapshot>[]));
}

class _DocumentReference {
  final String id;
  _DocumentReference(this.id);
  Future<DocumentSnapshot> get() async => _SimpleDocumentSnapshot({}, id);
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}
  _CollectionReference collection(String path) => _CollectionReference(path);
  Stream<DocumentSnapshot> snapshots() => Stream.value(_SimpleDocumentSnapshot({}, id));
}

class _Query {
  _Query orderBy(String field, {bool descending = false}) => this;
  _Query limit(int n) => this;
  _Query where(String field, {dynamic isEqualTo, dynamic isNotEqualTo, dynamic arrayContains, dynamic isGreaterThanOrEqualTo, dynamic isLessThanOrEqualTo}) => this;
  Stream<_QuerySnapshot> snapshots() => Stream.value(_QuerySnapshot(<DocumentSnapshot>[]));
  Future<_QuerySnapshot> get() async => _QuerySnapshot(<DocumentSnapshot>[]);
}

class _QuerySnapshot {
  final List<DocumentSnapshot> docs;
  _QuerySnapshot(this.docs);
}

class _DocumentSnapshot extends DocumentSnapshot {
  @override final String id;
  final Map<String, dynamic> _data;
  _DocumentSnapshot(this.id, [Map<String, dynamic>? data]) : _data = data ?? {};
  @override Map<String, dynamic> data() => _data;
}

typedef CollectionReference = _CollectionReference;
typedef QuerySnapshot = _QuerySnapshot;

class FieldValue {
  static Object serverTimestamp() => DateTime.now();
  static Object arrayRemove(List<dynamic> elements) => elements;
}

class FieldPath {
  static const documentId = 'documentId';
}

class SetOptions {
  final bool merge;
  SetOptions({this.merge = false});
}

/// Stub for Firebase Storage (no Firebase).
class FirebaseStorage {
  FirebaseStorage._();
  static final instance = FirebaseStorage._();
  _StorageRef ref() => _StorageRef();
}

class _StorageRef {
  _StorageRef child(String path) => this;
  Future<void> putFile(dynamic file) async {}
  Future<String> getDownloadURL() async => '';
}
