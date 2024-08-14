import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_letter_task/model/letter_model.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:svg_path_parser/svg_path_parser.dart';

class LetterSwitcher extends StatefulWidget {
  final List<LetterModel> letters;

  LetterSwitcher({Key? key, required this.letters}) : super(key: key);

  @override
  _LetterSwitcherState createState() => _LetterSwitcherState();
}

class _LetterSwitcherState extends State<LetterSwitcher> {
  int activeIndex = 0; // Track the active letter index

  void _onLetterComplete() {
    setState(() {
      if (activeIndex < widget.letters.length - 1) {
        activeIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.letters.length, (index) {
        return Padding(
          padding: EdgeInsets.only(right: 20),
          child: MyPaintWidget(
            letter: widget.letters[index],
            isActive: index == activeIndex,
            onComplete: _onLetterComplete, // Pass the completion callback
          ),
        );
      }),
    );
  }
}

class MyPaintWidget extends StatefulWidget {
  final LetterModel letter;
  final bool isActive;
  final VoidCallback onComplete; // Callback to notify when drawing is complete

  MyPaintWidget({
    Key? key,
    required this.letter,
    required this.isActive,
    required this.onComplete,
  }) : super(key: key);

  @override
  _MyPaintWidgetState createState() => _MyPaintWidgetState();
}

class _MyPaintWidgetState extends State<MyPaintWidget> {
  Path? letterImage;
  Path? dottedIndex;

  Path? letterIndex;

  ui.Image? traceImage;

  ui.Image? dottedImage;

  ui.Image? anchorImage;
  late List<ui.Path> paths;
  late ui.Path currentDrawingPath = ui.Path();
  late List<List<Offset>> allStrokePoints = [];
  Offset anchorPos = Offset.zero;

  Size viewSize = Size(200, 200);
  bool letterTracingFinished = false;
  bool hasFinishedOneStroke = false;
  int currentStroke = 0;
  int currentStrokeProgress = -1;

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadAssets();

    paths = [];
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (!isLoaded) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (viewSize.width > 0 && viewSize.height > 0) {
  //         loadAssets();
  //       }
  //     });
  //   }
  // }

  Size getOriginalSvgSize(String svgPath) {
    final parsedPath = parseSvgPath(svgPath);

    final path = Path()..addPath(parsedPath, Offset.zero);
    final bounds = path.getBounds();

    return Size(bounds.width, bounds.height);
  }

  Future<void> loadAssets() async {
    Path parsedPath = parseSvgPath(widget.letter.letterPath);
    final dottedIndexPath = parseSvgPath(widget.letter.indexPath);
    final dottedPath = parseSvgPath(widget.letter.dottedPath);

    final originalSize = getOriginalSvgSize(widget.letter.letterPath);

    final scaleX = viewSize.width / originalSize.width;
    final scaleY = viewSize.height / originalSize.height;
    final scale = math.min(scaleX, scaleY);

    final matrix = Matrix4.identity()
      ..scale(scale)
      ..translate(
        (viewSize.width - (originalSize.width * scale)) / 2,
        (viewSize.height - (originalSize.height * scale)) / 2,
      );

    letterImage = applyTransformation(parsedPath, matrix);
    letterIndex = applyTransformation(dottedPath, matrix);
    dottedIndex = applyTransformation(dottedIndexPath, matrix);
    if (widget.letter.needInstruction) {
      traceImage = await loadImage(widget.letter.tracingAssets);
    }
    anchorImage = await loadImage(widget.letter.tracingAssets);
    dottedImage = await loadImage(widget.letter.dottedImage);

    allStrokePoints = await loadPointsFromJson(widget.letter.pointsJsonFile);

    if (allStrokePoints.isNotEmpty) {
      anchorPos = allStrokePoints[0][0];
    }
    setState(() {
      isLoaded = true;
    });
  }

  Path applyTransformation(Path path, Matrix4 matrix) {
    final Float64List matrix4Storage = matrix.storage;
    return path.transform(matrix4Storage);
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
    print(widget.isActive);
    if (letterImage == null || allStrokePoints.isEmpty) {
      return CircularProgressIndicator();
    }
    return GestureDetector(
      onPanStart: widget.isActive ? (details) => handlePanStart(details) : null,
      onPanUpdate:
          widget.isActive ? (details) => handlePanUpdate(details) : null,
      onPanEnd: widget.isActive ? (details) => handlePanEnd(details) : null,
      child: Transform.scale(
        scale: 1.2,
        child: Container(
          color: Colors.amber,
          width: 200,
          height: 200,
          child: CustomPaint(
            size: Size.infinite,
            painter: TracingPainter(
              dottedImage: dottedImage,
              dottedIndex: dottedIndex,
              letterIndex: letterIndex,
              letterColor: Colors.blue.withOpacity(.4),
              letterImage: letterImage!,
              traceImage: widget.letter.needInstruction ? traceImage : null,
              anchorImage: anchorImage,
              paths: paths,
              currentDrawingPath: currentDrawingPath,
              pathPoints: allStrokePoints.expand((p) => p).toList(),
              strokeColor: widget.letter.strokeColor,
              pointColor: widget.letter.pointColor,
              anchorPos: anchorPos,
              viewSize: viewSize,
              strokePoints: allStrokePoints[currentStroke],
            ),
          ),
        ),
      ),
    );
  }

  void handlePanStart(DragStartDetails details) {
    if (!isTracingStartPoint(details.localPosition)) return;
    if (currentStrokeProgress == -1) {
      currentDrawingPath = ui.Path();
      currentDrawingPath.moveTo(anchorPos.dx, anchorPos.dy);
      currentStrokeProgress = 1;
    }
  }

  void handlePanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    if (currentStrokeProgress >= 0 &&
        currentStrokeProgress < allStrokePoints[currentStroke].length &&
        isOverlapped(position)) {
      if (isValidPoint(
          allStrokePoints[currentStroke][currentStrokeProgress], position)) {
        currentStrokeProgress++;
      }

      final point = allStrokePoints[currentStroke][currentStrokeProgress - 1];
      anchorPos = point;
      currentDrawingPath.lineTo(point.dx, point.dy);
    }

    if (currentStrokeProgress >= allStrokePoints[currentStroke].length) {
      completeStroke();
    }

    setState(() {});
  }

  void completeStroke() {
    if (currentStroke < allStrokePoints.length - 1) {
      paths.add(currentDrawingPath);
      currentStroke++;
      currentStrokeProgress = -1;
      anchorPos = allStrokePoints[currentStroke][0];
      hasFinishedOneStroke = true;
    } else if (!letterTracingFinished) {
      letterTracingFinished = true;
      hasFinishedOneStroke = true;
      widget.onComplete(); // Notify completion of the current letter
    }
  }

  void handlePanEnd(DragEndDetails details) {}

  bool isTracingStartPoint(Offset position) {
    final anchorRect =
        Rect.fromCenter(center: anchorPos, width: 50, height: 50);
    return anchorRect.contains(position);
  }

  bool isOverlapped(Offset position) {
    return true;
  }

  bool isValidPoint(Offset point, Offset position) {
    final validArea = 30.0;
    return (position - point).distance < validArea;
  }
}

class TracingPainter extends CustomPainter {
  final Path letterImage;
  final ui.Image? traceImage;
  final ui.Image? dottedImage;

  final ui.Image? anchorImage;
  final List<ui.Path> paths;
  final ui.Path currentDrawingPath;
  final List<Offset> pathPoints;
  final Color strokeColor;
  final Color pointColor;
  final Offset anchorPos;
  final Size viewSize;
  final List<Offset> strokePoints;
  final Color letterColor;
  final Shader? letterShader;

  final Path? dottedIndex;

  final Path? letterIndex;

  TracingPainter({
    this.dottedImage,
    this.dottedIndex,
    this.letterIndex,
    required this.strokePoints,
    required this.letterImage,
    required this.traceImage,
    required this.anchorImage,
    required this.paths,
    required this.currentDrawingPath,
    required this.pathPoints,
    required this.strokeColor,
    required this.pointColor,
    required this.anchorPos,
    required this.viewSize,
    required this.letterColor,
    this.letterShader,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final letterPaint = Paint()
      ..color = letterColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 80.0;

    // Draw the letter image
    canvas.drawPath(letterImage, letterPaint);

    if (dottedIndex != null) {
      final debugPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      print('ss');
      canvas.drawPath(dottedIndex!, debugPaint);
    }

    if (letterIndex != null) {
      final debugPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..strokeWidth = 2.0;

      canvas.drawPath(letterIndex!, debugPaint);
    }

    // Clip the canvas to the letter path
    canvas.save();
    canvas.clipPath(letterImage);

    if (traceImage != null) {
      final traceRect = Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      );
      canvas.drawImageRect(traceImage!, traceRect, traceRect, Paint());
    }

    final dottedimageDraw = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );
    canvas.drawImageRect(
        dottedImage!, dottedimageDraw, dottedimageDraw, Paint());

    // if (anchorImage != null) {
    //   final anchorRect = Rect.fromCenter(
    //     center: anchorPos,
    //     width: 50,
    //     height: 50,
    //   );
    //   canvas.drawImageRect(
    //     anchorImage!,
    //     Rect.fromLTWH(0, 0, anchorImage!.width.toDouble(),
    //         anchorImage!.height.toDouble()),
    //     anchorRect,
    //     Paint(),
    //   );
    // }

    // Draw all paths within the clipping area
    for (var path in paths) {
      canvas.drawPath(path, strokePaint);
    }

    // Draw the current drawing path
    canvas.drawPath(currentDrawingPath, strokePaint);

    // Restore the canvas state to remove the clipping
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
