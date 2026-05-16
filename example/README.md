# Floors Map Widget example

This example shows how to parse an SVG floor map, create interactive objects,
build routes, and render the map through the default tiled renderer.

## Initialize the parser and widgets

```dart
final parser = FloorSvgParser(svgContent: svgContent);

// Route graph points.
final points = parser.getPoints();

// Interactive SVG objects supported by the library.
final items = parser.getItems();

final listWidgets = items
    .map(
      (final element) => FloorItemWidget(
        element,
        onTap: _handleFloorItemTap,
        selectedColor: Colors.orange[200]!.withValues(alpha: 0.5),
        isActiveBlinking: false,
      ),
    )
    .toList();
```

## Search and highlight objects

```dart
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

## Display the map

Use the same `TransformationController` for the parent `InteractiveViewer` and
`FloorMapWidget`. This lets the tiled renderer calculate the visible tile range
from the current pan/zoom matrix.

```dart
final transformationController = TransformationController();
final renderPropertiesNotifier = ValueNotifier(
  SvgMapRenderProperties(
    svgData: svgContent,
    svgSource: SvgSource.string,
    mapSize: null,
    renderingStrategy: RenderStrategy.picture,
    renderquality: renderQuality,
  ),
);

InteractiveViewer(
  transformationController: transformationController,
  onInteractionEnd: _onScaleEnd,
  maxScale: 20,
  minScale: 1,
  child: RepaintBoundary(
    child: FloorMapWidget(
      svgContent,
      listWidgets,
      listPoints: points,
      renderPropertiesNotifier: renderPropertiesNotifier,
      transformationController: transformationController,
      startIdPoint: _startPointItem?.idPoint,
      endIdPoint: _endPointItem?.idPoint,
      unvisiblePoints: true,
      debugTiles: true,
    ),
  ),
);
```

`debugTiles` enables the collapsible overlay with displayed/visible tile count,
visible range, raster scale, cache/pending tiles, hits/misses, generated tiles,
and pruned tiles. Disable it in production.
