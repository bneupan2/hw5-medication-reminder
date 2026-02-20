import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

class StorageService {
  static const _medsKey = "medications";
  static const _logsKey = "intake_logs";

  Future<List<Medication>> loadMeds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_medsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<dynamic>();
    return list
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMeds(List<Medication> meds) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(meds.map((m) => m.toJson()).toList());
    await prefs.setString(_medsKey, raw);
  }

  Future<List<IntakeLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<dynamic>();
    final logs = list
        .map((e) => IntakeLog.fromJson(e as Map<String, dynamic>))
        .toList();
    // newest first
    logs.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return logs;
  }

  Future<void> saveLogs(List<IntakeLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(logs.map((l) => l.toJson()).toList());
    await prefs.setString(_logsKey, raw);
  }
}
