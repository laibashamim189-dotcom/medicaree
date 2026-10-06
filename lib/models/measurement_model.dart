class MeasurementModel {
  final String id;
  final String userId;
  final String title;
  final String type;
  final String date;
  final List<String> times;
  final String frequency;
  final String status;

  MeasurementModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.date,
    required this.times,
    required this.frequency,
    required this.status,
  });

  factory MeasurementModel.fromMap(String docId, Map<String, dynamic> data) {
    List<String> timesList = [];
    if (data['times'] != null) {
      timesList = List<String>.from(data['times']);
    } else if (data['time'] != null) {
      timesList = [data['time'].toString()];
    }

    return MeasurementModel(
      id: docId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Measurement',
      type: data['type'] ?? 'measurement',
      date: data['date'] ?? '',
      times: timesList,
      frequency: data['frequency'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'type': type,
      'date': date,
      'times': times,
      'frequency': frequency,
      'status': status,
    };
  }
}