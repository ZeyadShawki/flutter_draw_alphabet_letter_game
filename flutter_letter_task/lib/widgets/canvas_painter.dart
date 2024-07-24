import 'dart:ui';

import 'package:flutter/material.dart';

class DrawPainter extends CustomPainter {
  final List<List<Offset>> correctStrokes;
  final List<List<Offset?>> allStrokes;
  final List<Offset?> currentStroke;
  final int strokeIndex;

  DrawPainter(this.correctStrokes, this.allStrokes, this.currentStroke,
      this.strokeIndex);

  final strokeWidth = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    Paint guidePaint = Paint()
      ..color = Color(0xff6EC5A1).withOpacity(0.5) // Faded color for guide
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth - 5
      ..style = PaintingStyle.stroke;

    Paint userPaint = Paint()
      ..color = Color(0xff6EC5A1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    Paint dottedLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Paint circlePaint = Paint()
      ..color = Colors.black // Circle color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // Draw the guide lines with a faded color
    for (int j = 0; j < correctStrokes.length; j++) {
      var stroke = correctStrokes[j];
      for (int i = 0; i < stroke.length - 1; i++) {
        // Draw the faded background line first
        canvas.drawLine(stroke[i], stroke[i + 1], guidePaint);

        // Draw the dotted line on top of the faded line
        drawDottedLine(canvas, stroke[i], stroke[i + 1], dottedLinePaint);

        // Draw the circle and index number if this stroke is the current stroke
        if (j == strokeIndex) {
          // Draw the circle
          canvas.drawCircle(
            stroke[i] + Offset(-0, -0), // Center the circle around the text
            10, // Radius of the circle
            circlePaint,
          );
        }

        // Draw the stroke index number at the start of the stroke
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: '${j + 1}',
            style: TextStyle(
              color: j == strokeIndex
                  ? Colors.white
                  : Colors.white, // Change color based on index
              fontSize: j == strokeIndex ? 18 : 16,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, stroke[i] + Offset(-5, -10));
      }
    }

    // Draw the user's completed strokes
    for (var stroke in allStrokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i] != null && stroke[i + 1] != null) {
          canvas.drawLine(stroke[i]!, stroke[i + 1]!, userPaint);
        }
      }
    }

    // Draw the user's current stroke
    for (int i = 0; i < currentStroke.length - 1; i++) {
      if (currentStroke[i] != null && currentStroke[i + 1] != null) {
        canvas.drawLine(currentStroke[i]!, currentStroke[i + 1]!, userPaint);
      }
    }
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 5.0;

    final double distance = (end - start).distance;
    final double dx = (end.dx - start.dx) / distance;
    final double dy = (end.dy - start.dy) / distance;

    double x = start.dx;
    double y = start.dy;
    while ((x - start.dx).abs() < distance && (y - start.dy).abs() < distance) {
      final double nextX = x + dashWidth * dx;
      final double nextY = y + dashWidth * dy;

      canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint);

      x = nextX + dashSpace * dx;
      y = nextY + dashSpace * dy;
    }
  }}