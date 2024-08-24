import 'package:flutter/widgets.dart';

/// Means the floor point
final class FloorPoint {
  final int id;
  final double x;
  final double y;
  final List<int> neighbours;
  final int floor;
  final Size sizeParentSvg;

  const FloorPoint({
    required this.id,
    required this.x,
    required this.y,
    required this.neighbours,
    required this.floor,
    required this.sizeParentSvg,
  });
}
