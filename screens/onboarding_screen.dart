import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/permission_handler.dart';
import 'home_screen.dart';
import '../services/ad_manager.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AdManager _adManager = AdManager();
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    await _adManager.initialize();
    _isAdLoaded = await _adManager.tryToShowInterstitialAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Welcome to Status Saver Pro",
            body:
                "Save and manage status updates from your favorite messaging apps",
            image: _buildImage("assets/images/welcome.png"),
            decoration: _getPageDecoration(),
          ),
          PageViewModel(
            title: "Multiple App Support",
            body: "Save statuses from WhatsApp and WhatsApp Business",
            image: _buildImage("assets/images/apps.png"),
            decoration: _getPageDecoration(),
          ),
          PageViewModel(
            title: "Important Permission Required",
            body:
                "This app needs special storage permission to access statuses on Android 11 and above.\n\n"
                "We need this permission to:\n"
                "• View WhatsApp status images and videos\n"
                "• Save statuses to your gallery\n"
                "• Ensure proper app functionality\n\n"
                "You can grant this permission in the next steps.",
            image: _buildImage("assets/images/permissions.png"),
            decoration: _getPageDecoration(),
            footer: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _requestDirectoryAccess(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Grant Permissions"),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
        onDone: () => _finishOnboarding(context),
        showNextButton: true,
        next: const Icon(Icons.arrow_forward),
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
        skip: const Text("Skip"),
        showSkipButton: true,
        dotsDecorator: DotsDecorator(
          size: const Size(10, 10),
          color: Colors.grey,
          activeSize: const Size(22, 10),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => Container(
          height: 0,
          margin: const EdgeInsets.only(bottom: 100),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImage(String path) {
    return Center(
      child: Image.asset(path, width: 200),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 16),
      bodyPadding: EdgeInsets.all(16),
      imagePadding: EdgeInsets.all(24),
    );
  }

  Future<void> _requestDirectoryAccess(BuildContext context) async {
    final hasAccess = await StoragePermissionHandler.requestAllPermissions();
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hasAccess
                ? 'Storage access granted successfully!'
                : 'Storage access denied. Some features may not work.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: 100,
            left: 20,
            right: 20,
          ),
        ),
      );
  }

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }
}
