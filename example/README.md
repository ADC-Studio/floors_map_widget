# This is an example of using a widget FloorMapWidget

## An example of how you can initialize the parser and create a list of interactive widgets

```Dart
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
```

## One example of how you can easily find the necessary interactive object

```Dart
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
```

## Displaying the map on the screen

``` Dart
// Use for zoom and move
InteractiveViewer( 
    child: FloorItemWidget(
    // String from SVG Map
    _svgContent,
    // Floors widgets
    _listWidgets,
    // Use for build a route
    startIdPoint: _startPointItem?.idPoint,
    endIdPoint: _endPointItem?.idPoint, 
    // Use for remove points from svg
    unvisiblePoints: true,
    ),
),
```
