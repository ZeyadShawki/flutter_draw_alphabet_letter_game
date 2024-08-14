import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_letter_task/widgets/capture_points.dart';
import 'package:flutter_letter_task/widgets/s_shape_constants.dart';

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
          child: CapturePoint(
            letterPath: ShapePathsStrings.shapeNumber10,
          ),
        ),
      ),
    );
  }
}
