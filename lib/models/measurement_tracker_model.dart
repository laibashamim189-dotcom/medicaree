class MeasurementTrackerModel {
  final String id;
  final String patientId;
  final String category;
  final String value;
  final int? systolic;
  final int? diastolic;
  final String date;

  MeasurementTrackerModel({
    required this.id,
    required this.patientId,
    required this.category,
    required this.value,
    this.systolic,
    this.diastolic,
    required this.date,
  });

  bool get isHighRisk {
    if (category == 'Blood Pressure' && systolic != null && diastolic != null) {
      return systolic! >= 140 || diastolic! < 70;
    }
    return false;
  }

  factory MeasurementTrackerModel.fromMap(String docId, Map<String, dynamic> data) {
    return MeasurementTrackerModel(
      id: docId,
      patientId: data['patientId'] ?? '',
      category: data['category'] ?? 'Measurement',
      value: data['value'] ?? '',
      systolic: data['systolic'] as int?,
      diastolic: data['diastolic'] as int?,
      date: data['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'category': category,
      'value': value,
      'systolic': systolic,
      'diastolic': diastolic,
      'date': date,
    };
  }
}