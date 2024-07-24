import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_letter_task/widgets/canvas_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: DrawingScreen(),
      ),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: screenSize.height,
      width: screenSize.width,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/BG.svg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/Header.svg',
              fit: BoxFit.fitWidth,
              height: screenSize.height / 2,
            ),
          ),
          Positioned(
            top: 80,
            left: 30,
            child: SvgPicture.asset(
              'assets/trace2.svg',
              fit: BoxFit.fitHeight,
              height: screenSize.height / 3,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 40,
            child: SvgPicture.asset(
              'assets/bee.svg',
              fit: BoxFit.fitHeight,
              height: screenSize.height / 2,
            ),
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: CanvasWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterDrawing {
  final String character;
  final List<List<Offset>> strokes;

  CharacterDrawing(this.character, this.strokes);
}
