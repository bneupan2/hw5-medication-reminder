import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  List<IntakeLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _storage.loadLogs();
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear history?"),
        content: const Text("This will remove all intake logs."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _logs.clear();
    await _storage.saveLogs(_logs);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("History cleared")));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History Log"),
        actions: [
          IconButton(
            tooltip: "Clear",
            onPressed: _logs.isEmpty ? null : _clearHistory,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(
              child: Text("No history yet. Mark a medication as taken."),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(log.medName),
                    subtitle: Text(
                      "Dosage: ${log.dosage}\nTaken: ${log.takenLabel}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
