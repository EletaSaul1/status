import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/status_model.dart';
import '../providers/status_provider.dart';
import '../widgets/video_player_widget.dart';
import '../services/ad_manager.dart';

class StatusViewerScreen extends StatefulWidget {
  final StatusModel status;

  const StatusViewerScreen({super.key, required this.status});

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  final AdManager _adManager = AdManager();
  late BannerAd _bannerAd;
  bool _isSaving = false;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAds();
  }

  Future<void> _initAds() async {
    _bannerAd = AdManager.createBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() => _isBannerAdLoaded = true);
        }
      },
      onAdFailedToLoad: (error) {
        print('Banner ad failed to load: $error');
      },
    );
    _bannerAd.load();

    await _adManager.initialize();

    if (Random().nextDouble() < 0.3) {
      await _adManager.tryToShowInterstitialAd();
    }
  }

  Future<void> _saveStatus(BuildContext context) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<StatusProvider>(context, listen: false);
      final success = await provider.saveStatus(widget.status);

      if (!mounted) return;

      final bannerHeight = _isBannerAdLoaded ? 60.0 : 0.0;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Status saved successfully!' : 'Failed to save status',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: bannerHeight + 10,
              left: 20,
              right: 20,
            ),
          ),
        );

      if (Random().nextBool()) {
        await _adManager.tryToShowInterstitialAd();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _saveStatus(context),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Hero(
                    tag: widget.status.path,
                    child: widget.status.isVideo
                        ? VideoPlayerWidget(videoPath: widget.status.path)
                        : InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(File(widget.status.path)),
                          ),
                  ),
                ),
              ),
              if (_isBannerAdLoaded)
                Container(
                  alignment: Alignment.bottomCenter,
                  width: MediaQuery.of(context).size.width,
                  height: 60,
                  color: Colors.black54,
                  child: AdWidget(ad: _bannerAd),
                ),
            ],
          ),
          Positioned(
            bottom: _isBannerAdLoaded ? 70 : 10,
            left: 0,
            right: 0,
            child: Container(height: 0),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _adManager.dispose();
    super.dispose();
  }
}
