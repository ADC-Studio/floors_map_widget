<!-- markdownlint-disable MD041 MD033 -->

<br>

<div align="center">
    <h1 align="center">Floors Map Widget</h1>
    <p align="center">
        <strong>
        This widget allow you to create an interactive floors map from an SVG image.
        </strong>
    </p>

[![build](https://img.shields.io/github/actions/workflow/status/ADC-Studio/floors_map_widget/build.yml)](https://github.com/ADC-Studio/floors_map_widget/actions)
[![release](https://img.shields.io/pub/v/floors_map_widget)](https://github.com/hydralauncher/hydra/releases)

[![ru](https://img.shields.io/badge/lang-ru-yellow.svg)](README.ru.md)

<p align="center">
        <img src="https://github.com/user-attachments/assets/546c6ba6-98e1-477c-afe0-8febdba6da8c" alt="Logo" />
</p>
</div>

## Table of Contents

- [About the Project](#about-the-project)
- [Features](#features)
- [How to Use](#how-to-use)
- [How to Contribute](#how-to-contribute)

## About the Project

This widget allows you to create an interactive floor map based on an SVG image.

## Features

- Generation of an interactive map based on an SVG image.
- Creating and visualizing routes between different points.
- Configuring interactions when clicking on a block.
- Tiled SVG rendering for smoother work with large maps.
- Optional tile debug overlay for inspecting visible tile ranges and cache
  behavior during development.

## Supported Object Classes

- shop
- parkingspace
- atmmachine
- toilet
- stairs

### Toilet SubTypes

- male
- female
- mother_and_child

### Stairs SubTypes

- simple
- fire_escape
- escalator
- elevator

## How to Use

Working with the library is divided into several stages.

- [Adding Route Points](#stage-1---adding-route-points)
- [Assigning Correct IDs to Room Objects](#stage-2---assigning-correct-ids-to-room-objects)
- [Integrating the Library into Your Project](#stage-3---integrating-the-library-into-your-project)

### Stage 1 - Adding Route Points

Using Figma or any other SVG editor, create a floor map or use an existing one.
Now, you need to prepare this map to work with FloorMapWidget. You need to set route points and entrance points to room objects. You can use the ready-made Figma extension [here](https://github.com/ADC-Studio/FloorsMapWidgetFigmaExtension) or do it manually.

#### Figma Extension

Place the points and connect them into routes. You can read a more detailed description [here](https://github.com/ADC-Studio/FloorsMapWidgetFigmaExtension).

![MapPluginExample](https://github.com/user-attachments/assets/2a780fb4-5541-4334-a229-a7577a65b730)

#### Manual Implementation

You can use either a circle shape or a custom shape using a path. Point binding occurs using the id attribute. For example, in this example, we created a point in two ways and connected it to three neighboring points.

```text
point-43=44-39-45
│     │  └‒‒└‒‒└‒‒‒‒‒ unique IDs of connected neighbors
│     └‒‒‒‒‒ unique ID of the object
└‒‒‒‒‒ class of the object - point
```

```svg
<circle id="point-43=44-39-45" cx="4.5" cy="4.5" r="4.5" fill="black"/>
```

```svg
<path id="point-43=44-39-45" d="M4.2 8.39999C6.52 8.39999 8.39999 6.52 8.39999 4.2C8.39999 1.88 6.52 0 4.2 0C1.88 0 0 1.88 0 4.2C0 6.52 1.88 8.39999 4.2 8.39999Z" fill="black"/>
```

### Stage 2 - Assigning Correct IDs to Room Objects

You can see the supported objects here.
The rules for creating IDs are the same as for Point.

```Text
shop-1=2
│    │ └‒‒‒‒‒ unique ID of the connected entrance point (there can be only one)
│    └‒‒‒‒‒ unique ID of the object
└‒‒‒‒‒ class of the object
```

```Text
stairs-elevator-1=2
│      │        │ └‒‒‒‒‒ unique ID of the connected entrance point (there can be only one)
│      │        └‒‒‒‒‒ unique ID of the object
│      └‒‒‒‒‒ subtype of the object (required for stairs and toilet)
└‒‒‒‒‒ class of the object
```

#### Ready Example

```svg
<path id="shop-3=5" d="M477.648 206.928H428.712V323.772H565.44V315H569.448V235.404H481.044H477.648V231.996V206.928Z" fill="#EEF9FE" />
```

### Stage 3 - Integrating the Library into Your Project

Add the library to your project and embed the ready widget containing the necessary parameters.

```Dart
FloorMapWidget(
  // String from SVG Map
  _svgContent,
  // Floor widgets
  _listWidgets,
  // Optional: parsed route points. If omitted, FloorMapWidget parses them.
  listPoints: _listPoints,
  // Use to build a route
  startIdPoint: _startPointItem?.idPoint,
  endIdPoint: _endPointItem?.idPoint,
  // Use to remove point markers from SVG string rendering
  unvisiblePoints: true,
),
```

By default, the widget renders the SVG through the tiled renderer. This keeps
the map layer independent from interactive item overlays and reduces repeated
raster work while panning and zooming.

For development, enable the tile debug overlay:

```dart
FloorMapWidget(
  _svgContent,
  _listWidgets,
  debugTiles: true,
)
```

The debug panel is pinned to the top-right corner of the app overlay and can be
collapsed by tapping it. It shows the currently displayed/visible tile count,
visible tile range, effective/requested raster scale, cached and pending tiles,
cache hits/misses, generated tiles, and pruned tiles.

For advanced zoom-quality control, pass your own `TransformationController` and
`ValueNotifier<SvgMapRenderProperties>`:

```dart
final transformationController = TransformationController();
final renderPropertiesNotifier = ValueNotifier(
  SvgMapRenderProperties(
    svgData: svgContent,
    svgSource: SvgSource.string,
    mapSize: null,
    renderingStrategy: RenderStrategy.picture,
  ),
);

FloorMapWidget(
  svgContent,
  itemWidgets,
  listPoints: points,
  transformationController: transformationController,
  renderPropertiesNotifier: renderPropertiesNotifier,
)
```

#### FloorMapWidget parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| `svgContent` | `String` | Yes | Raw SVG markup used by the default string source. |
| `listItemsWidgets` | `List<FloorItemWidget>` | Yes | Interactive item overlays rendered above the map layer. |
| `listPoints` | `List<FloorPoint>?` | No | Parsed route points. If omitted, they are parsed from `svgContent`. |
| `renderPropertiesNotifier` | `ValueNotifier<SvgMapRenderProperties>?` | No | External map render state for advanced SVG source, quality, and loading control. |
| `transformationController` | `TransformationController?` | No | Shared controller for the parent `InteractiveViewer` and tiled renderer. |
| `unvisiblePoints` | `bool` | No | Removes point markers from string SVG rendering. Defaults to `false`. |
| `debugTiles` | `bool` | No | Enables the collapsible tile debug overlay. Defaults to `false`. |
| `startIdPoint` | `int?` | No | Start route point id. |
| `endIdPoint` | `int?` | No | End route point id. |

#### SvgMapRenderProperties parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `svgData` | `Object` | Required | Raw SVG string, SVG asset path, or compiled vector graphic asset path. |
| `svgSource` | `SvgSource` | Required | Source kind: `SvgSource.string`, `SvgSource.asset`, or `SvgSource.compiled`. |
| `mapSize` | `Size?` | Required | Render size. `FloorMapWidget` keeps it in sync with its layout constraints. |
| `loadingPlaceholder` | `Widget?` | `null` | Widget shown while the SVG picture is loading. |
| `renderquality` | `double` | `5` | Requested tile raster quality. The tiled renderer caps the effective quality to the current viewport scale. |
| `renderingStrategy` | `RenderStrategy?` | `RenderStrategy.raster` | `flutter_svg` rendering strategy used by the SVG loader. |

To add interactive objects to the map, initialize them with `FloorItemWidget`
and pass the resulting list to `FloorMapWidget`.

```Dart
FloorItemWidget(
    // FloorItem
    item: element,
    // Function (FloorItem)
    onTap: _handleFloorItemTap,
    // An example of how to change the color of an
    // interaction animation
    selectedColor: Colors.orange[200]!.withOpacity(0.5),
    // An example of how to turn on an object's blinking
    // Thanks to this, you can highlight some objects on the map.
    // For example toilets or ATM
    isActiveBlinking: false,
),
```

#### FloorItemWidget parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `item` | `FloorItem` | Required | Parsed interactive object from the SVG. |
| `onTap` | `Future<void> Function(FloorItem)?` | `null` | Called when the object is tapped. |
| `durationTapAnimation` | `Duration` | `50ms` | Tap highlight animation duration. |
| `durationBlink` | `Duration` | `1s` | Blinking highlight animation duration. |
| `isActiveBlinking` | `bool` | `false` | Enables repeated blinking highlight. |
| `selectedColor` | `Color?` | `null` | Highlight color. Falls back to a default translucent color. |
| `parentSize` | `Size?` | `null` | Parent map size. Usually set by `FloorMapWidget` automatically. |

You can get the objects using FloorSvgParser.

```Dart
final parser = FloorSvgParser(svgContent: svgContent);
// You can get anchor points from the map
final listPoints = parser.getPoints();
// You can get all objects supported by the library
final listItems = parser.getItems();
```

For more information, visit the Example with prepared code and map [example](/example/README.md).

![Example](https://github.com/user-attachments/assets/db2ae074-69e9-4e20-81b3-ce831daa5ae8)

## How to Contribute

To get started, read [CONTRIBUTING.md](CONTRIBUTING.md) to learn about the guidelines within this project.

## Changelog

[Refer to the Changelog to get all release notes.](/CHANGELOG.md)

## Maintainers

[LOGION](https://logion-mobile.com)

[Valerij Shishov](https://github.com/MixKage) |
[Arthur Lokhov](https://github.com/i4ox) |
[Brdn Velazquez](https://github.com/Brnd08)

This library is open for issues and pull requests. If you have ideas for improvements or bugs, the repository is open to contributions!
