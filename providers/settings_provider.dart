import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/version_checker.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _autoSave = false;
  bool _whatsappEnabled = true;
  bool _whatsappBusinessEnabled = true;

  bool get isDarkMode => _isDarkMode;
  bool get autoSave => _autoSave;
  bool get whatsappEnabled => _whatsappEnabled;
  bool get whatsappBusinessEnabled => _whatsappBusinessEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('darkMode') ?? false;
    _autoSave = _prefs.getBool('autoSave') ?? false;
    _whatsappEnabled = _prefs.getBool('whatsappEnabled') ?? true;
    _whatsappBusinessEnabled =
        _prefs.getBool('whatsappBusinessEnabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> toggleAutoSave(bool value) async {
    _autoSave = value;
    await _prefs.setBool('autoSave', value);
    notifyListeners();
  }

  Future<void> toggleWhatsapp(bool value) async {
    _whatsappEnabled = value;
    await _prefs.setBool('whatsappEnabled', value);
    notifyListeners();
  }

  Future<void> toggleWhatsappBusiness(bool value) async {
    _whatsappBusinessEnabled = value;
    await _prefs.setBool('whatsappBusinessEnabled', value);
    notifyListeners();
  }

  Future<void> openPrivacyPolicy() async {
    const url = 'https://dopedevs.blogspot.com/p/privacy-policy_21.html?m=1';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // Add this method
  Future<void> checkForUpdates(BuildContext context) async {
    await VersionChecker.checkForUpdate(context);
  }

  // Update your periodic operations or background tasks
  void startPeriodicTasks(BuildContext context) {
    // Check for updates when app is opened and every 3 days
    checkForUpdates(context);
  }
}
