import 'package:example/widgets/example_bottom_sheet.dart';
import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// To make the example easier to understand,
// no state management libraries were used.
final class SvgMapExample extends StatefulWidget {
  const SvgMapExample({
    super.key,
  });

  @override
  State<SvgMapExample> createState() => _SvgMapExampleState();
}

class _SvgMapExampleState extends State<SvgMapExample> {
  // To simplify the example, we are not using state libraries,
  // so if the variable is null, the loading widget will be shown
  String? _svgContent;
  // Map elements sheet
  List<FloorItemWidget> _listWidgets = [];
  // Points to build a route
  FloorItem? _startPointItem;
  FloorItem? _endPointItem;
  List<FloorPoint>? points;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<FloorItem>? items;
  late ValueNotifier<SvgMapRenderProperties> renderPropertiesNotifier;
  // final ValueNotifier<bool> reRenderTooggle = ValueNotifier(false);

  final TransformationController _transformationController =
      TransformationController();

  double renderQualityt = 1 / 1;
  double lastScale = 1.0;

  void _onScaleEnd(final ScaleEndDetails details) {
    final double currentScale =
        _transformationController.value.getMaxScaleOnAxis();

    if (currentScale == lastScale) {
      return; // No change in scale, so no need to update
    }

    // Calculate desired quality based on zoom level
    double newQuality;

    if (currentScale <= 1.0) {
      newQuality = 1.0;
    } else if (currentScale <= 3.0) {
      newQuality = 1.0;
    } else if (currentScale <= 12.0) {
      newQuality = 5.0;
    } else {
      newQuality = 8.0;
    }

    // Only update if quality actually changed
    if (newQuality != renderPropertiesNotifier.value.quality) {
      renderPropertiesNotifier.value = renderPropertiesNotifier.value.copyWith(
        renderquality: newQuality,
      );
      renderQualityt = newQuality; // Store quality instead of direction
      lastScale = currentScale; // Store current scale for next comparison
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();

    // _initializeMap();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      final svgContent = await rootBundle.loadString(
        'assets/frutras_y_hortalizas_full_coors_optimized_no_groups.svg',
      );
      const compiledSVGAsset =
          'assets/frutras_y_hortalizas_full_coors_optimized_no_groups.vg';
      // await rootBundle.loadString(
      //     'assets/frutras_y_hortalizas_full_coors_optimized_no_groups.svg');
      // Parser initialization
      final parser = FloorSvgParser(svgContent: svgContent);
      // You can get anchor points from the map
      // ignore: unused_local_variable
      points ??= parser.getPoints();
      // You can get all objects supported by the library
      items ??= parser.getItems();
      final listItems = parser.getItems();
      // We create FloorItemWidget based on FloorItem
      final listWidgets = listItems
          .map(
            (final element) => FloorItemWidget(
              element,
              onTap: _handleFloorItemTap,
              // An example of how to change the color of an
              // interaction animation
              selectedColor: Colors.orange[200]!.withValues(alpha: 0.5),
              // An example of how to turn on an object's blinking
              // Thanks to this, you can highlight some objects on the map.
              // For example toilets or ATM
              // ignore: avoid_redundant_argument_values
              isActiveBlinking: false,
            ),
          )
          .toList();

      // Updating received data on UI
      setState(
        () {
          _svgContent = svgContent;
          _listWidgets = listWidgets;
          _startPointItem = null;
          _endPointItem = null;

          renderPropertiesNotifier = ValueNotifier(
            SvgMapRenderProperties(
              mapSize: null,
              svgData: compiledSVGAsset,
              svgSource: SvgSource.compiled,
              renderingStrategy: RenderStrategy.picture,
              renderquality: renderQualityt,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error initial map: $e');

      // fail fast
      rethrow;
    }
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        key: _scaffoldKey,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildFloatingActionButtons(context),
        appBar: AppBar(
          title: const Text('Example Map Widget'),
        ),
        body: _svgContent == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  onInteractionEnd: _onScaleEnd,
                  maxScale: 20,
                  minScale: 1,
                  child: RepaintBoundary(
                    child: FloorMapWidget(
                      // String from SVG Map
                      _svgContent!,
                      // Floors widgets
                      _listWidgets,
                      points!,
                      renderPropertiesNotifier: renderPropertiesNotifier,
                      transformationController: _transformationController,
                      // Use for build a route
                      startIdPoint: _startPointItem?.idPoint,
                      endIdPoint: _endPointItem?.idPoint,
                      // Use for remove points from svg (not longer used)
                      unvisiblePoints: true,
                    ),
                  ),
                ),
              ),
      );

  Widget _buildFloatingActionButtons(final BuildContext context) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => searchObjects<FloorShop>(),
                icon: const Icon(Icons.store),
              ),
              IconButton(
                onPressed: () => searchObjects<FloorHygieneZone>(
                  subType: FloorHygieneZoneType.maleRoom,
                ),
                icon: const Icon(Icons.wc),
              ),
              IconButton(
                onPressed: () => searchObjects<FloorHygieneZone>(
                  subType: FloorHygieneZoneType.motherAndChildRoom,
                ),
                icon: const Icon(Icons.child_care),
              ),
              IconButton(
                onPressed: () => searchObjects<FloorStairs>(
                  subType: FloorStairsType.escalator,
                ),
                icon: const Icon(Icons.escalator),
              ),
              IconButton(
                onPressed: () => searchObjects<FloorStairs>(
                  subType: FloorStairsType.elevator,
                ),
                icon: const Icon(Icons.elevator),
              ),
              IconButton(
                onPressed: () => searchObjects<FloorAtmMachine>(),
                icon: const Icon(Icons.atm),
              ),
              IconButton(
                onPressed: _initializeMap,
                icon: const Icon(Icons.cancel),
              ),
            ],
          ),
        ),
      );

  // An example of how to turn on an object's blinking
  void searchObjects<T extends FloorItem>({final FloorSubTypes? subType}) {
    _listWidgets = _listWidgets.map((final item) {
      if (item.item is T && (subType == null || subType == item.item.subType)) {
        return item.copyWith(isActiveBlinking: true);
      }

      return item.copyWith(isActiveBlinking: false);
    }).toList();

    setState(() {});
  }

  // An example of obtaining information and building a route
  Future<void> _handleFloorItemTap(final FloorItem floorItem) async {
    await ExampleBottomSheet.showBottomSheet(
      context,
      floorItem,
      () => _setStartPoint(floorItem),
      () => _setEndPoint(floorItem),
    );
  }

  void _setStartPoint(final FloorItem floorItem) {
    setState(() {
      _startPointItem = floorItem;
    });
  }

  void _setEndPoint(final FloorItem floorItem) {
    setState(() {
      _endPointItem = floorItem;
    });
  }
}

void main() async {
  runApp(
    const MaterialApp(
      home: SvgMapExample(),
    ),
  );
}
