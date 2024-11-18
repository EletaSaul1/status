import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';

class VersionChecker {
  static const String PLAY_STORE_URL =
      'https://play.google.com/store/apps/details?id=';
  static const String APP_ID = 'com.allwhtsappstatus_saver';
  static const Duration CHECK_INTERVAL = Duration(hours: 6);
  static Timer? _periodicTimer;

  static void startPeriodicChecks(BuildContext context) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(CHECK_INTERVAL, (_) {
      checkForUpdate(context);
    });
  }

  static void stopPeriodicChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final updateAvailable = await _checkVersionInBackground();
      if (updateAvailable != null && context.mounted) {
        _showForceUpdateDialog(
          context,
          updateAvailable.storeVersion,
          updateAvailable.currentVersion,
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static Future<UpdateInfo?> _checkVersionInBackground() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = Uri.parse(
          'https://play.google.com/store/apps/details?id=${packageInfo.packageName}');
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final storeVersion = _extractVersionFromPlayStore(response.body);

      if (storeVersion != null && _shouldUpdate(currentVersion, storeVersion)) {
        return UpdateInfo(currentVersion, storeVersion);
      }
    } catch (e) {
      debugPrint('Background version check error: $e');
    }
    return null;
  }

  static String? _extractVersionFromPlayStore(String html) {
    try {
      final RegExp regex = RegExp(r'Current Version.*?>(.*?)<');
      final match = regex.firstMatch(html);
      return match?.group(1)?.trim();
    } catch (e) {
      debugPrint('Error extracting version: $e');
      return null;
    }
  }

  static bool _shouldUpdate(String currentVersion, String storeVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> store = storeVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < current.length && i < store.length; i++) {
        if (store[i] > current[i]) return true;
        if (current[i] > store[i]) return false;
      }
      return store.length > current.length;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  static Future<void> _launchPlayStore() async {
    final url = Uri.parse('$PLAY_STORE_URL$APP_ID');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching Play Store: $e');
    }
  }

  static Widget _buildVersionRow({
    required String currentVersion,
    required String newVersion,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Version',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentVersion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Version',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  newVersion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showForceUpdateDialog(
    BuildContext context,
    String newVersion,
    String currentVersion,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glassmorphic Header
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Update Required',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content with frosted glass effect
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'A new version of Status Saver Plus is available.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildVersionRow(
                            currentVersion: currentVersion,
                            newVersion: newVersion,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This version is no longer supported. Please update to continue using the app.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Update Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 8,
                              shadowColor: Colors.red.withOpacity(0.5),
                            ),
                            onPressed: () => _launchPlayStore(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.system_update, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Update Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'The app will not work until updated',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateInfo {
  final String currentVersion;
  final String storeVersion;

  UpdateInfo(this.currentVersion, this.storeVersion);
}
