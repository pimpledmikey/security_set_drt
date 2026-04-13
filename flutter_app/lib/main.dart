import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(RunwayAccessApp(cameras: cameras));
}
