import '../models/status_model.dart';
import 'package:path/path.dart' as path;

import '../services/storage_access_service.dart';

class FileUtils {
  static Future<bool> saveFile(String sourcePath) async {
    try {
      final status = StatusModel(
        path: sourcePath,
        dateModified: DateTime.now(),
        isVideo: path.extension(sourcePath).toLowerCase() == '.mp4',
        appSource: _determineAppSource(sourcePath),
        mediaType: path.extension(sourcePath).toLowerCase() == '.mp4'
            ? 'video'
            : 'image',
      );

      return await StorageAccessService.saveStatus(status);
    } catch (e) {
      print('Error saving file: $e');
      return false;
    }
  }

  static String _determineAppSource(String filePath) {
    return filePath.contains('w4b') ? 'WhatsApp Business' : 'WhatsApp';
  }

  static Future<List<StatusModel>> getAllStatuses() async {
    return await StorageAccessService.getAllStatuses();
  }
}
