import 'package:flutter/material.dart';
import 'package:zoom_widget/zoom_widget.dart';

import 'grid_painter.dart';

class GridWidget extends StatelessWidget {
  final CustomPainter foreground;

  const GridWidget(this.foreground, {Key? key}) : super(key: key);
  //const GridWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Zoom(
      maxZoomHeight: 1000,
      maxZoomWidth: 1000,
      initZoom: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: SafeArea(
          child: CustomPaint(
            foregroundPainter: foreground,
            painter: GridPainter(),
          ),
        ),
      ),
    );
  }
}
