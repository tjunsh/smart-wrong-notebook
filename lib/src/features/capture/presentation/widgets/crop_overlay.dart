import 'package:flutter/material.dart';

class CropOverlay extends StatelessWidget {
  const CropOverlay({super.key, required this.cropRect, required this.onChanged});

  final Rect cropRect;
  final ValueChanged<Rect> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CropOverlayPainter(cropRect),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter(this.cropRect);

  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dimPaint = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dimPaint);
    canvas.drawRect(cropRect, Paint()..blendMode = BlendMode.clear);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}
