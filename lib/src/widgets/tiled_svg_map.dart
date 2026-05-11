import 'dart:async';
import 'dart:ui' as ui;
import 'package:floors_map_widget/floors_map_widget.dart'
    show FloorSvgParser, SvgMapRenderProperties;
import 'package:floors_map_widget/src/widgets/svg_map.dart' show SvgSource;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

class _TileKey {
  final int col;
  final int row;
  final double scale;
  _TileKey(this.col, this.row, this.scale);

  @override
  String toString() => '${col}_${row}_$scale';
  @override
  bool operator ==(final Object other) =>
      other is _TileKey &&
      col == other.col &&
      row == other.row &&
      scale == other.scale;
  @override
  int get hashCode => Object.hash(col, row, scale);
}

class TiledSvgMap extends StatefulWidget {
  // Provides the current SVG source, size, quality, and loading widget.
  final ValueListenable<SvgMapRenderProperties> renderPropertiesListenable;
  // Parent InteractiveViewer controller used to calculate visible tiles.
  final TransformationController transformationController;
  final bool unvisiblePoints;

  const TiledSvgMap.listenable(
    this.renderPropertiesListenable,
    this.transformationController, {
    super.key,
    this.unvisiblePoints = false,
  });

  @override
  State<TiledSvgMap> createState() => _TiledSvgMapState();
}

class _TiledSvgMapState extends State<TiledSvgMap> {
  // Loader for the SVG content, created based on the current render properties
  late BytesLoader _vectorLoader;
  // last used render properties to detect changes
  late SvgMapRenderProperties currentRenderProperties;
  Future<PictureInfo>? _pictureFuture;
  Object? _loadedSvg;
  SvgSource? _loadedSource;
  double? _loadedQuality;
  bool _loadedHiddenPoints = false;

  final Map<_TileKey, ui.Image> _tileCache = {};
  final Set<_TileKey> _pendingTiles = {};
  final double _tileSize = 512; // Power of two for better GPU performance.
  int _generationEpoch = 0;

  String? cleanedSvgData; // Store cleaned SVG data if unvisiblePoints is true

  @override
  void initState() {
    super.initState();
    currentRenderProperties = widget.renderPropertiesListenable.value;
    widget.transformationController.addListener(_onTransformationChanged);
    _loadSvg(currentRenderProperties);
  }

  void _loadSvg(final SvgMapRenderProperties renderProperties) {
    currentRenderProperties = renderProperties;

    // if unvisiblePoints is true, clean the SVG content from point elements
    // before loading only when the SVG source is a string.
    cleanedSvgData =
        (widget.unvisiblePoints && renderProperties.source == SvgSource.string)
            ? FloorSvgParser.cleanPointsFromMap(renderProperties.svg as String)
            : renderProperties.svg as String;

    _vectorLoader = switch (renderProperties.source) {
      SvgSource.string => SvgStringLoader(cleanedSvgData!),
      SvgSource.asset => SvgAssetLoader(renderProperties.svg as String),
      SvgSource.compiled => AssetBytesLoader(renderProperties.svg as String),
    };
    _loadedSvg = renderProperties.svg;
    _loadedSource = renderProperties.source;
    _loadedQuality = renderProperties.quality;
    _loadedHiddenPoints = widget.unvisiblePoints;
    _pictureFuture = null;
    _clearCache(notify: false);
  }

  Future<PictureInfo> _loadPicture(final BuildContext context) =>
      _pictureFuture ??= vg.loadPicture(_vectorLoader, context);

  @override
  void didUpdateWidget(final TiledSvgMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController.removeListener(
        _onTransformationChanged,
      );
      widget.transformationController.addListener(_onTransformationChanged);
    }
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<SvgMapRenderProperties>(
        valueListenable: widget.renderPropertiesListenable,
        builder: (final context, final renderProperties, final _) {
          final sourceChanged = renderProperties.svg != _loadedSvg ||
              renderProperties.source != _loadedSource ||
              widget.unvisiblePoints != _loadedHiddenPoints;
          if (sourceChanged) {
            _loadSvg(renderProperties);
          }

          if (renderProperties.quality != _loadedQuality) {
            currentRenderProperties = renderProperties;
            _loadedQuality = renderProperties.quality;
            _clearCache(notify: false);
          }

          currentRenderProperties = renderProperties;

          return FutureBuilder<PictureInfo>(
            future: _loadPicture(context),
            builder: (final context, final snapshot) {
              if (!snapshot.hasData) {
                return renderProperties.loading ?? const SizedBox();
              }

              final pictureInfo = snapshot.data!;

              // size of the original SVG content (1:1 scale)
              final mapContentSize = pictureInfo.size;
              // size of the area to fill with the map.
              final displaySize = renderProperties.size!;

              // Scale to fit the entire map content into the display area.
              final double fitScale =
                  (displaySize.width / mapContentSize.width) <
                          (displaySize.height / mapContentSize.height)
                      ? displaySize.width / mapContentSize.width
                      : displaySize.height / mapContentSize.height;

              // Use the renderProperties.quality as rasterScale
              final double rasterScale = renderProperties.quality;

              // Determine which tiles are needed and trigger generation.
              _checkAndUpdateTiles(
                mapContentSize,
                displaySize,
                fitScale,
                rasterScale,
                pictureInfo,
              );

              return SizedBox(
                width: displaySize.width,
                height: displaySize.height,
                child: FittedBox(
                  child: SizedBox(
                    width: mapContentSize.width,
                    height: mapContentSize.height,
                    // Wrap ONLY the painter so it listens to tile updates
                    child: ValueListenableBuilder<int>(
                      valueListenable: _tileUpdateNotifier,
                      builder: (final context, final _, final __) =>
                          CustomPaint(
                        size: mapContentSize,
                        painter: _SvgTilePainter(
                          tileCache: _tileCache,
                          tileSize: _tileSize,
                          gridScale: rasterScale,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

  bool _isGeneratingTiles = false; // Add this flag to class

  void _checkAndUpdateTiles(
    final Size mapContentSize,
    final Size displaySize,
    final double initialFitScale,
    final double rasterScale,
    final PictureInfo pictureInfo,
  ) {
    if (_isGeneratingTiles) {
      return;
    }

    final matrix = widget.transformationController.value;
    // Get the current zoom scale from the parent InteractiveViewer matrix.
    final double zoomScale = matrix.getMaxScaleOnAxis();

    // Calculate how much FittedBox scaled the map
    final double fitScaleX = displaySize.width / mapContentSize.width;
    final double fitScaleY = displaySize.height / mapContentSize.height;
    final double fitScale = initialFitScale == 0
        ? (fitScaleX < fitScaleY ? fitScaleX : fitScaleY)
        : initialFitScale;

    // calculates the "Centering Offset" added by FittedBox
    // is the extra space on the left/top when the map is smaller than the screen
    final double offsetX =
        (displaySize.width - (mapContentSize.width * fitScale)) / 2;
    final double offsetY =
        (displaySize.height - (mapContentSize.height * fitScale)) / 2;

    // Scales map coordinates to current zoom, including fit-to-screen scale.
    final double totalScale = zoomScale * fitScale;

    // This aligns the "Map Zero" with the "Screen Zero"
    final double adjustedTx = matrix.getTranslation().x + (offsetX * zoomScale);
    final double adjustedTy = matrix.getTranslation().y + (offsetY * zoomScale);

    // Determine visible area in map coordinates by inverting the transform.
    final Rect visibleRect = Rect.fromLTRB(
      -adjustedTx / totalScale,
      -adjustedTy / totalScale,
      (-adjustedTx + displaySize.width) / totalScale,
      (-adjustedTy + displaySize.height) / totalScale,
    );

    // Calculate logical tile size in map coordinates.
    final double logicalTileSize = _tileSize / rasterScale;
    final int totalCols =
        (mapContentSize.width * rasterScale / _tileSize).ceil();
    final int totalRows =
        (mapContentSize.height * rasterScale / _tileSize).ceil();

    // Define the range of tiles that intersect with the visible area

    // floor for the start (left/top) to include any tile that the edge
    final int startCol =
        (visibleRect.left / logicalTileSize).floor().clamp(0, totalCols - 1);
    final int startRow =
        (visibleRect.top / logicalTileSize).floor().clamp(0, totalRows - 1);
    // ceil for the end (right/bottom) to include any tile that the edge
    final int endCol =
        (visibleRect.right / logicalTileSize).ceil().clamp(0, totalCols) - 1;
    final int endRow =
        (visibleRect.bottom / logicalTileSize).ceil().clamp(0, totalRows) - 1;

    // Keep tiles within a x-tile radius of the current view
    // TODO: Allow caller to configure this radius
    // Adjust this value to keep more tiles around the edges
    const int colDelta = 1;
    const int rowDelta = 1;
    _pruneCache(startCol, endCol, startRow, endRow, colDelta, rowDelta);

    // Determine whether the visible tiles are already generated.
    bool needsGeneration = false;
    for (int x = startCol; x <= endCol; x++) {
      for (int y = startRow; y <= endRow; y++) {
        final key = _TileKey(x, y, rasterScale);
        if (!_tileCache.containsKey(key) && !_pendingTiles.contains(key)) {
          needsGeneration = true;
          break;
        }
      }
      if (needsGeneration) {
        break;
      }
    }

    // Only generate if needed
    if (needsGeneration) {
      _isGeneratingTiles = true;
      final generationEpoch = _generationEpoch;

      // Generate tiles asynchronously
      Future.microtask(() async {
        try {
          for (int x = startCol; x <= endCol; x++) {
            for (int y = startRow; y <= endRow; y++) {
              final key = _TileKey(x, y, rasterScale);
              if (_tileCache.containsKey(key) || _pendingTiles.contains(key)) {
                continue;
              }
              _pendingTiles.add(key);
              await _generateTile(
                x,
                y,
                rasterScale,
                pictureInfo,
                generationEpoch,
              );
            }
          }
        } finally {
          _isGeneratingTiles = false;
        }
      });
    }
  }

  Future<void> _generateTile(
    final int col,
    final int row,
    final double scale,
    final PictureInfo pictureInfo,
    final int generationEpoch,
  ) async {
    final key = _TileKey(col, row, scale);

    // Render the specific SVG tile area to an image at the required scale.
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..clipRect(Rect.fromLTWH(0, 0, _tileSize, _tileSize))
      ..save()
      ..translate(-(col * _tileSize), -(row * _tileSize))
      ..scale(scale)
      ..drawPicture(pictureInfo.picture)
      ..restore();

    // Build the image and store it in the cache
    final image = await recorder
        .endRecording()
        .toImage(_tileSize.toInt(), _tileSize.toInt());

    _pendingTiles.remove(key);

    if (!mounted || generationEpoch != _generationEpoch) {
      image.dispose();
      return;
    }

    _tileCache[key]?.dispose();
    _tileCache[key] = image;
    _tileUpdateNotifier.value++; // Signal the painter to repaint
  }

  final ValueNotifier<int> _tileUpdateNotifier = ValueNotifier(0);

  void _onTransformationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearCache({final bool notify = true}) {
    _generationEpoch++;
    _pendingTiles.clear();
    for (final img in _tileCache.values) {
      img.dispose();
    }
    _tileCache.clear();
    if (notify && mounted) {
      _tileUpdateNotifier.value++;
    }
  }

  void _pruneCache(
    final int startCol,
    final int endCol,
    final int startRow,
    final int endRow,
    final int colDelta,
    final int rowDelta,
  ) {
    // Keep tiles within a x-tile radius of the current view
    _tileCache.removeWhere((final key, final image) {
      final bool isFar = key.col < startCol - colDelta ||
          key.col > endCol + colDelta ||
          key.row < startRow - rowDelta ||
          key.row > endRow + rowDelta;
      if (isFar) {
        image.dispose();
      }
      return isFar;
    });
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onTransformationChanged);
    _clearCache();
    _tileUpdateNotifier.dispose();
    super.dispose();
  }
}

class _SvgTilePainter extends CustomPainter {
  final Map<_TileKey, ui.Image> tileCache;
  final double tileSize;
  final double gridScale;

  _SvgTilePainter({
    required this.tileCache,
    required this.tileSize,
    required this.gridScale,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..filterQuality = ui.FilterQuality.high;

    // Draw background to show map area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF5F5F5),
    );

    tileCache.forEach((final key, final image) {
      final double x = (key.col * tileSize) / gridScale;
      final double y = (key.row * tileSize) / gridScale;
      final double tileLogicalSize = tileSize / gridScale;

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, tileSize, tileSize), // Source (the high-res tile)
        Rect.fromLTWH(
          x,
          y,
          tileLogicalSize,
          tileLogicalSize,
        ), // Destination (the map area)
        paint,
      );
    });
  }

  @override
  bool shouldRepaint(final _SvgTilePainter oldDelegate) =>
      oldDelegate.tileCache != tileCache ||
      oldDelegate.tileSize != tileSize ||
      oldDelegate.gridScale != gridScale;
}
