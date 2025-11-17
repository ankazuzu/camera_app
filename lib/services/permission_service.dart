import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  /// Requests camera and location permissions
  /// Returns true if all permissions are granted
  Future<bool> requestPermissions() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    
    // Request location permission
    final locationStatus = await Permission.location.request();
    
    // Check if both permissions are granted
    return cameraStatus.isGranted && locationStatus.isGranted;
  }

  /// Checks if all required permissions are granted
  Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    
    return cameraStatus.isGranted && locationStatus.isGranted;
  }

  /// Opens app settings if permissions are denied
  Future<void> openSettings() async {
    await openAppSettings();
  }
}

