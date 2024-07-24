import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_letter_task/cubit/letter_cubit.dart';
import 'package:flutter_letter_task/cubit/letter_state.dart';
import 'package:flutter_letter_task/widgets/canvas_painter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  final myCubit = DrawingCubit();
  final Set<int> activePointers = {}; // Track active pointers

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawingCubit, DrawingState>(
      bloc: myCubit,
      builder: (context, state) {
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
              ),
              Container(
                width: 400,
                height: 220,
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Listener(
                      onPointerDown: _handlePointerDown,
                      onPointerMove: _handlePointerMove,
                      onPointerUp: _handlePointerUp,
                      child: CustomPaint(
                        painter: DrawPainter(
                          myCubit.tDrawing.strokes,
                          myCubit.allStrokes,
                          myCubit.currentStroke,
                          myCubit.strokeIndex,
                        ),
                        child: Container(),
                      ),
                    ),
                    ..._buildArrowIcons(myCubit.tDrawing.strokes),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Handle pointer down event
  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      activePointers.add(event.pointer); // Add pointer to active pointers
    });

    // Check if exactly two pointers are active
    if (activePointers.length == 2) {
      myCubit.startDrawing();
    }
  }

  // Handle pointer move event
  void _handlePointerMove(PointerMoveEvent event) {
    // Check if exactly two pointers are active
    if (activePointers.length == 2) {
      myCubit.updateDrawing(event.localPosition);
    }
  }

  // Handle pointer up event
  void _handlePointerUp(PointerUpEvent event) {
    setState(() {
      activePointers
          .remove(event.pointer); // Remove pointer from active pointers
    });

    // Check if no pointers are active
    if (activePointers.isEmpty) {
      myCubit.finishDrawing();
    }
  }

  List<Widget> _buildArrowIcons(List<List<Offset>> strokes) {
    List<Widget> arrows = [];
    for (var i = 0; i < strokes.length; i++) {
      if (strokes[i].isNotEmpty) {
        if (myCubit.strokeIndex == 0 || myCubit.strokeIndex <= i) {
          arrows.add(
            Positioned(
              left: strokes[i].first.dx - (i == 0 ? 7 : -15),
              top: strokes[i].first.dy + (i == 0 ? 30 : -9),
              child: Transform.rotate(
                angle: i == 0 ? 0 : -pi / 2,
                child: SvgPicture.asset(
                  'assets/arrow.svg',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
      }
    }
    return arrows;
  }
}
