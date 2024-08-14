import 'dart:async';
import 'dart:convert'; // For JSON parsing
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class CapturePoint extends StatefulWidget {
  final String letterPath;

  const CapturePoint({
    Key? key,
    required this.letterPath,
  }) : super(key: key);

  @override
  _CapturePointState createState() => _CapturePointState();
}

class _CapturePointState extends State<CapturePoint> {
  late Path letterImage;
  late List<List<Offset>> allStrokePoints = [
    []
  ]; // List of strokes, each stroke is a list of points
  Size viewSize = Size(200, 200);
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (viewSize.width > 0 && viewSize.height > 0) {
          loadAssets();
        }
      });
    }
  }

  Size getOriginalSvgSize(String svgPath) {
    final parsedPath = parseSvgPath(svgPath);
    final path = Path()..addPath(parsedPath, Offset.zero);
    final bounds = path.getBounds();
    return Size(bounds.width, bounds.height);
  }

  Path _applyTransformation(Path path, Size viewSize) {
    // Get the bounds of the original path
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    // Calculate the scale factor to fit the SVG within the view size
    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;
    final double scale = math.min(scaleX, scaleY);

    // Calculate the translation needed to center the path within the view size
    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    // Create a matrix for the transformation
    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    // Apply the transformation to the path
    return path.transform(matrix.storage);
  }

  Future<void> loadAssets() async {
    try {
      final parsedPath = parseSvgPath(widget.letterPath);
      letterImage = _applyTransformation(parsedPath, viewSize);

      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      print('Error loading assets: $e');
    }
  }

  Future<ui.Image> loadImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final Uint8List bytes = data.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }

  Future<List<List<Offset>>> loadPointsFromJson(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final jsonData = jsonDecode(jsonString);
    final List<List<Offset>> strokePointsList = [];

    for (var stroke in jsonData['strokes']) {
      final List<dynamic> strokePointsData = stroke['points'];
      final points = strokePointsData.map<Offset>((pointString) {
        final coords =
            pointString.split(',').map((e) => double.parse(e)).toList();
        return Offset(coords[0] * viewSize.width, coords[1] * viewSize.height);
      }).toList();
      strokePointsList.add(points);
    }

    return strokePointsList;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (allStrokePoints.isNotEmpty &&
                    allStrokePoints.last.isNotEmpty) {
                  setState(() {
                    if (allStrokePoints.length == 1) {
                      allStrokePoints = [[]];
                    } else {
                      allStrokePoints.removeLast();
                    }
                  });
                }
              },
              child: Text("Clear Last Point"),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  allStrokePoints.add([]); // Add a new list for the next stroke
                });
              },
              child: Text("New Stroke"),
            ),
          ],
        ),
        Container(
          height: 200,
          width: 200,
          color: Colors.amber,
          child: LayoutBuilder(builder: (context, constraints) {
            viewSize = Size(constraints.maxWidth, constraints.maxHeight);

            if (!isLoaded) {
              return Center(child: CircularProgressIndicator());
            }

            return Container(
              child: GestureDetector(
                onPanStart: (details) {
                  allStrokePoints.last.add(details.localPosition);
                  captureAndPrintPoints();
                  setState(() {});
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: TracingPainter(
                    pathPoints:
                        allStrokePoints.expand((points) => points).toList(),
                    letter: letterImage,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void captureAndPrintPoints() {
    final strokes = allStrokePoints
        .where((stroke) => stroke.isNotEmpty)
        .map((stroke) => {
              "points": stroke
                  .map((point) =>
                      "${point.dx / viewSize.width},${point.dy / viewSize.height}")
                  .toList()
            })
        .toList();

    final jsonOutput = jsonEncode({
      "id":
          "1AB3FF31-5FF5-493F-A04C-EAFA8371A8AB", // You can replace this with a dynamic UUID
      "style": "default", // Replace with your desired style
      "char": "A", // Replace with the correct character
      "strokes": strokes,
    });
    print('/////////////////');
    print(jsonOutput);
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset> pathPoints;
  final Path letter;

  TracingPainter({
    required this.letter,
    required this.pathPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final letterPaint = Paint()
      ..color = Colors.blue.withOpacity(.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(letter, letterPaint);

    canvas.save();
    canvas.clipPath(letter);

    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (var point in pathPoints) {
      canvas.drawCircle(point, 10, pointPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
