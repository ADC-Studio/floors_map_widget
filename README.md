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
        <img src="https://private-user-images.githubusercontent.com/55548743/377865297-be17fe66-f79c-4064-be7e-ce22d8721361.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjkyNTQ2NTEsIm5iZiI6MTcyOTI1NDM1MSwicGF0aCI6Ii81NTU0ODc0My8zNzc4NjUyOTctYmUxN2ZlNjYtZjc5Yy00MDY0LWJlN2UtY2UyMmQ4NzIxMzYxLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDEwMTglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMDE4VDEyMjU1MVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTJjODVjNDNkMjdiMTQ3MDI2NTEyODRkZGM1ODQ4NWIwMWY4YjA1MTAzZTc4ODBjMDBiMmEzY2IxMjQzYzM3NDImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.wrzY67vMeV3mfqvo01XwoNZRQjVDylM8YrWx942PtZo" alt="Logo" />
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

![MapPluginExample](https://private-user-images.githubusercontent.com/55548743/377865309-853cf782-c018-4e22-8694-9fc3cd3f2a98.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjkyNTQ2NTEsIm5iZiI6MTcyOTI1NDM1MSwicGF0aCI6Ii81NTU0ODc0My8zNzc4NjUzMDktODUzY2Y3ODItYzAxOC00ZTIyLTg2OTQtOWZjM2NkM2YyYTk4LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDEwMTglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMDE4VDEyMjU1MVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTFlMjkzMzFjMTAxYmFjMDQzOWRmMjE3N2NmNGU2NDNjNTY1ZjY2YzA3YTFjMmZjZmQ2MGE1ZWI2MGJiZTYyNzcmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.6Xi5ebeQGTtE98sifNbj1GNGFBF3tCxHT4zc7L4QCu4)

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
FloorItemWidget(
    // String from SVG Map
    _svgContent,
    // Floors widgets
    _listWidgets,
    // Use to build a route
    startIdPoint: _startPointItem?.idPoint,
    endIdPoint:_endPointItem?.idPoint,
    // Use to remove points from SVG
    unvisiblePoints: true,
),
```

To add interactive objects to the map, you need to initialize them with the FloorItemWidget and pass them as a list to FloorItemWidget.

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

You can get the objects using FloorSvgParser.

```Dart
final parser = FloorSvgParser(svgContent: svgContent);
// You can get anchor points from the map
final listPoints = parser.getPoints();
// You can get all objects supported by the library
final listItems = parser.getItems();
```

For more information, visit the Example with prepared code and map.

![Example](https://private-user-images.githubusercontent.com/55548743/377865034-1f945a9a-dd47-4941-a6ad-80647f592bbf.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MjkyNTQ2NTEsIm5iZiI6MTcyOTI1NDM1MSwicGF0aCI6Ii81NTU0ODc0My8zNzc4NjUwMzQtMWY5NDVhOWEtZGQ0Ny00OTQxLWE2YWQtODA2NDdmNTkyYmJmLmdpZj9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDEwMTglMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQxMDE4VDEyMjU1MVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWQzNDZhMTc5NzhhNjI0YzdhMTk0M2Y0YzAyNTUzYjY4Y2QzNTMzODUyNGY3YzBhY2Q2MTk3OTc0NWM2YmI4ZTEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.UNJD2GwBmO8sbk7DGQqNETzDjL7EpKVy9SYAPLgLMME)

## How to Contribute

To get started, read [CONTRIBUTING.md](CONTRIBUTING.md) to learn about the guidelines within this project.
