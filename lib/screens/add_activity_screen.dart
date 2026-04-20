import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddActivityScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData; // For editing existing activity

  const AddActivityScreen({Key? key, this.initialData}) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedActivity;
  final List<String> _activities = ['Running', 'Cycling', 'Walking', 'Swimming', 'Yoga'];
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      _selectedActivity = widget.initialData!['type'];
      _durationController.text = widget.initialData!['duration'].toString();
      _caloriesController.text = widget.initialData!['calories'].toString();

      // Firestore stores date as Timestamp, convert to DateTime
      if (widget.initialData!['date'] is Timestamp) {
        _selectedDate = (widget.initialData!['date'] as Timestamp).toDate();
      } else if (widget.initialData!['date'] is DateTime) {
        _selectedDate = widget.initialData!['date'];
      } else {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'type': _selectedActivity,
        'duration': int.parse(_durationController.text),
        'calories': int.parse(_caloriesController.text),
        'date': _selectedDate,
      });
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Add New Activity' : 'Edit Activity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Activity Type'),
                value: _selectedActivity,
                items: _activities
                    .map((act) => DropdownMenuItem(
                  value: act,
                  child: Text(act),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedActivity = val),
                validator: (val) => val == null ? 'Please select an activity' : null,
              ),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter duration';
                  if (int.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories Burned'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter calories burned';
                  if (int.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Date: '),
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.initialData == null ? 'Add Activity' : 'Update Activity'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
