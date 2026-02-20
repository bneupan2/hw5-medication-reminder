import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';

class AddEditMedScreen extends StatefulWidget {
  final Medication? existing;
  const AddEditMedScreen({super.key, this.existing});

  @override
  State<AddEditMedScreen> createState() => _AddEditMedScreenState();
}

class _AddEditMedScreenState extends State<AddEditMedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _frequency = "Once daily";
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _active = true;

  final List<String> _freqOptions = const [
    "Once daily",
    "Twice daily",
    "Three times daily",
    "Weekly",
    "As needed",
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.existing;
    if (med != null) {
      _nameCtrl.text = med.name;
      _dosageCtrl.text = med.dosage;
      _frequency = med.frequency;
      _time = TimeOfDay(hour: med.hour, minute: med.minute);
      _active = med.active;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final meds = await _storage.loadMeds();

    if (widget.existing == null) {
      final med = Medication(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        frequency: _frequency,
        hour: _time.hour,
        minute: _time.minute,
        active: _active,
      );
      meds.add(med);
    } else {
      final idx = meds.indexWhere((m) => m.id == widget.existing!.id);
      if (idx >= 0) {
        meds[idx].name = _nameCtrl.text.trim();
        meds[idx].dosage = _dosageCtrl.text.trim();
        meds[idx].frequency = _frequency;
        meds[idx].hour = _time.hour;
        meds[idx].minute = _time.minute;
        meds[idx].active = _active;
      }
    }

    await _storage.saveMeds(meds);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Medication" : "Add Medication"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Medication name",
                  hintText: "e.g., Amoxicillin",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Name is required";
                  if (v.trim().length < 2) return "Name too short";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: "Dosage",
                  hintText: "e.g., 500 mg / 1 tablet",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return "Dosage is required";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _frequency,
                items: _freqOptions
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
                decoration: const InputDecoration(
                  labelText: "Frequency",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Time picker
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Reminder time",
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule),
                      const SizedBox(width: 10),
                      Text(_time.format(context)),
                      const Spacer(),
                      const Icon(Icons.edit),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text("Active"),
                subtitle: const Text("If off, it won’t show on the main list"),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? "Save Changes" : "Add Medication"),
              ),
              const SizedBox(height: 8),
              Text(
                "Tip: Mark meds as taken from the home screen to build your history log.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
