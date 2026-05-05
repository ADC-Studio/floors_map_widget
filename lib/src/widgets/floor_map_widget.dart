import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:floors_map_widget/src/widgets/tiled_svg_map.dart';
import 'package:flutter/material.dart';

class FloorMapWidget extends StatefulWidget {
  final List<FloorPoint> listPoints;
  final String svgContent;
  final List<FloorItemWidget> listItemsWidgets;
  final bool unvisiblePoints;
  final int? startIdPoint;
  final int? endIdPoint;
  // final ValueNotifier<bool> reRenderToogle;
  final ValueNotifier<SvgMapRenderProperties> renderPropertiesNotifier;
  final TransformationController transformationController;

  /// A widget that displays an SVG map with interactive floor items.
  const FloorMapWidget(
    this.svgContent,
    this.listItemsWidgets,
    this.listPoints, {
    // required this.reRenderToogle,
    required this.renderPropertiesNotifier,
    required this.transformationController,
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
  void didUpdateWidget(final FloorMapWidget oldWidget) {
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
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          // we could do constraints.biggest;
          final parentSize = constraints.biggest;
          if (widget.renderPropertiesNotifier.value.size == null) {
            widget.renderPropertiesNotifier.value.size = parentSize;
          }

          return Stack(
            children: [
              /// --- Static SVG Map (rarely changes) ---
              // RepaintBoundary(
              //   child:
              TiledSvgMap.listenable(
                // SvgMap.listenable(
                widget.renderPropertiesNotifier,
                widget.transformationController,
              ),
              // ),

              /// --- Interactive Items (change independently) ---
              RepaintBoundary(
                child: Stack(
                  children: widget.listItemsWidgets
                      .map(
                        (final item) => item.parentSize == null
                            ? item.copyWith(parentSize: parentSize)
                            : item,
                      )
                      .toList(),
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
