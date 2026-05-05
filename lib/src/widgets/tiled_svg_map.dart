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
  // Tile size in pixels (logical size, not scaled)
  final double _tileSize = 512.0; // Power of 2 for better GPU performance

  @override
  void initState() {
    super.initState();
    currentRenderProperties = widget.renderPropertiesListenable.value;
    widget.transformationController.addListener(_onTransformationChanged);
    _loadSvg();
  }

  void _onTransformationChanged() {
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

  Future<void> _generateTile(
      int col, int row, double scale, PictureInfo pictureInfo) async {
    final key = _TileKey(col, row, scale);
    if (_tileCache.containsKey(key)) return;

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

          return FutureBuilder<PictureInfo>(
            future: vg.loadPicture(_vectorLoader, context),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return renderProperties.loading ?? const SizedBox();

              final pictureInfo = snapshot.data!;

              // MAP CONTENT SIZE: The actual SVG content dimensions
              final Size mapContentSize =
                  pictureInfo.size; // Size(840.8, 917.1)

              // DISPLAY SIZE: The window/screen size where we show the map
              final Size displaySize =
                  renderProperties.size ?? mapContentSize; // Size(800.0, 544.0)

              // Calculate scale to fit the entire map in the display area
              final double scaleX = displaySize.width / mapContentSize.width;
              final double scaleY = displaySize.height / mapContentSize.height;
              final double fitScale = (scaleX < scaleY ? scaleX : scaleY) *
                  0.95; // 95% to add padding

              debugPrint('Map content size: $mapContentSize');
              debugPrint('Display size: $displaySize');
              debugPrint('Fit scale: $fitScale');

              const double rasterScale = 5.0;

              // Generate tiles based on MAP CONTENT SIZE at rasterScale
              int cols =
                  (mapContentSize.width * rasterScale / _tileSize).ceil();
              int rows =
                  (mapContentSize.height * rasterScale / _tileSize).ceil();

              debugPrint('Generating $cols x $rows tiles');

              // Generate ALL tiles for the complete map
              for (int x = 0; x < cols; x++) {
                for (int y = 0; y < rows; y++) {
                  _generateTile(x, y, rasterScale, pictureInfo);
                }
              }

              // The widget is sized to display size, but content is the full map
              return SizedBox(
                width: displaySize.width,
                height: displaySize.height,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: mapContentSize.width,
                    height: mapContentSize.height,
                    child: CustomPaint(
                      size: mapContentSize,
                      painter: SvgTilePainter(
                        tileCache: _tileCache,
                        tileSize: _tileSize,
                        gridScale: rasterScale,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

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
        Rect.fromLTWH(0, 0, tileSize, tileSize),
        Rect.fromLTWH(x, y, tileLogicalSize, tileLogicalSize),
        paint,
      );
    });
  }

  @override
  bool shouldRepaint(SvgTilePainter oldDelegate) => true;
}
