import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';

class PackageCaptureView extends StatefulWidget {
  const PackageCaptureView({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<PackageCaptureView> createState() => _PackageCaptureViewState();
}

class _PackageCaptureViewState extends State<PackageCaptureView> {
  late final CameraController _controller;
  bool _loading = true;
  bool _capturing = false;
  Offset? _focusIndicatorPosition;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _init();
  }

  Future<void> _init() async {
    await _controller.initialize();
    try {
      await _controller.setFlashMode(FlashMode.off);
      await _controller.setFocusMode(FocusMode.auto);
      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setFocusPoint(const Offset(0.5, 0.5));
      await _controller.setExposurePoint(const Offset(0.5, 0.5));
    } catch (_) {
      // Device-specific camera controls may fail.
    }

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _focusAt(Offset localPosition, Size size) async {
    if (_loading || _capturing || !_controller.value.isInitialized) {
      return;
    }

    final normalizedPoint = Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0),
      (localPosition.dy / size.height).clamp(0.0, 1.0),
    );

    setState(() => _focusIndicatorPosition = localPosition);
    try {
      await _controller.setFocusMode(FocusMode.auto);
      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setFocusPoint(normalizedPoint);
      await _controller.setExposurePoint(normalizedPoint);
    } catch (_) {
      // Some devices ignore manual focus points.
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    setState(() => _focusIndicatorPosition = null);
  }

  Future<void> _capture() async {
    if (_capturing || !_controller.value.isInitialized) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await _controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(base64Encode(bytes));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppFeedback(
        context,
        'No se pudo tomar la foto del paquete.',
        tone: AppFeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Fotografiar paquete')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) =>
                          _focusAt(details.localPosition, constraints.biggest),
                      child: CameraPreview(_controller),
                    ),
                    if (_focusIndicatorPosition != null)
                      Positioned(
                        left: _focusIndicatorPosition!.dx - 24,
                        top: _focusIndicatorPosition!.dy - 24,
                        child: IgnorePointer(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 1.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: _capturing
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Regresar'),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xB814223A),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text('Toca para enfocar'),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 14),
                              decoration: BoxDecoration(
                                color: const Color(0xC814223A),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Toma la evidencia del paquete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Usa una foto clara. Si necesitas otro ángulo o vienen varias piezas, puedes tomar más fotos después.',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _capturing ? null : _capture,
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(58),
                                        backgroundColor:
                                            AppColors.packageAccent,
                                      ),
                                      icon: _capturing
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_rounded),
                                      label: Text(
                                        _capturing
                                            ? 'Procesando...'
                                            : 'Tomar foto',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
