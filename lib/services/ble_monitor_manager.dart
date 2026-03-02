import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'ble_foreground_service.dart';

class BleMonitorManager {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ble_monitor',
        channelName: 'BLE Monitor',
        channelDescription: 'Keeps BLE monitoring active in background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
      
      // (اختياري) لو النسخة عندك بتدعمها:
      // printDevLog: true,
    );
  }

  static Future<void> start({
    required String patientId,
    required String deviceId,
  }) async {
    // ✅ لازم await
    await FlutterForegroundTask.saveData(
      key: 'bleData',
      value: {
        'patientId': patientId,
        'deviceId': deviceId,
      },
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'SmartCare BLE Monitor',
      notificationText: 'Monitoring BLE connection...',
      callback: startCallback, // ✅ top-level function
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

/// ✅ لازم تكون Top-level + entry-point
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BleFgTaskHandler());
}
