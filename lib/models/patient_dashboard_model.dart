class PatientUserProfile {
  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl;

  PatientUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  factory PatientUserProfile.fromFirestore(String uid, Map<String, dynamic>? data) {
    if (data == null) {
      return PatientUserProfile(
        uid: uid,
        name: "Medicare User",
        email: "Managing your health",
      );
    }
    return PatientUserProfile(
      uid: uid,
      name: data['name'] ?? "Medicare User",
      email: data['email'] ?? "Managing your health",
      profileImageUrl: data['profileImageUrl'],
    );
  }
}

class DashboardNotificationItem {
  final String docId;
  final String fromId;
  final String? chatId;
  final String title;
  final String body;
  final String type;

  DashboardNotificationItem({
    required this.docId,
    required this.fromId,
    this.chatId,
    required this.title,
    required this.body,
    required this.type,
  });

  factory DashboardNotificationItem.fromFirestore(String docId, Map<String, dynamic> data) {
    return DashboardNotificationItem(
      docId: docId,
      fromId: (data['fromId'] ?? data['senderId'] ?? "").toString().trim().toLowerCase(),
      chatId: data['chatId']?.toString().toLowerCase(),
      title: data['title'] ?? "New Alert",
      body: data['body'] ?? "",
      type: data['type'] ?? "",
    );
  }
}