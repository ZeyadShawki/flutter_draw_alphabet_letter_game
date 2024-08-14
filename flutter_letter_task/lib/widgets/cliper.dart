import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Draw Multiple Paths')),
        body: Center(
          child: CustomPaint(
            size: Size(300, 300), // Adjust the size as needed
            painter: PathPainter(
              paths: [
                Path()..moveTo(50, 50)..lineTo(250, 50)..lineTo(150, 150)..close(),
                Path()..moveTo(50, 250)..lineTo(250, 250)..lineTo(150, 150)..close(),
                Path()..addOval(Rect.fromCircle(center: Offset(150, 150), radius: 50)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Path> paths;
  final Paint paintStyle;

  PathPainter({required this.paths})
      : paintStyle = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (var path in paths) {
      canvas.drawPath(path, paintStyle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
