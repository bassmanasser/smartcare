import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
  // Only request on platforms where needed (Android)
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse, // Often required for BLE scanning
      ].request();

      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          debugPrint('[Permission] $permission not granted');
        }
      });
    } catch (e) {
      debugPrint("Error requesting bluetooth permissions: $e");
    }
  }
}

Future<void> requestSmsAndCallPermissions() async {
  // Only request on platforms where needed (Android/iOS)
  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
        Permission.phone,
      ].request();

      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          debugPrint('[Permission] $permission not granted');
        }
      });
    } catch (e) {
      debugPrint("Error requesting SMS/Call permissions: $e");
    }
  }
}

// New function to request notification permission
Future<void> requestNotificationPermission() async {
   // Only request on platforms where needed (Android 13+ / iOS)
  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
    final PermissionStatus status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('[Permission] Notification permission denied.');
      // Optional: Show a dialog explaining why the permission is needed
    } else if (status.isPermanentlyDenied) {
      debugPrint('[Permission] Notification permission permanently denied.');
      // Optional: Guide user to settings
      // openAppSettings();
    }
  }
}