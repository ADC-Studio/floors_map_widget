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

class _TileDebugInfo {
  final int cachedTiles;
  final int pendingTiles;
  final int displayedTiles;
  final int visibleTiles;
  final int generatedTiles;
  final int prunedTiles;
  final int cacheHits;
  final int cacheMisses;
  final String visibleRange;
  final double requestedRasterScale;
  final double effectiveRasterScale;

  const _TileDebugInfo({
    required this.cachedTiles,
    required this.pendingTiles,
    required this.displayedTiles,
    required this.visibleTiles,
    required this.generatedTiles,
    required this.prunedTiles,
    required this.cacheHits,
    required this.cacheMisses,
    required this.visibleRange,
    required this.requestedRasterScale,
    required this.effectiveRasterScale,
  });

  @override
  bool operator ==(final Object other) =>
      other is _TileDebugInfo &&
      cachedTiles == other.cachedTiles &&
      pendingTiles == other.pendingTiles &&
      displayedTiles == other.displayedTiles &&
      visibleTiles == other.visibleTiles &&
      generatedTiles == other.generatedTiles &&
      prunedTiles == other.prunedTiles &&
      cacheHits == other.cacheHits &&
      cacheMisses == other.cacheMisses &&
      visibleRange == other.visibleRange &&
      requestedRasterScale == other.requestedRasterScale &&
      effectiveRasterScale == other.effectiveRasterScale;

  @override
  int get hashCode => Object.hash(
        cachedTiles,
        pendingTiles,
        displayedTiles,
        visibleTiles,
        generatedTiles,
        prunedTiles,
        cacheHits,
        cacheMisses,
        visibleRange,
        requestedRasterScale,
        effectiveRasterScale,
      );
}

class TiledSvgMap extends StatefulWidget {
  // Provides the current SVG source, size, quality, and loading widget.
  final ValueListenable<SvgMapRenderProperties> renderPropertiesListenable;
  // Parent InteractiveViewer controller used to calculate visible tiles.
  final TransformationController transformationController;
  final bool unvisiblePoints;
  final bool debugTiles;

  const TiledSvgMap.listenable(
    this.renderPropertiesListenable,
    this.transformationController, {
    super.key,
    this.unvisiblePoints = false,
    this.debugTiles = false,
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
  Set<_TileKey> _visibleTileKeys = {};
  final double _tileSize = 512; // Power of two for better GPU performance.
  int _generationEpoch = 0;
  int _tileVersion = 0;
  int _generatedTiles = 0;
  int _prunedTiles = 0;
  int _debugDisplayedTiles = 0;
  int _debugVisibleTiles = 0;
  int _debugCacheHits = 0;
  int _debugCacheMisses = 0;
  String _debugVisibleRange = 'none';
  double _requestedRasterScale = 1;
  double _effectiveRasterScale = 1;
  double? _activeRasterScale;
  OverlayEntry? _debugOverlayEntry;
  bool _isDebugPanelExpanded = true;
  bool _debugOverlaySyncScheduled = false;
  bool _debugOverlayBuildScheduled = false;
  bool _needsTileUpdateAfterGeneration = false;

  String? cleanedSvgData; // Store cleaned SVG data if unvisiblePoints is true

  @override
  void initState() {
    super.initState();
    currentRenderProperties = widget.renderPropertiesListenable.value;
    widget.transformationController.addListener(_onTransformationChanged);
    _loadSvg(currentRenderProperties);
    _syncDebugOverlay();
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
    _resetDebugStats();
    _clearCache(notify: false);
  }

  _TileDebugInfo get _debugInfo => _TileDebugInfo(
        cachedTiles: _tileCache.length,
        pendingTiles: _pendingTiles.length,
        displayedTiles: _debugDisplayedTiles,
        visibleTiles: _debugVisibleTiles,
        generatedTiles: _generatedTiles,
        prunedTiles: _prunedTiles,
        cacheHits: _debugCacheHits,
        cacheMisses: _debugCacheMisses,
        visibleRange: _debugVisibleRange,
        requestedRasterScale: _requestedRasterScale,
        effectiveRasterScale: _effectiveRasterScale,
      );

  void _resetDebugStats() {
    _generatedTiles = 0;
    _prunedTiles = 0;
    _debugDisplayedTiles = 0;
    _debugVisibleTiles = 0;
    _debugCacheHits = 0;
    _debugCacheMisses = 0;
    _debugVisibleRange = 'none';
    _requestedRasterScale = 1;
    _effectiveRasterScale = 1;
    _visibleTileKeys = {};
  }

  void _notifyTilesChanged() {
    _tileVersion++;
    _tileUpdateNotifier.value = _tileVersion;
    _markDebugOverlayNeedsBuild();
  }

  void _debugLog(final String message) {
    if (widget.debugTiles && kDebugMode) {
      debugPrint('TiledSvgMap: $message');
    }
  }

  void _syncDebugOverlay() {
    if (_debugOverlaySyncScheduled) {
      return;
    }
    _debugOverlaySyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _debugOverlaySyncScheduled = false;
      if (!mounted) {
        return;
      }
      if (!widget.debugTiles) {
        _removeDebugOverlay();
        return;
      }

      final overlay = Overlay.of(context, rootOverlay: true);
      _debugOverlayEntry ??= OverlayEntry(
        builder: (final context) => _TileDebugOverlay(
          debugInfo: _debugInfo,
          isExpanded: _isDebugPanelExpanded,
          onToggle: _toggleDebugPanel,
        ),
      );

      if (_debugOverlayEntry!.mounted) {
        _debugOverlayEntry!.markNeedsBuild();
      } else {
        overlay.insert(_debugOverlayEntry!);
      }
    });
  }

  void _markDebugOverlayNeedsBuild() {
    if (!widget.debugTiles || _debugOverlayBuildScheduled) {
      return;
    }
    _debugOverlayBuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _debugOverlayBuildScheduled = false;
      if (mounted &&
          widget.debugTiles &&
          (_debugOverlayEntry?.mounted ?? false)) {
        _debugOverlayEntry?.markNeedsBuild();
      }
    });
  }

  void _toggleDebugPanel() {
    _isDebugPanelExpanded = !_isDebugPanelExpanded;
    _debugOverlayEntry?.markNeedsBuild();
  }

  void _removeDebugOverlay() {
    _debugOverlayEntry?.remove();
    _debugOverlayEntry = null;
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
    _syncDebugOverlay();
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<SvgMapRenderProperties>(
        valueListenable: widget.renderPropertiesListenable,
        builder: (final context, final renderProperties, final _) {
          _syncDebugOverlay();

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

              final requestedRasterScale = renderProperties.quality;
              final rasterScale = _effectiveRasterScaleForViewport(
                requestedRasterScale: requestedRasterScale,
                fitScale: fitScale,
                zoomScale:
                    widget.transformationController.value.getMaxScaleOnAxis(),
                devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
              );
              _setActiveRasterScale(
                requestedRasterScale: requestedRasterScale,
                effectiveRasterScale: rasterScale,
              );

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
                    child: ValueListenableBuilder<int>(
                      valueListenable: _tileUpdateNotifier,
                      builder: (final context, final tileVersion, final __) =>
                          CustomPaint(
                        size: mapContentSize,
                        painter: _SvgTilePainter(
                          tileCache: _tileCache,
                          tileSize: _tileSize,
                          gridScale: rasterScale,
                          tileVersion: tileVersion,
                          repaint: _tileUpdateNotifier,
                          debugTiles: widget.debugTiles,
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

  bool _isGeneratingTiles = false;

  double _effectiveRasterScaleForViewport({
    required final double requestedRasterScale,
    required final double fitScale,
    required final double zoomScale,
    required final double devicePixelRatio,
  }) {
    if (requestedRasterScale <= 0) {
      return 1;
    }

    final screenRasterScale = fitScale * zoomScale * devicePixelRatio;
    final quantizedScale = (screenRasterScale * 2).ceilToDouble() / 2;
    final upperScale = quantizedScale < 0.5 ? 0.5 : quantizedScale;
    return requestedRasterScale.clamp(0.5, upperScale);
  }

  void _setActiveRasterScale({
    required final double requestedRasterScale,
    required final double effectiveRasterScale,
  }) {
    _requestedRasterScale = requestedRasterScale;
    _effectiveRasterScale = effectiveRasterScale;

    if (_activeRasterScale == effectiveRasterScale) {
      return;
    }

    _activeRasterScale = effectiveRasterScale;
    _isGeneratingTiles = false;
    _clearCache(notify: false);
    _markDebugOverlayNeedsBuild();
  }

  void _checkAndUpdateTiles(
    final Size mapContentSize,
    final Size displaySize,
    final double initialFitScale,
    final double rasterScale,
    final PictureInfo pictureInfo,
  ) {
    if (_isGeneratingTiles) {
      _needsTileUpdateAfterGeneration = true;
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
    _debugVisibleRange = 'cols $startCol-$endCol, rows $startRow-$endRow';

    // Keep tiles within a x-tile radius of the current view
    // TODO: Allow caller to configure this radius
    // Adjust this value to keep more tiles around the edges
    const int colDelta = 1;
    const int rowDelta = 1;
    _pruneCache(startCol, endCol, startRow, endRow, colDelta, rowDelta);

    // Determine whether the visible tiles are already generated.
    bool needsGeneration = false;
    int cacheHits = 0;
    int cacheMisses = 0;
    int displayedTiles = 0;
    final visibleTileKeys = <_TileKey>{};
    for (int x = startCol; x <= endCol; x++) {
      for (int y = startRow; y <= endRow; y++) {
        final key = _TileKey(x, y, rasterScale);
        visibleTileKeys.add(key);
        if (_tileCache.containsKey(key)) {
          displayedTiles++;
          cacheHits++;
        } else if (_pendingTiles.contains(key)) {
          cacheHits++;
        } else {
          cacheMisses++;
          needsGeneration = true;
        }
      }
    }
    _visibleTileKeys = visibleTileKeys;
    _debugDisplayedTiles = displayedTiles;
    _debugVisibleTiles = visibleTileKeys.length;
    _debugCacheHits = cacheHits;
    _debugCacheMisses = cacheMisses;
    _debugLog(
      '$_debugVisibleRange, hits: $cacheHits, misses: $cacheMisses, '
      'cached: ${_tileCache.length}, pending: ${_pendingTiles.length}, '
      'raster: $rasterScale/${currentRenderProperties.quality}',
    );
    _markDebugOverlayNeedsBuild();

    // Only generate if needed
    if (needsGeneration) {
      _isGeneratingTiles = true;
      final generationEpoch = _generationEpoch;

      // Generate tiles asynchronously
      Future.microtask(() async {
        try {
          for (int x = startCol; x <= endCol; x++) {
            for (int y = startRow; y <= endRow; y++) {
              if (!mounted || generationEpoch != _generationEpoch) {
                return;
              }
              final key = _TileKey(x, y, rasterScale);
              if (_tileCache.containsKey(key) || _pendingTiles.contains(key)) {
                continue;
              }
              _pendingTiles.add(key);
              _debugLog('generate tile col: $x, row: $y, scale: $rasterScale');
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
          if (generationEpoch == _generationEpoch) {
            _isGeneratingTiles = false;
            _recheckTilesIfNeeded();
          }
        }
      });
    }
  }

  void _recheckTilesIfNeeded() {
    if (!_needsTileUpdateAfterGeneration || !mounted) {
      return;
    }

    _needsTileUpdateAfterGeneration = false;
    setState(() {});
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

    if (!mounted || generationEpoch != _generationEpoch) {
      image.dispose();
      return;
    }

    _pendingTiles.remove(key);
    _tileCache[key]?.dispose();
    _tileCache[key] = image;
    if (_visibleTileKeys.contains(key)) {
      _debugDisplayedTiles =
          _visibleTileKeys.where(_tileCache.containsKey).length;
    }
    _generatedTiles++;
    _notifyTilesChanged();
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
    _debugDisplayedTiles = 0;
    for (final img in _tileCache.values) {
      img.dispose();
    }
    _tileCache.clear();
    if (notify && mounted) {
      _notifyTilesChanged();
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
    int prunedTiles = 0;
    _tileCache.removeWhere((final key, final image) {
      final bool isFar = key.col < startCol - colDelta ||
          key.col > endCol + colDelta ||
          key.row < startRow - rowDelta ||
          key.row > endRow + rowDelta;
      if (isFar) {
        prunedTiles++;
        image.dispose();
      }
      return isFar;
    });
    if (prunedTiles > 0) {
      _prunedTiles += prunedTiles;
      _debugLog('pruned $prunedTiles tiles');
    }
  }

  @override
  void dispose() {
    _removeDebugOverlay();
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
  final int tileVersion;
  final bool debugTiles;

  _SvgTilePainter({
    required this.tileCache,
    required this.tileSize,
    required this.gridScale,
    required this.tileVersion,
    required final Listenable repaint,
    required this.debugTiles,
  }) : super(repaint: repaint);

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..filterQuality = ui.FilterQuality.high;
    final debugBorderPaint = Paint()
      ..color = const Color(0xFFFF3B30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / gridScale.clamp(1, double.infinity);

    // Draw background to show map area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF5F5F5),
    );

    tileCache.forEach((final key, final image) {
      final double x = (key.col * tileSize) / gridScale;
      final double y = (key.row * tileSize) / gridScale;
      final double tileLogicalSize = tileSize / gridScale;
      final tileRect = Rect.fromLTWH(
        x,
        y,
        tileLogicalSize,
        tileLogicalSize,
      );

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, tileSize, tileSize), // Source (the high-res tile)
        tileRect, // Destination (the map area)
        paint,
      );
      if (debugTiles) {
        canvas.drawRect(tileRect, debugBorderPaint);
        _paintText(
          canvas,
          '${key.col},${key.row}\nscale ${key.scale.toStringAsFixed(1)}',
          Offset(tileRect.left + 6 / gridScale, tileRect.top + 6 / gridScale),
          fontSize: 12 / gridScale,
        );
      }
    });
  }

  void _paintText(
    final Canvas canvas,
    final String text,
    final Offset offset, {
    required final double fontSize,
    final Color backgroundColor = const Color(0xCCFFFFFF),
  }) {
    TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF1E1E1E),
          fontSize: fontSize,
          backgroundColor: backgroundColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout(maxWidth: 220)
      ..paint(canvas, offset);
  }

  @override
  bool shouldRepaint(final _SvgTilePainter oldDelegate) =>
      oldDelegate.tileVersion != tileVersion ||
      oldDelegate.tileSize != tileSize ||
      oldDelegate.gridScale != gridScale ||
      oldDelegate.debugTiles != debugTiles;
}

class _TileDebugOverlay extends StatelessWidget {
  final _TileDebugInfo debugInfo;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _TileDebugOverlay({
    required this.debugInfo,
    required this.isExpanded,
    required this.onToggle,
  });

  String get _tileSummary =>
      'tiles: ${debugInfo.displayedTiles}/${debugInfo.visibleTiles}';

  @override
  Widget build(final BuildContext context) => Positioned(
        top: 12,
        right: 12,
        child: SafeArea(
          child: GestureDetector(
            onTap: onToggle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xEFFFFFFF),
                border: Border.all(color: const Color(0xFF1E1E1E)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: isExpanded ? _expandedContent() : _collapsedContent(),
              ),
            ),
          ),
        ),
      );

  Widget _collapsedContent() => Text(
        '$_tileSummary +',
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      );

  Widget _expandedContent() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          '$_tileSummary -\n'
          'visible: ${debugInfo.visibleRange}\n'
          'raster: ${debugInfo.effectiveRasterScale.toStringAsFixed(1)} / '
          '${debugInfo.requestedRasterScale.toStringAsFixed(1)}\n'
          'cache: ${debugInfo.cachedTiles}, '
          'pending: ${debugInfo.pendingTiles}\n'
          'hits: ${debugInfo.cacheHits}, '
          'misses: ${debugInfo.cacheMisses}\n'
          'generated: ${debugInfo.generatedTiles}, '
          'pruned: ${debugInfo.prunedTiles}',
          style: const TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 11,
            height: 1.25,
            decoration: TextDecoration.none,
          ),
        ),
      );
}
