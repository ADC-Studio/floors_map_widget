import 'dart:math';
import 'dart:ui' as ui;
import 'package:floors_map_widget/floors_map_widget.dart'
    show SvgMapRenderProperties;
import 'package:floors_map_widget/src/widgets/svg_map.dart' show SvgSource;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

class _TileKey {
  final int col, row;
  final double scale;
  _TileKey(this.col, this.row, this.scale);

  @override
  String toString() => '${col}_${row}_$scale';
  @override
  bool operator ==(Object other) =>
      other is _TileKey &&
      col == other.col &&
      row == other.row &&
      scale == other.scale;
  @override
  int get hashCode => Object.hash(col, row, scale);
}

class TiledSvgMap extends StatefulWidget {
  final ValueListenable<SvgMapRenderProperties> renderPropertiesListenable;
  final TransformationController transformationController;

  const TiledSvgMap.listenable(
    this.renderPropertiesListenable,
    this.transformationController, {
    super.key,
  });

  @override
  State<TiledSvgMap> createState() => _TiledSvgMapState();
}

class _TiledSvgMapState extends State<TiledSvgMap> {
  late BytesLoader _vectorLoader;
  late SvgMapRenderProperties currentRenderProperties;

  final Map<_TileKey, ui.Image> _tileCache = {};
  final double _tileSize = 512.0; //  of 2^n for better GPU performance

  double _lastQuality = 1.0;

  @override
  void initState() {
    super.initState();
    currentRenderProperties = widget.renderPropertiesListenable.value;
    _lastQuality = currentRenderProperties.quality;
    widget.transformationController.addListener(_onTransformationChanged);
    _loadSvg();
  }

  void _loadSvg() {
    _vectorLoader = switch (currentRenderProperties.source) {
      SvgSource.string => SvgStringLoader(currentRenderProperties.svg),
      SvgSource.asset => SvgAssetLoader(currentRenderProperties.svg),
      SvgSource.compiled => AssetBytesLoader(currentRenderProperties.svg),
    };
    _clearCache();
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<SvgMapRenderProperties>(
        valueListenable: widget.renderPropertiesListenable,
        builder: (context, renderProperties, _) {
          // Only update if SVG source changed
          if (renderProperties.svg != currentRenderProperties.svg) {
            currentRenderProperties = renderProperties;
            _loadSvg();
          }

          // Check if quality changed
          if (renderProperties.quality != _lastQuality) {
            currentRenderProperties = renderProperties;
            _lastQuality = renderProperties.quality;
            _clearCache();
          }

          currentRenderProperties = renderProperties;

          return FutureBuilder<PictureInfo>(
            future: vg.loadPicture(_vectorLoader, context),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return renderProperties.loading ?? const SizedBox();

              final pictureInfo = snapshot.data!;
              final Size mapContentSize = pictureInfo.size;
              final Size displaySize = renderProperties.size ?? mapContentSize;

              final double fitScale =
                  (displaySize.width / mapContentSize.width <
                          displaySize.height / mapContentSize.height)
                      ? displaySize.width / mapContentSize.width
                      : displaySize.height / mapContentSize.height;

              // Use the renderProperties.quality as rasterScale
              final double rasterScale = renderProperties.quality;

              print(
                  'FitScale: $fitScale, RasterScale: $rasterScale, DisplaySize: $displaySize, MapContentSize: $mapContentSize');
              // IMPORTANT: Call this only ONCE, and check if we need to generate
              _checkAndUpdateTiles(mapContentSize, displaySize, fitScale,
                  rasterScale, pictureInfo);

              return SizedBox(
                width: displaySize.width,
                height: displaySize.height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: mapContentSize.width,
                    height: mapContentSize.height,
                    // Wrap ONLY the painter so it listens to tile updates
                    child: ValueListenableBuilder<int>(
                      valueListenable: _tileUpdateNotifier,
                      builder: (context, _, __) => CustomPaint(
                        size: mapContentSize,
                        painter: SvgTilePainter(
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

  void _checkAndUpdateTiles(Size mapContentSize, Size displaySize,
      double fitScale, double rasterScale, PictureInfo pictureInfo) {
    if (_isGeneratingTiles) return;

    final matrix = widget.transformationController.value;
    final double zoomScale = matrix.getMaxScaleOnAxis();

    // 1. Calculate how much FittedBox scaled the map
    final double fitScaleX = displaySize.width / mapContentSize.width;
    final double fitScaleY = displaySize.height / mapContentSize.height;
    final double fitScale = fitScaleX < fitScaleY ? fitScaleX : fitScaleY;

    // 2. Calculate the "Centering Offset" added by FittedBox
    // This is the extra space on the left/top when the map is smaller than the screen
    final double offsetX =
        (displaySize.width - (mapContentSize.width * fitScale)) / 2;
    final double offsetY =
        (displaySize.height - (mapContentSize.height * fitScale)) / 2;

    final double totalScale = zoomScale * fitScale;

    // 3. ADJUST TRANSLATION: Subtract the offset from the raw tx/ty
    // This aligns the "Map Zero" with the "Screen Zero"
    final double adjustedTx = matrix.getTranslation().x + (offsetX * zoomScale);
    final double adjustedTy = matrix.getTranslation().y + (offsetY * zoomScale);

    final Rect visibleRect = Rect.fromLTRB(
      -adjustedTx / totalScale,
      -adjustedTy / totalScale,
      (-adjustedTx + displaySize.width) / totalScale,
      (-adjustedTy + displaySize.height) / totalScale,
    );

    // Calculate visible bounds in map coordinates
    // Calculate tile dimensions
    final double logicalTileSize = _tileSize / rasterScale;
    int totalCols = (mapContentSize.width * rasterScale / _tileSize).ceil();
    int totalRows = (mapContentSize.height * rasterScale / _tileSize).ceil();

    print(
        'VisibleRect: $visibleRect, ZoomScale: $zoomScale, TotalScale: $totalScale, LogicalTileSize: $logicalTileSize, TotalCols: $totalCols, TotalRows: $totalRows');

// 2. Map coordinates to indices (No buffers for now to test accuracy)
// Use (rect / logicalSize) to get the exact fractional index

// Use floor for the start (left/top) to capture the tile the edge is inside

    int startCol =
        (visibleRect.left / logicalTileSize).floor().clamp(0, totalCols - 1);

    int startRow =
        (visibleRect.top / logicalTileSize).floor().clamp(0, totalRows - 1);

// Use ceil for the end (right/bottom) to capture the tile the edge is inside
// We subtract 1 at the end because ceil() on a perfect boundary (e.g., 5.0)
// would give us the next tile index we don't need.
    int endCol =
        (visibleRect.right / logicalTileSize).ceil().clamp(0, totalCols) - 1;
    int endRow =
        (visibleRect.bottom / logicalTileSize).ceil().clamp(0, totalRows) - 1;

    print('VISIBLE INDEX RANGE: Col $startCol-$endCol, Row $startRow-$endRow');

    // Keep tiles within a 2-tile radius of the current view
    _pruneCache(startCol, endCol, startRow, endRow, 1, 1);

    // Check which tiles are missing
    bool needsGeneration = false;
    for (int x = startCol; x <= endCol; x++) {
      for (int y = startRow; y <= endRow; y++) {
        final key = _TileKey(x, y, rasterScale);
        if (!_tileCache.containsKey(key)) {
          needsGeneration = true;
          break;
        }
      }
      if (needsGeneration) break;
    }

    // Only generate if needed
    if (needsGeneration) {
      _isGeneratingTiles = true;

      // Generate tiles asynchronously
      Future.microtask(() async {
        for (int x = startCol; x <= endCol; x++) {
          for (int y = startRow; y <= endRow; y++) {
            final key = _TileKey(x, y, rasterScale);
            if (_tileCache.containsKey(key)) continue;
            print('Tiling: Generating ($x, $y), scale $rasterScale');
            _generateTile(x, y, rasterScale, pictureInfo);
          }
        }
        _isGeneratingTiles = false;
      });
    }
  }

  Future<void> _generateTile(
      int col, int row, double scale, PictureInfo pictureInfo) async {
    final key = _TileKey(col, row, scale);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..clipRect(Rect.fromLTWH(0, 0, _tileSize, _tileSize))
      ..save()
      ..translate(-(col * _tileSize), -(row * _tileSize))
      ..scale(scale)
      ..drawPicture(pictureInfo.picture)
      ..restore();

    // Debug overlay
    final debugPaint = Paint()
      ..color = const Color(0x40FF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, _tileSize, _tileSize), debugPaint);

    TextPainter(
        text: TextSpan(
          text: '$col,$row',
          style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 24,
              backgroundColor: Color(0x80FFFFFF)),
        ),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: _tileSize)
      ..paint(canvas, const Offset(10, 10));

    final image = await recorder
        .endRecording()
        .toImage(_tileSize.toInt(), _tileSize.toInt());

    if (mounted) {
      _tileCache[key] = image;
      _tileUpdateNotifier.value++; // Signal the painter to repaint
    }
  }

  final ValueNotifier<int> _tileUpdateNotifier = ValueNotifier(0);

  void _onTransformationChanged() {
    setState(() {});
  }

  void _clearCache() {
    for (var img in _tileCache.values) {
      img.dispose();
    }
    _tileCache.clear();
  }

  void _pruneCache(int startCol, int endCol, int startRow, int endRow,
      int colDelta, int rowDelta) {
    // Keep tiles within a 2-tile radius of the current view
    _tileCache.removeWhere((key, image) {
      final bool isFar = key.col < startCol - colDelta ||
          key.col > endCol + colDelta ||
          key.row < startRow - rowDelta ||
          key.row > endRow + rowDelta;
      if (isFar) {
        print("Tiling: Disposing tile (${key.col}, ${key.row})");
        image.dispose();
      }
      return isFar;
    });
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onTransformationChanged);
    _clearCache();
    super.dispose();
  }
}

class SvgTilePainter extends CustomPainter {
  final Map<_TileKey, ui.Image> tileCache;
  final double tileSize;
  final double gridScale;

  SvgTilePainter({
    required this.tileCache,
    required this.tileSize,
    required this.gridScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = ui.FilterQuality.high;

    // Draw background to show map area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF5F5F5),
    );

    tileCache.forEach((key, image) {
      final double x = (key.col * tileSize) / gridScale;
      final double y = (key.row * tileSize) / gridScale;
      final double tileLogicalSize = tileSize / gridScale;

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, tileSize, tileSize), // Source (the high-res tile)
        Rect.fromLTWH(x, y, tileLogicalSize,
            tileLogicalSize), // Destination (the map area)
        paint,
      );
    });
  }

  @override
  bool shouldRepaint(SvgTilePainter oldDelegate) => true;
}
