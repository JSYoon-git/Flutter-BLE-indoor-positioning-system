import 'package:flutter/material.dart';
import 'grid/grid_widget.dart';
import 'package:get/get.dart';
import 'ble_data.dart';
import 'dart:math';

class CircleRoute extends StatefulWidget {
  const CircleRoute({Key? key}) : super(key: key);

  @override
  CircleRouteState createState() => CircleRouteState();
}

class CircleRouteState extends State<CircleRoute>
    with SingleTickerProviderStateMixin {
  double waveRadius = 100.0;

  late AnimationController controller;
  var centerXList = [];
  var centerYList = [];
  List<num> radiusList = [];

  @override
  void initState() {
    super.initState();
    final bleController = Get.put(BLEResult());

    //animation duration 1 seconds
    controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this)
      ..addListener(() => setState(() {}))
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
          centerXList = bleController.selectedCenterXList;
          centerYList = bleController.selectedCenterYList;
          // initialize radius list
          radiusList = [];
          for (int i = 0; i < bleController.selectedDistanceList.length; i++) {
            radiusList.add(0.0);
          }
          // rssi to distance
          for (int idx = 0;
              idx < bleController.selectedDistanceList.length;
              idx++) {
            radiusList[idx] = pow(
                10.0,
                ((bleController.selectedRSSI_1mList[idx] -
                        bleController
                            .scanResultList[
                                bleController.selectedDeviceIdxList[idx]]
                            .rssi) /
                    (10 * bleController.selectedConstNList[idx])));
          }
          print(radiusList);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: GridWidget(CirclePainter(centerXList, centerYList, radiusList)));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CirclePainter extends CustomPainter {
  var centerXList = [];
  var centerYList = [];
  var radiusList = [];
  var circlePaint = Paint()
    ..color = Colors.lightBlue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..isAntiAlias = true;

  CirclePainter(this.centerXList, this.centerYList, this.radiusList);

  @override
  void paint(Canvas canvas, Size size) {
    if (radiusList.isNotEmpty) {
      for (int i = 0; i < radiusList.length; i++) {
        canvas.drawCircle(Offset(centerXList[i] * 100, centerYList[i] * 100),
            radiusList[i] * 100, circlePaint);
        var textPainter1 = TextPainter(
          text: TextSpan(
            text: 'Anchor$i\n(${centerXList[i]}, ${centerYList[i]})',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter1.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        textPainter1.paint(
            canvas, Offset(centerXList[i] * 100 - 27, centerYList[i] * 100));
        /*
        var textPainter2 = TextPainter(
          text: TextSpan(
            text: '${radiusList[i].toStringAsFixed(2)}[m]',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter2.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        textPainter2.paint(
            canvas,
            Offset(centerXList[i] * 100,
                centerYList[i] * 100 - (radiusList[i] * 100) / 2 - 5));
                
        var p1 = Offset(centerXList[i] * 100, centerYList[i] * 100);
        var p2 = Offset(
            centerXList[i] * 100, centerYList[i] * 100 - radiusList[i] * 100);

        canvas.drawLine(p1, p2, circlePaint);
        */
      }
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) {
    return true;
  }
}
