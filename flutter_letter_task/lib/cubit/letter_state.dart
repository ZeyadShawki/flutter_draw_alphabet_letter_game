import 'dart:ui';

// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';

abstract class DrawingSatate extends Equatable {}


abstract class DrawingState {}

class DrawingInitial extends DrawingState {}

class DrawingInProgress extends DrawingState {
  final List<Offset?> currentStroke;
  DrawingInProgress(this.currentStroke);
}

class DrawingCompleted extends DrawingState {}
