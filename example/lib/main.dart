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

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

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

  Future<void> _initializeMap() async {
    try {
      final svgContent =
          await rootBundle.loadString('assets/map_with_points_example.svg');
      // Parser initialization
      final parser = FloorSvgParser(svgContent: svgContent);
      // You can get anchor points from the map
      // ignore: unused_local_variable
      final listPoints = parser.getPoints();
      // You can get all objects supported by the library
      final listItems = parser.getItems();
      // We create FloorItemWidget based on FloorItem
      final listWidgets = listItems
          .map(
            (final element) => FloorItemWidget(
              item: element,
              onTap: _handleFloorItemTap,
              // An example of how to change the color of an
              // interaction animation
              selectedColor: Colors.orange[200]!.withOpacity(0.5),
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
        },
      );
    } catch (e) {
      debugPrint('Error initial map: $e');
      setState(() {
        _svgContent = null;
      });
    }
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Example Map Widget'),
        ),
        body: _svgContent == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Stack(
                  children: [
                    // Use for zoom and move
                    InteractiveViewer(
                      maxScale: 3,
                      child: FloorMapWidget(
                        // String from SVG Map
                        _svgContent!,
                        // Floors widgets
                        _listWidgets,
                        // Use for build a route
                        startIdPoint: _startPointItem?.idPoint,
                        endIdPoint: _endPointItem?.idPoint,
                        // Use for remove points from svg
                        unvisiblePoints: true,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
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
                  ],
                ),
              ),
      );
}

void main() async {
  runApp(
    const MaterialApp(
      home: SvgMapExample(),
    ),
  );
}
