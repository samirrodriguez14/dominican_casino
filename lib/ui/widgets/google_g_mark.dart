import 'package:flutter/cupertino.dart';

/// Compact four-color Google G for auth buttons.
class GoogleGMark extends StatelessWidget {
  const GoogleGMark({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.35, 1.7, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.35, 1.05, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.4, 0.85, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.25, 1.15, false, paint);

    final bar = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    final midY = size.height / 2 - stroke / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(
        size.width * 0.48,
        midY,
        size.width - stroke * 0.15,
        midY + stroke,
        const Radius.circular(0.5),
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
