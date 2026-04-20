import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, int>> getUserStats() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final activities = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('activities')
      .get();

  int totalWorkouts = activities.docs.length;
  int totalCalories = 0;

  for (var doc in activities.docs) {
    totalCalories += (doc.data()['calories'] ?? 0) as int;
  }

  return {
    'totalWorkouts': totalWorkouts,
    'totalCalories': totalCalories,
  };
}
