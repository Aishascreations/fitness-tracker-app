import 'package:flutter/material.dart';
import 'add_activity_screen.dart';
import '../services/firestore_service.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  IconData _getIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'walking':
        return Icons.directions_walk;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getActivitiesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No activities logged yet.'));
          }
          final activities = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              // Convert Firestore Timestamp to DateTime if needed
              final date = activity['date'] is DateTime
                  ? activity['date']
                  : (activity['date'] as dynamic).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: Icon(_getIcon(activity['type']), color: Colors.blue),
                  title: Text(activity['type']),
                  subtitle: Text(
                    'Date: ${formatDate(date)}\nDuration: ${activity['duration']} mins\nCalories: ${activity['calories']} cal',
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    // Open AddActivityScreen with initial data for editing
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddActivityScreen(
                          initialData: activity,
                        ),
                      ),
                    );

                    if (result != null) {
                      await _firestoreService.updateActivity(activity['id'], result);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activity updated!')),
                      );
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Activity?'),
                          content: const Text('Are you sure you want to delete this activity?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _firestoreService.deleteActivity(activity['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Activity deleted!')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddActivityScreen()),
          );

          if (result != null) {
            await _firestoreService.addActivity(result);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Activity added!')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
