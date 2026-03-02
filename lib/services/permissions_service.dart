import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  
  // طلب صلاحيات البلوتوث والموقع (للأندرويد)
  static Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ (API 31+)
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // مطلوب للمسح في بعض الإصدارات
      ].request();

      return statuses.values.every((status) => status.isGranted);
    }
    return true; // iOS يتعامل معها تلقائياً غالباً عند الاستخدام
  }

  // طلب صلاحيات الإشعارات (Android 13+)
  static Future<bool> requestNotificationPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }
}