import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  SignaturePadState createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = <Offset?>[];
  Size _canvasSize = const Size(320, 180);

  bool get hasSignature => _points.whereType<Offset>().isNotEmpty;

  void clear() {
    setState(() {
      _points.clear();
    });
  }

  Future<String> exportAsBase64() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paintBounds = Offset.zero & _canvasSize;

    canvas.drawRRect(
      RRect.fromRectAndRadius(paintBounds, const Radius.circular(18)),
      Paint()..color = Colors.white,
    );

    final painter =
        _SignaturePainter(points: _points, strokeColor: Colors.black);
    painter.paint(canvas, _canvasSize);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _canvasSize.width.ceil(),
      _canvasSize.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              onPanStart: (details) {
                setState(() => _points.add(details.localPosition));
              },
              onPanUpdate: (details) {
                setState(() => _points.add(details.localPosition));
              },
              onPanEnd: (_) {
                setState(() => _points.add(null));
              },
              child: CustomPaint(
                painter: _SignaturePainter(
                  points: _points,
                  strokeColor: AppColors.midnight,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.points,
    required this.strokeColor,
  });

  final List<Offset?> points;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final guideline = Paint()
      ..color = const Color(0xFFD8E3F4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(18, size.height * 0.68),
      Offset(size.width - 18, size.height * 0.68),
      guideline,
    );

    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.6;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor;
  }
}
