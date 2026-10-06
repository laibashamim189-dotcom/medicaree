import 'package:flutter/material.dart';
import '../models/alarm_payload_model.dart';
import '../services/notification_service.dart';

class AlarmViewModel extends ChangeNotifier {
  AlarmPayloadModel? _payloadModel;
  AlarmPayloadModel? get payloadModel => _payloadModel;

  String? _pendingAction; // 'action_taken' or 'action_missed'
  String? get pendingAction => _pendingAction;

  void initPayload(Map<String, dynamic> payloadMap) {
    _payloadModel = AlarmPayloadModel.fromMap(payloadMap);
    _pendingAction = null;
    notifyListeners();
  }

  void setPendingAction(String? action) {
    _pendingAction = action;
    notifyListeners();
  }

  void submitAction(String performedBy) {
    if (_payloadModel != null && _pendingAction != null) {
      NotificationService.handleActionLogic(
        _payloadModel!.fullPayload,
        _pendingAction,
        performedBy: performedBy,
      );
    }
  }
}