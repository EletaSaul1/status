import 'dart:async';
import 'package:flutter/services.dart';
import '../models/status_model.dart';
import 'channel_service.dart';
import '../utils/permission_handler.dart';

class StorageAccessService {
  static const MethodChannel _channel = MethodChannel(ChannelService.storage);

  /// Get all statuses from both WhatsApp and WhatsApp Business
  static Future<List<StatusModel>> getAllStatuses() async {
    // First check/request permissions
    final hasAccess = await StoragePermissionHandler.hasStorageAccess();
    if (!hasAccess) {
      final granted = await StoragePermissionHandler.requestAllPermissions();
      if (!granted) return [];
    }

    final List<StatusModel> statuses = [];

    try {
      // Get regular WhatsApp statuses
      final whatsappStatuses = await _getStatusesForApp(false);
      statuses.addAll(whatsappStatuses);

      // Get WhatsApp Business statuses
      final businessStatuses = await _getStatusesForApp(true);
      statuses.addAll(businessStatuses);

      // Sort by date modified
      statuses.sort((a, b) => b.dateModified.compareTo(a.dateModified));
    } catch (e) {
      print('Error getting all statuses: $e');
    }

    return statuses;
  }

  /// Get statuses for specific WhatsApp variant
  static Future<List<StatusModel>> _getStatusesForApp(
      bool isBusinessWhatsApp) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getStatuses', {
        'isBusinessWhatsApp': isBusinessWhatsApp,
      });

      if (result == null) return [];

      return result
          .map((item) => StatusModel(
                path: item['path'],
                dateModified:
                    DateTime.fromMillisecondsSinceEpoch(item['dateModified']),
                isVideo: item['isVideo'],
                appSource:
                    isBusinessWhatsApp ? 'WhatsApp Business' : 'WhatsApp',
                mediaType: item['isVideo'] ? 'video' : 'image',
              ))
          .toList();
    } catch (e) {
      print('Error getting statuses: $e');
      return [];
    }
  }

  /// Save status to device
  static Future<bool> saveStatus(StatusModel status) async {
    try {
      final result = await _channel.invokeMethod('saveStatus', {
        'uri': status.path,
        'isVideo': status.isVideo,
        'fileName': _generateFileName(status),
        'appSource': status.appSource,
      });

      return result ?? false;
    } catch (e) {
      print('Error saving status: $e');
      return false;
    }
  }

  /// Generate a unique filename for saving
  static String _generateFileName(StatusModel status) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _getExtension(status.path, status.isVideo);
    final prefix = status.isVideo ? 'VID' : 'IMG';
    return '${prefix}_STATUS_$timestamp$extension';
  }

  /// Extract file extension from path
  static String _getExtension(String path, bool isVideo) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return isVideo ? '.mp4' : '.jpg';
    return path.substring(lastDot);
  }

  /// Check if a file exists
  static Future<bool> checkFileExists(String path) async {
    try {
      final result =
          await _channel.invokeMethod('checkFileExists', {'path': path});
      return result ?? false;
    } catch (e) {
      print('Error checking file existence: $e');
      return false;
    }
  }
}
