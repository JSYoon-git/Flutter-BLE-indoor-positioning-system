import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double boxSize = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final vLines = (size.width ~/ boxSize) + 1;
    final hLines = (size.height ~/ boxSize) + 1;

    final paint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black12
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Draw vertical lines
    for (var i = 0; i < vLines; ++i) {
      final x = boxSize * i;
      path.moveTo(x, 0);
      path.relativeLineTo(0, size.height);
    }

    // Draw horizontal lines
    for (var i = 0; i < hLines; ++i) {
      final y = boxSize * i;
      path.moveTo(0, y);
      path.relativeLineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
