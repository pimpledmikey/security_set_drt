import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../features/bootstrap/ui/splash_view.dart';
import '../features/home/ui/guard_home_view.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _showHome = false;

  void _finishSplash() {
    if (!mounted) {
      return;
    }
    setState(() => _showHome = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: _showHome
          ? GuardHomeView(key: const ValueKey('home'), cameras: widget.cameras)
          : SplashView(
              key: const ValueKey('splash'),
              onFinished: _finishSplash,
            ),
    );
  }
}
