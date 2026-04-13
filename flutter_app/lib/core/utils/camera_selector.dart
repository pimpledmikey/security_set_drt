import 'package:camera/camera.dart';

CameraDescription? selectPreferredCamera(List<CameraDescription> cameras) {
  if (cameras.isEmpty) {
    return null;
  }

  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.back) {
      return camera;
    }
  }

  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.external) {
      return camera;
    }
  }

  return cameras.first;
}
