import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 80,
    this.height = 80,
    this.pngAsset160 = 'assets/images/runway_logo_160.png',
    this.pngAsset48 = 'assets/images/runway_logo_48.png',
  });

  final double width;
  final double height;
  final String pngAsset160;
  final String pngAsset48;

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chosen = width > 64 ? pngAsset160 : pngAsset48;
    return FutureBuilder<bool>(
      future: _assetExists(chosen),
      builder: (context, snapshot) {
        final exists = snapshot.data == true;
        if (exists) {
          return Image.asset(
            chosen,
            width: width,
            height: height,
            fit: BoxFit.contain,
          );
        }

        // Fallback to Lottie animation included in the project
        return Lottie.asset(
          'assets/lottie/runway_logo.json',
          width: width,
          height: height,
          repeat: true,
          fit: BoxFit.contain,
        );
      },
    );
  }
}
