import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorMapWidget extends StatefulWidget {
  final List<FloorPoint> listPoints;
  final String svgContent;
  final List<FloorItemWidget> listItemsWidgets;
  final bool unvisiblePoints;
  final int? startIdPoint;
  final int? endIdPoint;

  /// A widget that displays an SVG map with interactive floor items.
  const FloorMapWidget(
    this.svgContent,
    this.listItemsWidgets,
    this.listPoints, {
    this.unvisiblePoints = false,
    this.startIdPoint,
    this.endIdPoint,
    super.key,
  });

  @override
  State<FloorMapWidget> createState() => _FloorMapWidgetState();
}

class _FloorMapWidgetState extends State<FloorMapWidget> {
  /// Navigation points in the map.
  late List<FloorPoint> listPoints;

  @override
  void initState() {
    super.initState();
    listPoints = widget.listPoints;
  }

  List<FloorPoint> _calculatedPath = [];

  @override
  void didUpdateWidget(FloorMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // prevent calculating the shortest path every time the map is zoomed in/out
    if (widget.startIdPoint != oldWidget.startIdPoint ||
        widget.endIdPoint != oldWidget.endIdPoint) {
      _calculatePath();
    }
  }

  void _calculatePath() {
    if (widget.startIdPoint != null && widget.endIdPoint != null) {
      final path = PathBuilder(
        startId: widget.startIdPoint!,
        endId: widget.endIdPoint!,
        coords: listPoints,
      ).findShortestPath()['points'] as List<FloorPoint>;
      setState(() {
        _calculatedPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // we could do constraints.biggest;
        final parentSize = constraints.biggest;

        return Stack(
          children: [
            /// --- Static SVG Map (rarely changes) ---
            RepaintBoundary(
              child: SvgMap(
                widget.svgContent,
                sizeMap: parentSize,
                hidePoints: widget.unvisiblePoints,
              ),
            ),

            /// --- Interactive Items (change independently) ---
            RepaintBoundary(
              child: Stack(
                children: widget.listItemsWidgets.map((item) {
                  return item.parentSize == null
                      ? item.copyWith(parentSize: parentSize)
                      : item;
                }).toList(),
              ),
            ),

            /// --- Path Painter (only appears when a path is active) ---
            if (_calculatedPath.isNotEmpty)
              RepaintBoundary(
                child: FloorPathPainter(
                  _calculatedPath,
                  parentSize: parentSize,
                ),
              ),
          ],
        );
      },
    );
  }
}
