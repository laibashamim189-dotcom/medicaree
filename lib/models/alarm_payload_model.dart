class AlarmPayloadModel {
  final String title;
  final String type;
  final String fullPayload;

  AlarmPayloadModel({
    required this.title,
    required this.type,
    required this.fullPayload,
  });

  factory AlarmPayloadModel.fromMap(Map<String, dynamic> map) {
    return AlarmPayloadModel(
      title: map['title'] ?? 'Reminder',
      type: (map['type'] ?? 'Reminder').toString(),
      fullPayload: map['fullPayload'] ?? '',
    );
  }

  String get reminderText {
    switch (type.toLowerCase()) {
      case 'medication':
        return "Time for Medication!";
      case 'measurement':
        return "Time for Measurement!";
      case 'activity':
        return "Time for Activity!";
      case 'appointment':
        return "Time for Appointment!";
      default:
        return "Time for Reminder!";
    }
  }
}