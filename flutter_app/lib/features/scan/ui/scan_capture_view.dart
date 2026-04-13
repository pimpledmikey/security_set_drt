import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../data/scan_service.dart';
import '../models/scan_frame_config.dart';

class ScanCaptureView extends StatefulWidget {
  const ScanCaptureView({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<ScanCaptureView> createState() => _ScanCaptureViewState();
}

class _ScanCaptureViewState extends State<ScanCaptureView> {
  late final CameraController _controller;
  bool _loading = true;
  bool _processing = false;
  ScanDocumentPreset _preset = ScanDocumentPreset.credential;
  ScanFrameOrientation _orientation = ScanFrameOrientation.auto;
  Offset? _focusIndicatorPosition;

  ScanFrameConfig get _frameConfig => ScanFrameConfig(
        preset: _preset,
        orientation: _orientation,
      );

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
      // Some devices do not support all tuning options.
    }
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _focusAt(Offset localPosition, Size size) async {
    if (_loading || _processing || !_controller.value.isInitialized) {
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

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    setState(() => _focusIndicatorPosition = null);
  }

  Future<void> _capture() async {
    if (_processing || !_controller.value.isInitialized) {
      return;
    }

    setState(() => _processing = true);
    final scanService = context.read<ScanService>();
    try {
      try {
        await _controller.setFocusPoint(const Offset(0.5, 0.5));
        await _controller.setExposurePoint(const Offset(0.5, 0.5));
        await Future<void>.delayed(const Duration(milliseconds: 120));
      } catch (_) {
        // Ignore camera tuning failures and continue with capture.
      }

      final file = await _controller.takePicture();
      final result = await scanService.processImage(
        file.path,
        frameConfig: _frameConfig,
      );
      if (!mounted) {
        return;
      }
      if (result.data != null) {
        Navigator.of(context).pop(result.data);
      } else {
        _showError(result.errorMessage ?? 'No se pudo analizar el documento.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('No se pudo tomar la fotografia.');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _showError(String message) {
    showAppFeedback(
      context,
      message,
      tone: AppFeedbackTone.error,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameConfig = _frameConfig;
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxGuideWidth = constraints.maxWidth - 32;
                final maxGuideHeight = constraints.maxHeight * 0.56;
                final minGuideWidth = frameConfig.isVertical ? 248.0 : 312.0;
                var guideWidth = math.min(
                  maxGuideWidth,
                  maxGuideHeight * frameConfig.aspectRatio,
                );
                guideWidth = math.max(
                  math.min(minGuideWidth, maxGuideWidth),
                  guideWidth,
                );
                final guideHeight = guideWidth / frameConfig.aspectRatio;
                final cutoutRect = Rect.fromCenter(
                  center: constraints.biggest.center(Offset.zero),
                  width: guideWidth,
                  height: guideHeight,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) =>
                          _focusAt(details.localPosition, constraints.biggest),
                      child: CameraPreview(_controller),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _FocusMaskPainter(cutoutRect: cutoutRect),
                      ),
                    ),
                    if (_focusIndicatorPosition != null)
                      Positioned(
                        left: _focusIndicatorPosition!.dx - 26,
                        top: _focusIndicatorPosition!.dy - 26,
                        child: const IgnorePointer(child: _FocusIndicator()),
                      ),
                    SafeArea(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 14,
                            left: 16,
                            right: 16,
                            child: Row(
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: _processing
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Regresar'),
                                ),
                                const Spacer(),
                                const _HeaderPill(
                                  icon: Icons.center_focus_strong_rounded,
                                  label: 'Toca para enfocar',
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 72,
                            left: 16,
                            right: 16,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _ModeChip(
                                    label: 'Licencia / Credencial',
                                    selected: _preset ==
                                        ScanDocumentPreset.credential,
                                    onTap: () => setState(() {
                                      _preset = ScanDocumentPreset.credential;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  _ModeChip(
                                    label: 'Pasaporte',
                                    selected:
                                        _preset == ScanDocumentPreset.passport,
                                    onTap: () => setState(() {
                                      _preset = ScanDocumentPreset.passport;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  _ModeChip(
                                    label: 'Otro',
                                    selected:
                                        _preset == ScanDocumentPreset.other,
                                    onTap: () => setState(() {
                                      _preset = ScanDocumentPreset.other;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 122,
                            left: 16,
                            right: 16,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _ModeChip(
                                    label: 'Auto',
                                    selected: _orientation ==
                                        ScanFrameOrientation.auto,
                                    onTap: () => setState(() {
                                      _orientation = ScanFrameOrientation.auto;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  _ModeChip(
                                    label: 'Horizontal',
                                    selected: _orientation ==
                                        ScanFrameOrientation.horizontal,
                                    onTap: () => setState(() {
                                      _orientation =
                                          ScanFrameOrientation.horizontal;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  _ModeChip(
                                    label: 'Vertical',
                                    selected: _orientation ==
                                        ScanFrameOrientation.vertical,
                                    onTap: () => setState(() {
                                      _orientation =
                                          ScanFrameOrientation.vertical;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: guideWidth,
                              child: _DocumentGuide(frameConfig: frameConfig),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            child: Container(
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
                                    'Escanea el documento',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Llena el marco con la credencial o pasaporte y toca el nombre si necesitas reenfocar.',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _processing ? null : _capture,
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(58),
                                      ),
                                      icon: _processing
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt_rounded,
                                            ),
                                      label: const Text('Tomar foto'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xA60F172A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accentSoft),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _DocumentGuide extends StatelessWidget {
  const _DocumentGuide({required this.frameConfig});

  final ScanFrameConfig frameConfig;

  @override
  Widget build(BuildContext context) {
    final isVertical = frameConfig.isVertical;
    return AspectRatio(
      aspectRatio: frameConfig.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.92),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            const _GuideCorner(alignment: Alignment.topLeft),
            const _GuideCorner(alignment: Alignment.topRight),
            const _GuideCorner(alignment: Alignment.bottomLeft),
            const _GuideCorner(alignment: Alignment.bottomRight),
            Align(
              child: Container(
                width: isVertical ? 1.2 : 84,
                height: isVertical ? 84 : 1.2,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            Align(
              child: Container(
                width: isVertical ? 84 : 1.2,
                height: isVertical ? 1.2 : 84,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xC014223A),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    isVertical ? 'Marco vertical' : 'Marco horizontal',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent.withValues(alpha: 0.26),
      backgroundColor: const Color(0xA014223A),
      side: BorderSide(
        color: selected
            ? AppColors.accentSoft.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

class _FocusMaskPainter extends CustomPainter {
  const _FocusMaskPainter({required this.cutoutRect});

  final Rect cutoutRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.22);
    final fullPath = Path()..addRect(Offset.zero & size);
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          cutoutRect,
          const Radius.circular(28),
        ),
      );
    final masked = Path.combine(PathOperation.difference, fullPath, cutoutPath);
    canvas.drawPath(masked, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _FocusMaskPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect;
  }
}

class _FocusIndicator extends StatelessWidget {
  const _FocusIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.94),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft.withValues(alpha: 0.18),
            border: Border.all(
              color: AppColors.accentSoft.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideCorner extends StatelessWidget {
  const _GuideCorner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 34,
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: isLeft
                    ? const BorderSide(color: AppColors.accentSoft, width: 4)
                    : BorderSide.none,
                right: !isLeft
                    ? const BorderSide(color: AppColors.accentSoft, width: 4)
                    : BorderSide.none,
                top: isTop
                    ? const BorderSide(color: AppColors.accentSoft, width: 4)
                    : BorderSide.none,
                bottom: !isTop
                    ? const BorderSide(color: AppColors.accentSoft, width: 4)
                    : BorderSide.none,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
