
// import 'dart:math';
// import 'dart:ui';

// // ignore: depend_on_referenced_packages
// import 'package:bloc/bloc.dart';
// import 'package:flutter_letter_task/cubit/letter_state.dart';
// import 'package:flutter_letter_task/main.dart';

// class DrawingCubit extends Cubit<DrawingState> {
//  DrawingCubit() : super(DrawingInitial()) {
//         tDrawing = CharacterDrawing(
//       'T',
//       [
//         [const Offset(150, 20), const Offset(150, 200)], // Vertical line
//         [const Offset(110, 80), const Offset(190, 80)], // Horizontal line
//       ],
//     );
//   }
//   late CharacterDrawing tDrawing;
//   List<List<Offset?>> allStrokes = [];
//   List<Offset?> currentStroke = [];
//   int strokeIndex = 0;

//  void startDrawing() {
 
//       if (currentStroke.isEmpty) {
//         emit( DrawingInProgress([]));
//       }

//   }

//   void updateDrawing(Offset point) {
//     if (isPointBetweenOffsets(tDrawing.strokes[strokeIndex].first,
//             tDrawing.strokes[strokeIndex].last, point) &&
//         checkifNextPoint(currentStroke, tDrawing.strokes[strokeIndex], point)) {
  
//         // Snap the point to the nearest point on the current stroke
//         Offset snappedPoint =
//             snapToStroke(point, tDrawing.strokes[strokeIndex]);

//         // Add point to currentStroke and ensure it's sorted by dx offset
//         addPointToCurrentStroke(snappedPoint);

//       emit( DrawingInProgress(List.from(currentStroke)));

//     }
//   }

//   void addPointToCurrentStroke(Offset point) {
//     // Check if the point is already in the list
//     if (currentStroke.isEmpty || currentStroke.last != point) {
//       currentStroke.add(point);

//       // Sort points by dx and then by dy
//       currentStroke.sort((a, b) {
//         if (a!.dx != b!.dx) {
//           return a.dx.compareTo(b.dx);
//         } else {
//           return a.dy.compareTo(b.dy);
//         }
//       });
//     }
//   }

//   void finishDrawing() {
  
//       if (currentStroke.isNotEmpty) {
//         allStrokes.add(List.from(currentStroke));
//         if (validateStroke(currentStroke, tDrawing.strokes[strokeIndex])) {
//           strokeIndex++;
//           if (strokeIndex == tDrawing.strokes.length) {
//            emit(DrawingCompleted());
//             currentStroke = [];
//             strokeIndex = 0;
//             allStrokes.clear();
//           } else {
//             currentStroke = [];
//             emit(DrawingInProgress([]));
//           }
//         } else {
//             emit(DrawingInProgress(currentStroke));
//         }
//       }
    
//   }

//   Offset snapToStroke(Offset userPoint, List<Offset> stroke) {
//     double minDistance = double.infinity;
//     Offset snappedPoint = userPoint;

//     for (int i = 0; i < stroke.length - 1; i++) {
//       final start = stroke[i];
//       final end = stroke[i + 1];

//       Offset nearestPoint = _nearestPointOnLineSegment(start, end, userPoint);
//       double distance = (nearestPoint - userPoint).distance;

//       if (distance < minDistance) {
//         minDistance = distance;
//         snappedPoint = nearestPoint;
//       }
//     }

//     return snappedPoint;
//   }

//   bool checkifNextPoint(
//       List<Offset?> userStroke, List<Offset> currentStroke, Offset point) {
//     final startStroke = currentStroke.first;
//     final endStroke = currentStroke.last;

//     // print(currentStroke..toString());
//     // print(end.toString());
//     // print(point.toString());
//     // Handle special cases where start and end points are the same
//     if (userStroke.isEmpty) {
//       // Handle horizontal line segments
//       if (startStroke.dy == endStroke.dy) {
//         // ignore: unused_local_variable
//         final endDy = endStroke.dy + 10;


//         return point.dx >= startStroke.dx && point.dx <= (startStroke.dx + 5);
//       }

// // vertical
//       else if (startStroke.dx == endStroke.dx) {

//         return point.dy >= startStroke.dy && point.dy <= (startStroke.dy + 5);
//       }
//     } else {
//       final lastStroke = userStroke.last;

//       if (startStroke.dy == endStroke.dy) {

//         return point.dx >= lastStroke!.dx;
//       }

// // vertical
//       else if (startStroke.dx == endStroke.dx) {

//         return point.dy >= lastStroke!.dy;
//       }
//     }

//     return false;
//   }

//   bool isPointBetweenOffsets(Offset start, Offset end, Offset point) {
//     // Handle special cases where start and end points are the same
//     if (start == end) {
//       return point ==
//           start; // Point must be exactly the same as start (and end)
//     }

//     // Handle horizontal line segments
//     if (start.dy == end.dy) {
//       final startdy = start.dy - 10;
//       final endDy = end.dy + 10;

//       return (point.dy >= min(startdy, endDy) &&
//               point.dy <= max(startdy, endDy)) &&
//           point.dx >= min(start.dx, end.dx) &&
//           point.dx <= max(start.dx, end.dx);
//     }

//     // Handle vertical line segments
//     if (start.dx == end.dx) {
//       final startdx = start.dx - 10;
//       final endDx = end.dx + 10;

//       return (point.dx >= min(startdx, endDx) &&
//               point.dx <= max(startdx, endDx)) &&
//           point.dy >= min(start.dy, end.dy) &&
//           point.dy <= max(start.dy, end.dy);
//     }

//     // General case for diagonal lines
//     // Check if the point is within the bounding box of the line segment
//     if (point.dx < min(start.dx, end.dx) ||
//         point.dx > max(start.dx, end.dx) ||
//         point.dy < min(start.dy, end.dy) ||
//         point.dy > max(start.dy, end.dy)) {
//       return false;
//     }

//     // Check if the point is collinear with the line segment
//     double crossProduct = (point.dy - start.dy) * (end.dx - start.dx) -
//         (point.dx - start.dx) * (end.dy - start.dy);

//     // Check if the cross product is close to zero (indicating collinearity)
//     if (crossProduct.abs() > 1e-10) {
//       return false;
//     }

//     return true;
//   }

//   Offset _nearestPointOnLineSegment(Offset start, Offset end, Offset point) {
//     final line = end - start;
//     final len = line.distance;
//     final lineDir = line / len;
//     final startToPoint = point - start;
//     final projection =
//         startToPoint.dx * lineDir.dx + startToPoint.dy * lineDir.dy;
//     final t = projection.clamp(0.0, len);
//     return start + lineDir * t;
//   }

//   bool validateStroke(List<Offset?> userStroke, List<Offset> correctStroke) {
//     if (userStroke.isEmpty || correctStroke.isEmpty) return false;

//     const double maxDeviation = 5.0; // Maximum allowed deviation

//     List<Offset?> userPoints =
//         userStroke.where((point) => point != null).toList();

//     for (int i = 0; i < correctStroke.length - 1; i++) {
//       final start = correctStroke[i];
//       final end = correctStroke[i + 1];

//       bool valid = false;

//       final userStart = userPoints.first!;
//       final userEnd = userPoints.last!;

//       double distanceToStart = (userStart - start).distance;
//       double distanceToEnd = (userEnd - end).distance;
//       // print('end ' + userEnd.toString());
//       if (distanceToStart < maxDeviation && distanceToEnd < maxDeviation) {
//         valid = true;
//       }

//       if (!valid) return false;
//     }

//     return true;
//   }
// }



