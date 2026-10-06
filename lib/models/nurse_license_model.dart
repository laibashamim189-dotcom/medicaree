class NurseLicenseModel {
  final String uid;
  final String licenseNumber;
  final String? certificateUrl;
  final String status;

  NurseLicenseModel({
    required this.uid,
    required this.licenseNumber,
    this.certificateUrl,
    required this.status,
  });

  bool get isEditable => status == 'NOT_SUBMITTED' || status == 'REJECTED';
  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';

  factory NurseLicenseModel.fromFirestore(String uid, Map<String, dynamic>? data) {
    if (data == null) {
      return NurseLicenseModel(
        uid: uid,
        licenseNumber: '',
        certificateUrl: null,
        status: 'NOT_SUBMITTED',
      );
    }

    final rawStatus = (data['licenseStatus'] ?? 'NOT_SUBMITTED').toString().toUpperCase().trim();

    return NurseLicenseModel(
      uid: uid,
      licenseNumber: data['nursingLicenseNumber'] ?? '',
      certificateUrl: data['certificateUrl'],
      status: rawStatus,
    );
  }
}