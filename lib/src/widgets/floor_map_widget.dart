import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

class FloorMapWidget extends StatefulWidget {
  final String svgContent;
  final List<FloorItemWidget> listItemsWidgets;
  final bool unvisiblePoints;
  final int? startIdPoint;
  final int? endIdPoint;

  /// A widget that displays an SVG map with interactive floor items.
  const FloorMapWidget(
    this.svgContent,
    this.listItemsWidgets, {
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
    super.initState(); // Call super.initState() first
    final parser = SvgParser(svgContent: widget.svgContent);
    listPoints = parser.getPoints();
  }

  @override
  Widget build(final BuildContext context) => RepaintBoundary(
        child: LayoutBuilder(
          builder: (final context, final constraints) => Stack(
            children: [
              SvgMap(
                widget.svgContent,
                sizeMap: Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
                hidePoints: widget.unvisiblePoints,
              ),
              ...widget.listItemsWidgets.map(
                (final item) => item.parentSize == null
                    ? item.copyWith(
                        parentSize: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                      )
                    : item,
              ),
              if (widget.startIdPoint != null && widget.endIdPoint != null)
                FloorPathPainter(
                  PathBuilder(
                    startId: widget.startIdPoint!,
                    endId: widget.endIdPoint!,
                    coords: listPoints,
                  ).findShortestPath()['points'] as List<FloorPoint>,
                  Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                ),
            ],
          ),
        ),
      );
}
