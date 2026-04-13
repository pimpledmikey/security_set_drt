import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RunwayLogoLottie extends StatelessWidget {
  const RunwayLogoLottie({super.key, this.width = 80, this.height = 80});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/runway_logo.json',
      width: width,
      height: height,
      repeat: true,
      fit: BoxFit.contain,
    );
  }
}
