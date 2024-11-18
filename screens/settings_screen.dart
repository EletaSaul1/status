import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';
import '../utils/permission_handler.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _checkPermissions(BuildContext context) async {
    final hasAccess = await StoragePermissionHandler.hasStorageAccess();
    if (!hasAccess) {
      await StoragePermissionHandler.requestAllPermissions();
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasAccess
              ? 'Storage permissions are granted'
              : 'Storage permissions required',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => ListView(
          children: [
            _buildSection(
              title: 'App Settings',
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark theme'),
                  value: settings.isDarkMode,
                  onChanged: settings.toggleDarkMode,
                ),
                SwitchListTile(
                  title: const Text('Auto-save New Statuses'),
                  subtitle: const Text('Automatically save new statuses'),
                  value: settings.autoSave,
                  onChanged: settings.toggleAutoSave,
                ),
              ],
            ),
            _buildSection(
              title: 'Supported Apps',
              children: [
                SwitchListTile(
                  title: const Text('WhatsApp'),
                  value: settings.whatsappEnabled,
                  onChanged: settings.toggleWhatsapp,
                ),
                SwitchListTile(
                  title: const Text('WhatsApp Business'),
                  value: settings.whatsappBusinessEnabled,
                  onChanged: settings.toggleWhatsappBusiness,
                ),
              ],
            ),
            _buildSection(
              title: 'Permissions',
              children: [
                ListTile(
                  title: const Text('Storage Access'),
                  subtitle: const Text('Required for saving statuses'),
                  trailing: TextButton(
                    onPressed: () => _checkPermissions(context),
                    child: const Text('Check'),
                  ),
                ),
              ],
            ),
            _buildSection(
              title: 'About',
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListTile(
                        title: const Text('Version'),
                        subtitle: Text(snapshot.data!.version),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                ListTile(
                  title: const Text('Check for Updates'),
                  onTap: () => settings.checkForUpdates(context),
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  onTap: () => settings.openPrivacyPolicy(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}
