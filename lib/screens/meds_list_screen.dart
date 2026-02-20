import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import 'add_edit_med_screen.dart';
import 'history_screen.dart';

class MedsListScreen extends StatefulWidget {
  const MedsListScreen({super.key});

  @override
  State<MedsListScreen> createState() => _MedsListScreenState();
}

class _MedsListScreenState extends State<MedsListScreen> {
  final _storage = StorageService();
  List<Medication> _meds = [];
  List<IntakeLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final meds = await _storage.loadMeds();
    final logs = await _storage.loadLogs();
    setState(() {
      _meds = meds;
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditMedScreen()),
    );
    if (created == true) {
      await _loadAll();
    }
  }

  Future<void> _openEdit(Medication med) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditMedScreen(existing: med)),
    );
    if (updated == true) {
      await _loadAll();
    }
  }

  Future<void> _deleteMed(Medication med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete medication?"),
        content: Text("Delete “${med.name}” and keep its history log?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _meds.removeWhere((m) => m.id == med.id);
    await _storage.saveMeds(_meds);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Deleted ${med.name}")));
    }
    setState(() {});
  }

  Future<void> _logTaken(Medication med) async {
    final log = IntakeLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      medId: med.id,
      medName: med.name,
      dosage: med.dosage,
      takenAt: DateTime.now(),
    );

    _logs.insert(0, log);
    await _storage.saveLogs(_logs);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logged: ${med.name} taken")));
    }
    setState(() {});
  }

  int _takenCountForMed(String medId) =>
      _logs.where((l) => l.medId == medId).length;

  @override
  Widget build(BuildContext context) {
    final activeMeds = _meds.where((m) => m.active).toList()
      ..sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication Reminder + Log"),
        actions: [
          IconButton(
            tooltip: "History",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              await _loadAll(); // refresh after potential clear
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : activeMeds.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: activeMeds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final med = activeMeds[index];
                  final takenCount = _takenCountForMed(med.id);

                  return Dismissible(
                    key: ValueKey(med.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _deleteMed(med);
                      return false; // we handle deletion ourselves
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete),
                    ),
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: "Edit",
                                  onPressed: () => _openEdit(med),
                                  icon: const Icon(Icons.edit),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chip(Icons.medication, med.dosage),
                                _chip(Icons.schedule, med.timeLabel),
                                _chip(Icons.repeat, med.frequency),
                                _chip(Icons.check_circle, "Taken: $takenCount"),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _logTaken(med),
                                    icon: const Icon(Icons.check),
                                    label: const Text("Mark as Taken"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_outlined, size: 64),
            const SizedBox(height: 12),
            const Text(
              "No medications yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap + to add your first medication.\nYou can mark it as taken and view history.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _openAdd,
              icon: const Icon(Icons.add),
              label: const Text("Add Medication"),
            ),
          ],
        ),
      ),
    );
  }
}
