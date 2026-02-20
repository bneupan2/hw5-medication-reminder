class Medication {
  final String id;
  String name;
  String dosage; // e.g. "500 mg", "1 tablet"
  String frequency; // e.g. "Once daily", "Twice daily", "As needed"
  int hour; // 0-23
  int minute; // 0-59
  bool active;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.hour,
    required this.minute,
    this.active = true,
  });

  String get timeLabel {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour >= 12 ? "PM" : "AM";
    final mm = minute.toString().padLeft(2, '0');
    return "$h12:$mm $ampm";
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "dosage": dosage,
    "frequency": frequency,
    "hour": hour,
    "minute": minute,
    "active": active,
  };

  static Medication fromJson(Map<String, dynamic> json) => Medication(
    id: json["id"] as String,
    name: (json["name"] as String?) ?? "",
    dosage: (json["dosage"] as String?) ?? "",
    frequency: (json["frequency"] as String?) ?? "Once daily",
    hour: (json["hour"] as num?)?.toInt() ?? 9,
    minute: (json["minute"] as num?)?.toInt() ?? 0,
    active: (json["active"] as bool?) ?? true,
  );
}

class IntakeLog {
  final String id;
  final String medId;
  final String medName;
  final String dosage;
  final DateTime takenAt;

  IntakeLog({
    required this.id,
    required this.medId,
    required this.medName,
    required this.dosage,
    required this.takenAt,
  });

  String get takenLabel {
    final m = takenAt.minute.toString().padLeft(2, '0');
    final h = takenAt.hour;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h >= 12 ? "PM" : "AM";
    return "${takenAt.month}/${takenAt.day}/${takenAt.year}  $h12:$m $ampm";
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "medId": medId,
    "medName": medName,
    "dosage": dosage,
    "takenAt": takenAt.toIso8601String(),
  };

  static IntakeLog fromJson(Map<String, dynamic> json) => IntakeLog(
    id: json["id"] as String,
    medId: json["medId"] as String,
    medName: (json["medName"] as String?) ?? "",
    dosage: (json["dosage"] as String?) ?? "",
    takenAt: DateTime.parse(json["takenAt"] as String),
  );
}
