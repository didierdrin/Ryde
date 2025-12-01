import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde_rw/models/drivers.dart';

class DriverService {
  final CollectionReference driversCollection = FirebaseFirestore.instance
      .collection('drivers');

  // Stream to get all drivers in real-time
  Stream<List<Driver>> getDriversStream() {
    return driversCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Driver.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Stream to get a single driver in real-time by ID
  Stream<Driver?> getDriverStreamById(String driverId) {
    return driversCollection.doc(driverId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Driver.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }
}

