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
  final TransformationController transformationController; // Add this

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

  // High-level cache for our generated tiles
  final Map<_TileKey, ui.Image> _tileCache = {};
  final double _tileSize = 500.0; // Standard tile size for GPU stability

  @override
  void initState() {
    super.initState();
    currentRenderProperties = widget.renderPropertiesListenable.value;
    widget.transformationController.addListener(_onTransformationChanged);

    _loadSvg();
  }

  void _onTransformationChanged() {
    // This will be called frequently during pan/zoom.
    // The triggerVisibleTiles logic inside the FutureBuilder will handle the rest.
    setState(() {});
  }

  void _loadSvg() {
    _vectorLoader = switch (currentRenderProperties.source) {
      SvgSource.string => SvgStringLoader(currentRenderProperties.svg),
      SvgSource.asset => SvgAssetLoader(currentRenderProperties.svg),
      SvgSource.compiled => AssetBytesLoader(currentRenderProperties.svg),
    };
    _clearCache();
  }

  void _clearCache() {
    for (var img in _tileCache.values) {
      img.dispose();
    }
    _tileCache.clear();
  }

  /// The engine room: Extracts a specific section of the SVG as a ui.Image
  Future<void> _generateTile(
      int col, int row, double scale, PictureInfo pictureInfo) async {
    final key = _TileKey(col, row, scale);
    if (_tileCache.containsKey(key)) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)

    // 1. Clip and Save state
    ..clipRect(Rect.fromLTWH(0, 0, _tileSize, _tileSize))
    ..save() // <--- SAVE HERE

    // 2. Transform and draw the SVG section
    ..translate(-(col * _tileSize), -(row * _tileSize)) // Use pixel units
    ..scale(scale)
    ..drawPicture(pictureInfo.picture)

    ..restore(); // <--- RESTORE HERE to reset coordinates to (0,0) of the tile

    // 3. Draw debug info (Now it stays in the same spot on every tile)
    final debugPaint = Paint()
      ..color = const Color(0x80FF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, _tileSize, _tileSize), debugPaint);

    TextPainter(
        text: TextSpan(
          text: 'Tile: $col,$row',
          style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 28,
              backgroundColor: Color(0x80FFFFFF)),
        ),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: _tileSize)
      ..paint(canvas, const Offset(20, 20));

    final image = await recorder
        .endRecording()
        .toImage(_tileSize.toInt(), _tileSize.toInt());

    if (mounted) setState(() => _tileCache[key] = image);
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<SvgMapRenderProperties>(
        valueListenable: widget.renderPropertiesListenable,
        builder: (context, renderProperties, _) {
          if (renderProperties.svg != currentRenderProperties.svg) {
            currentRenderProperties = renderProperties;
            _loadSvg();
          }

          // We use FutureBuilder to get the ui.Picture once
          return FutureBuilder<PictureInfo>(
            future: vg.loadPicture(_vectorLoader, context),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return renderProperties.loading ?? const SizedBox();

              final pictureInfo = snapshot.data!;
              // Use the parent's size (from LayoutBuilder) as the logical base
              final visualSize = currentRenderProperties.size!;
              final logicalSize = renderProperties.size ?? pictureInfo.size;

              // The "Internal Scale" is how much we multiply the logical size
              // to get our target high-res version.
              // For a 512px tile system, if your map is 1000px, a scale of 2.0
              // means a 2000px virtual canvas.
              const double rasterScale = 5.0;

              // Trigger the generation using the internal scale
              _triggerVisibleTiles(logicalSize, rasterScale, pictureInfo);

              return SizedBox(
                width: logicalSize.width,
                height: logicalSize.height,
                child: CustomPaint(
                  painter: SvgTilePainter(
                    tileCache: _tileCache,
                    tileSize: _tileSize,
                    gridScale: rasterScale, // This is the 'rasterScale'
                  ),
                ),
              );
            },
          );
        },
      );

  void _triggerVisibleTiles(Size logicalSize, double scale, PictureInfo info) {
    final Matrix4 matrix = widget.transformationController.value;

    // Calculate the visible bounds in logical coordinates
    // We divide by the current zoom level to see the "world" coordinates
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double viewportWidth =
        currentRenderProperties.size!.width / currentScale;
    final double viewportHeight =
        currentRenderProperties.size!.height / currentScale;

    final double localX = -matrix.getTranslation().x / currentScale;
    final double localY = -matrix.getTranslation().y / currentScale;

    final Rect viewport =
        Rect.fromLTWH(localX, localY, viewportWidth, viewportHeight);

    // Buffer: Increase viewport slightly to preload tiles just off-screen
    final Rect bufferedViewport = viewport.inflate(_tileSize / scale);

    int cols = (logicalSize.width * scale / _tileSize).ceil();
    int rows = (logicalSize.height * scale / _tileSize).ceil();

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        final tileRect = Rect.fromLTWH(
          (x * _tileSize) / scale,
          (y * _tileSize) / scale,
          _tileSize / scale,
          _tileSize / scale,
        );

        if (bufferedViewport.overlaps(tileRect)) {
          _generateTile(x, y, scale, info);
        }
      }
    }
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

    tileCache.forEach((key, image) {
      // Calculate the top-left position where this tile belongs in logical pixels
      final double x = (key.col * tileSize) / gridScale;
      final double y = (key.row * tileSize) / gridScale;

      // Draw the tile scaled back down to logical size
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, tileSize, tileSize),
        Rect.fromLTWH(x, y, tileSize / gridScale, tileSize / gridScale),
        paint,
      );
    });
  }

  @override
  bool shouldRepaint(SvgTilePainter oldDelegate) => true;
}
