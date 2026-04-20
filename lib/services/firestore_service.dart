import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addActivity(Map<String, dynamic> activity) async {
    await _db.collection('activities').add(activity);
  }

  Future<void> updateActivity(String id, Map<String, dynamic> activity) async {
    await _db.collection('activities').doc(id).update(activity);
  }

  Future<void> deleteActivity(String id) async {
    await _db.collection('activities').doc(id).delete();
  }

  Stream<List<Map<String, dynamic>>> getActivitiesStream() {
    return _db.collection('activities')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include doc ID for edits/deletes
      return data;
    }).toList());
  }
}
