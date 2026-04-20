import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitPulse Lite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final weeklySteps = <int>[];
          final weeklyCalories = <int>[];
          final weeklyHeartRate = <int>[]; // Optional: if heart rate is stored

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            weeklySteps.add(data['duration'] ?? 0); // Or from another field
            weeklyCalories.add(data['calories'] ?? 0);
            // weeklyHeartRate.add(data['heartRate'] ?? 0); // if available
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (weeklySteps.isNotEmpty)
                  _buildChartCard(
                    title: 'Activity Duration (min)',
                    maxY: 100,
                    spots: weeklySteps,
                    color: Colors.blue,
                    leftInterval: 20,
                    unit: 'min',
                  ),
                const SizedBox(height: 24),
                if (weeklyCalories.isNotEmpty)
                  _buildChartCard(
                    title: 'Calories Burned',
                    maxY: 500,
                    spots: weeklyCalories,
                    color: Colors.orange,
                    leftInterval: 100,
                    unit: 'cal',
                  ),
                // Add more if heart rate or other data is available
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required double maxY,
    required List<int> spots,
    required Color color,
    required double leftInterval,
    required String unit,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final day = days[value.toInt() % days.length];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(day),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: leftInterval,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()} $unit', style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(spots.length, (i) => FlSpot(i.toDouble(), spots[i].toDouble())),
                      isCurved: true,
                      barWidth: 3,
                      color: color,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
