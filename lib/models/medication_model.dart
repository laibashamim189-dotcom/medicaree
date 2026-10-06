class MedicationModel {
  final String id;
  final String userId;
  final String title;
  final String dosage;
  final List<String> times;
  final String date;
  final String type;
  final String status;
  final String frequency;
  final String stock;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.dosage,
    required this.times,
    required this.date,
    required this.type,
    required this.status,
    required this.frequency,
    required this.stock,
  });

  int get stockCount => stock.isNotEmpty ? int.tryParse(stock) ?? -1 : -1;

  factory MedicationModel.fromMap(String docId, Map<String, dynamic> data) {
    List<String> parsedTimes = [];
    if (data['times'] != null) {
      parsedTimes = List<String>.from(data['times']);
    } else if (data['time'] != null) {
      parsedTimes = [data['time'].toString()];
    }

    return MedicationModel(
      id: docId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Medicine',
      dosage: data['dosage'] ?? '',
      times: parsedTimes,
      date: data['date'] ?? '',
      type: data['type'] ?? 'medication',
      status: data['status'] ?? 'Pending',
      frequency: data['frequency'] ?? '',
      stock: data['stock'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'dosage': dosage,
      'times': times,
      'date': date,
      'type': type,
      'status': status,
      'frequency': frequency,
      'stock': stock,
    };
  }
}