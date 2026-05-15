import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:floors_map_widget/src/widgets/tiled_svg_map.dart';
import 'package:flutter/material.dart';

class FloorMapWidget extends StatefulWidget {
  final List<FloorPoint>? listPoints;
  final String svgContent;
  final List<FloorItemWidget> listItemsWidgets;
  final bool unvisiblePoints;
  final int? startIdPoint;
  final int? endIdPoint;
  final ValueNotifier<SvgMapRenderProperties>? renderPropertiesNotifier;
  final TransformationController? transformationController;
  final bool debugTiles;

  /// A widget that displays an SVG map with interactive floor items.
  const FloorMapWidget(
    this.svgContent,
    this.listItemsWidgets, {
    this.listPoints,
    this.renderPropertiesNotifier,
    this.transformationController,
    this.unvisiblePoints = false,
    this.debugTiles = false,
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
  late ValueNotifier<SvgMapRenderProperties> _renderPropertiesNotifier;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    listPoints = _resolvePoints();
    _renderPropertiesNotifier =
        widget.renderPropertiesNotifier ?? ValueNotifier(_defaultProperties());
    _transformationController =
        widget.transformationController ?? TransformationController();
    _calculatePath();
  }

  List<FloorPoint> _calculatedPath = [];

  @override
  void didUpdateWidget(final FloorMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.renderPropertiesNotifier != widget.renderPropertiesNotifier) {
      if (oldWidget.renderPropertiesNotifier == null) {
        _renderPropertiesNotifier.dispose();
      }
      _renderPropertiesNotifier = widget.renderPropertiesNotifier ??
          ValueNotifier(_defaultProperties());
    }

    if (oldWidget.transformationController != widget.transformationController) {
      if (oldWidget.transformationController == null) {
        _transformationController.dispose();
      }
      _transformationController =
          widget.transformationController ?? TransformationController();
    }

    if (oldWidget.svgContent != widget.svgContent ||
        oldWidget.listPoints != widget.listPoints) {
      listPoints = _resolvePoints();
      if (widget.renderPropertiesNotifier == null) {
        _renderPropertiesNotifier.value = _defaultProperties(
          size: _renderPropertiesNotifier.value.size,
        );
      }
      _calculatePath();
      return;
    }

    // prevent calculating the shortest path every time the map is zoomed in/out
    if (widget.startIdPoint != oldWidget.startIdPoint ||
        widget.endIdPoint != oldWidget.endIdPoint) {
      _calculatePath();
    }
  }

  List<FloorPoint> _resolvePoints() =>
      widget.listPoints ??
      FloorSvgParser(svgContent: widget.svgContent).getPoints();

  SvgMapRenderProperties _defaultProperties({final Size? size}) =>
      SvgMapRenderProperties(
        svgData: widget.svgContent,
        svgSource: SvgSource.string,
        mapSize: size,
        renderingStrategy: RenderStrategy.picture,
      );

  void _calculatePath() {
    final startIdPoint = widget.startIdPoint;
    final endIdPoint = widget.endIdPoint;

    if (startIdPoint == null || endIdPoint == null) {
      _calculatedPath = [];
      return;
    }

    _calculatedPath = PathBuilder(
      startId: startIdPoint,
      endId: endIdPoint,
      coords: listPoints,
    ).findShortestPath()['points'] as List<FloorPoint>;
  }

  void _syncRenderPropertiesSize(final Size parentSize) {
    final currentProperties = _renderPropertiesNotifier.value;
    if (currentProperties.size == parentSize) {
      return;
    }

    _renderPropertiesNotifier.value =
        currentProperties.copyWith(mapSize: parentSize);
  }

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          // we could do constraints.biggest;
          final parentSize = constraints.biggest;
          _syncRenderPropertiesSize(parentSize);

          return Stack(
            children: [
              /// --- Static SVG Map ---
              RepaintBoundary(
                child: TiledSvgMap.listenable(
                  _renderPropertiesNotifier,
                  _transformationController,
                  unvisiblePoints: widget.unvisiblePoints,
                  debugTiles: widget.debugTiles,
                ),
              ),

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

  @override
  void dispose() {
    if (widget.renderPropertiesNotifier == null) {
      _renderPropertiesNotifier.dispose();
    }
    if (widget.transformationController == null) {
      _transformationController.dispose();
    }
    super.dispose();
  }
}
