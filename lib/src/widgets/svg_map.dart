import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart';

enum RenderStrategy { picture, raster }

enum SvgSource { string, asset, compiled }

class SvgMapRenderProperties {
  dynamic svgData;
  SvgSource svgSource;
  Size? mapSize;
  RenderingStrategy renderingStrategy;
  Widget? loadingPlaceholder;

  double renderquality = 1.0;

  SvgMapRenderProperties({
    required this.svgData,
    required this.svgSource,
    required this.mapSize,
    this.loadingPlaceholder,
    this.renderquality = 5.0,
    final RenderStrategy? renderingStrategy = RenderStrategy.raster,
  }) : renderingStrategy = renderingStrategy == RenderStrategy.raster
            ? RenderingStrategy.raster
            : RenderingStrategy.picture;

  SvgMapRenderProperties copyWith({
    final dynamic? svgData,
    final SvgSource? svgSource,
    final Size? mapSize,
    final Widget? loadingPlaceholder,
    final double? renderquality,
    final RenderStrategy? renderingStrategy,
  }) =>
      SvgMapRenderProperties(
        svgSource: svgSource ?? this.svgSource,
        svgData: svgData ?? this.svgData,
        mapSize: mapSize ?? this.mapSize,
        renderquality: renderquality ?? this.renderquality,
        loadingPlaceholder: loadingPlaceholder ?? this.loadingPlaceholder,
        renderingStrategy: renderingStrategy ??
            (this.renderingStrategy == RenderingStrategy.raster
                ? RenderStrategy.raster
                : RenderStrategy.picture),
      );

  dynamic get svg => svgData;
  SvgSource get source => svgSource;
  Size? get size => mapSize;
  double get quality => renderquality;
  RenderingStrategy get strategy => renderingStrategy;
  Widget? get loading => loadingPlaceholder;

  set svg(final svg) => svgData = svg;
  set size(final Size? size) => mapSize = size;
  set source(final SvgSource strategy) => svgSource = strategy;
  set strategy(final RenderingStrategy strategy) =>
      renderingStrategy = strategy;
  set loading(final Widget? widget) => loadingPlaceholder = widget;
  set quality(final double quality) => renderquality = quality;
}

class SvgMap extends StatefulWidget {
  final ValueListenable<SvgMapRenderProperties> renderPropertiesListenable;

  const SvgMap.listenable(this.renderPropertiesListenable, {super.key});

  @override
  State<SvgMap> createState() => _SvgMapState();
}

class _SvgMapState extends State<SvgMap> {
  late BytesLoader _vectorLoader;
  late SvgMapRenderProperties currentRenderProperties;

  @override
  void initState() {
    super.initState();
    currentRenderProperties = widget.renderPropertiesListenable.value;

    _loadSvg();
  }

  void _loadSvg() {
    _vectorLoader = switch (currentRenderProperties.source) {
      SvgSource.string => SvgStringLoader(currentRenderProperties.svg),
      SvgSource.asset => SvgAssetLoader(currentRenderProperties.svg),
      SvgSource.compiled => AssetBytesLoader(currentRenderProperties.svg),
    };
  }

  @override
  // ignore: prefer_expression_function_bodies
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<SvgMapRenderProperties>(
      valueListenable: widget.renderPropertiesListenable,
      // ignore: prefer_expression_function_bodies
      builder: (final context, final renderProperties, final _) {
        if (renderProperties.svg != currentRenderProperties.svg) {
          currentRenderProperties.svg = renderProperties.svg;
          _loadSvg();
        }
        return Center(
          // RepaintBoundary to cache the resulting bitmap.
          child: RepaintBoundary(
            // Key forces a fresh raster snapshot when signalValue changes
            key: ValueKey(
              'svg_raster_${widget.renderPropertiesListenable.value.hashCode}',
            ),
            child: SvgPicture(
              _vectorLoader,
              width: renderProperties.size?.height,
              height: renderProperties.size?.height,
              renderingStrategy: renderProperties.renderingStrategy,
            ),
          ),
        );
      },
    );
  }
}

/// A [BytesLoader] that loads a [Uint8List] of binary vector graphics data
/// (the .vg format) directly from memory.
class VectorGraphicBufferLoader extends BytesLoader {
  const VectorGraphicBufferLoader(this.bytes);

  final Uint8List bytes;

  @override
  // ignore: lines_longer_than_80_chars
  Future<ByteData> loadBytes(final BuildContext? context) async =>
      ByteData.sublistView(bytes);

  @override
  int get hashCode => bytes.hashCode;

  @override
  // ignore: lines_longer_than_80_chars
  bool operator ==(final Object other) =>
      other is VectorGraphicBufferLoader && other.bytes == bytes;
}
