import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static Future<void> init() async {
    // Load keys from environment variables (set via .env at build time)
    const appId = String.fromEnvironment('ONESIGNAL_APP_ID');
    const restKey = String.fromEnvironment('ONESIGNAL_REST_KEY');
    if (appId.isEmpty || restKey.isEmpty) {
      debugPrint('OneSignal: missing environment variables');
      return;
    }
    OneSignal.shared.setAppId(appId);
    // Optional: set additional configuration here
    debugPrint('OneSignal initialized');
  }
}
