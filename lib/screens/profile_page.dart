import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rxdart/rxdart.dart'; // <-- add this import
import '../providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _weeklyDistanceController = TextEditingController();
  final _monthlyCaloriesController = TextEditingController();

  File? _pickedImage;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      final goals = data['goals'] ?? {};
      _weeklyDistanceController.text = (goals['weeklyDistanceKm'] ?? '').toString();
      _monthlyCaloriesController.text = (goals['monthlyCalories'] ?? '').toString();
      setState(() {
        _photoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _pickedImage = File(pickedFile.path);
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(_pickedImage!);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'photoUrl': url,
    }, SetOptions(merge: true));

    setState(() {
      _photoUrl = url;
    });
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameController.text,
      'goals': {
        'weeklyDistanceKm': int.tryParse(_weeklyDistanceController.text) ?? 0,
        'monthlyCalories': int.tryParse(_monthlyCaloriesController.text) ?? 0,
      },
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  // Stream that combines user goals and activities for live goal progress updates
  Stream<Map<String, dynamic>> getGoalProgressStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDocStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    final activitiesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activities')
        .snapshots();

    return Rx.combineLatest2(userDocStream, activitiesStream,
            (DocumentSnapshot userDoc, QuerySnapshot activitiesSnapshot) {
          final data = userDoc.data() as Map<String, dynamic>? ?? {};
          final goals = data['goals'] ?? {};
          final weeklyGoal = (goals['weeklyDistanceKm'] ?? 1) as int;
          final monthlyGoal = (goals['monthlyCalories'] ?? 1) as int;

          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfMonth = DateTime(now.year, now.month, 1);

          double weeklyDistance = 0;
          int monthlyCalories = 0;

          for (var doc in activitiesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();
            if (date != null) {
              if (date.isAfter(startOfWeek)) {
                weeklyDistance += (data['distanceKm'] ?? 0).toDouble();
              }
              if (date.isAfter(startOfMonth)) {
                monthlyCalories += (data['calories'] ?? 0) as int;
              }
            }
          }

          return {
            'weekly': {'progress': weeklyDistance, 'goal': weeklyGoal.toDouble()},
            'monthly': {'progress': monthlyCalories.toDouble(), 'goal': monthlyGoal.toDouble()},
          };
        });
  }

  // Stream to listen to activity stats changes (total workouts, total calories)
  Stream<Map<String, int>> getUserStatsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activities')
        .snapshots()
        .map((snapshot) {
      int totalWorkouts = snapshot.docs.length;
      int totalCalories = 0;
      for (var doc in snapshot.docs) {
        totalCalories += (doc.data()['calories'] ?? 0) as int;
      }
      return {
        'totalWorkouts': totalWorkouts,
        'totalCalories': totalCalories,
      };
    });
  }

  Widget buildProgressChart(String label, double progress, double goal, Color color) {
    double percent = (progress / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: color,
                      value: percent * 100,
                      radius: 50,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: Colors.grey.shade300,
                      value: (1 - percent) * 100,
                      radius: 50,
                      showTitle: false,
                    ),
                  ],
                  sectionsSpace: 0,
                  centerSpaceRadius: 35,
                ),
              ),
              Text('${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('${progress.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : (_photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : const AssetImage('assets/default_avatar.png')) as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode', style: TextStyle(fontSize: 18)),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: themeProvider.toggleTheme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weeklyDistanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weekly Distance Goal (km)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _monthlyCaloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Calories Goal'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 40),

            // Stats with StreamBuilder
            StreamBuilder<Map<String, int>>(
              stream: getUserStatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading stats');
                } else if (!snapshot.hasData) {
                  return const Text('No stats available');
                }

                final stats = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Total Workouts: ${stats['totalWorkouts']}'),
                    Text('Total Calories Burned: ${stats['totalCalories']}'),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Goal progress charts with StreamBuilder for real-time updates
            StreamBuilder<Map<String, dynamic>>(
              stream: getGoalProgressStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final data = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildProgressChart('Weekly Distance', data['weekly']['progress'], data['weekly']['goal'], Colors.blue),
                    buildProgressChart('Monthly Calories', data['monthly']['progress'], data['monthly']['goal'], Colors.orange),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
