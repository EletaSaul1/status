import 'package:flutter/services.dart';
import '../services/channel_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class StoragePermissionHandler {
  static const platform = MethodChannel(ChannelService.storage);
  static bool? _hasStorageAccess;

  /// Check if we have necessary storage permissions
  static Future<bool> hasStorageAccess() async {
    if (_hasStorageAccess != null) return _hasStorageAccess!;

    try {
      final result = await platform.invokeMethod('checkStorageAccess');
      _hasStorageAccess = result ?? false;
      debugPrint('Storage access check result: $_hasStorageAccess');
      return _hasStorageAccess!;
    } on PlatformException catch (e) {
      debugPrint('Error checking storage access: $e');
      return false;
    }
  }

  /// Request directory access through SAF
  static Future<bool> requestDirectoryAccess(
      {bool isBusinessWhatsApp = false}) async {
    try {
      debugPrint('Requesting directory access...');
      final result = await platform.invokeMethod('requestDirectoryAccess', {
        'isBusinessWhatsApp': isBusinessWhatsApp,
      });

      _hasStorageAccess = result ?? false;
      debugPrint('Directory access request result: $_hasStorageAccess');
      return _hasStorageAccess!;
    } on PlatformException catch (e) {
      debugPrint('Error requesting directory access: $e');
      return false;
    }
  }

  /// Request all necessary permissions
  static Future<bool> requestAllPermissions() async {
    debugPrint('Requesting all permissions...');
    if (!Platform.isAndroid) return false;

    try {
      // Simple single method call that handles all permission logic on Android side
      final result = await platform.invokeMethod('requestAllPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting all permissions: $e');
      return false;
    }
  }

  /// Clear cached permissions
  static void clearCache() {
    _hasStorageAccess = null;
  }
}

// For backward compatibility
Future<bool> requestDirectoryAccess() async {
  return StoragePermissionHandler.requestAllPermissions();
}
