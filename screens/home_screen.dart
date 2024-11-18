import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/status_provider.dart';
import '../services/version_checker.dart';
import '../utils/permission_handler.dart';
import '../widgets/status_grid.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeApp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionChecker.checkForUpdate(context);
      VersionChecker.startPeriodicChecks(context);
    });
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);

    try {
      final hasAccess = await StoragePermissionHandler.hasStorageAccess();
      if (!mounted) return;

      if (!hasAccess) {
        final granted = await StoragePermissionHandler.requestAllPermissions();
        if (!mounted) return;
        setState(() => _hasPermission = granted);

        if (granted) {
          await context.read<StatusProvider>().loadStatuses();
        }
      } else {
        setState(() => _hasPermission = true);
        await context.read<StatusProvider>().loadStatuses();
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatuses() async {
    await context.read<StatusProvider>().loadStatuses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Saver Plus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatuses,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Images'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          StatusGrid(mediaType: 'image'),
          StatusGrid(mediaType: 'video'),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Directory Access Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app needs access to the WhatsApp status directory to save your statuses.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializeApp,
                  icon: const Icon(Icons.folder),
                  label: const Text('Grant Access'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    VersionChecker.stopPeriodicChecks();
    super.dispose();
  }
}
