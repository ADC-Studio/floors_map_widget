import 'dart:ui';

import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:floors_map_widget/src/core/parser/path_instruction.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xml.dart';

/// FloorSvgParser is responsible for parsing SVG content that
/// represents floor maps. It extracts essential information
/// such as the SVG dimensions, floor number, path data,
/// colors (stroke and fill), and various floor elements like points,
/// shops, parking spaces, ATMs, toilets, and stairs. The parser processes
/// SVG elements to construct drawable paths and organizes floor items
/// with their properties, enabling the creation of interactive
/// and detailed floor map widgets.
class FloorSvgParser {
  final String svgContent;
  late Size svgSize;
  late int? floorNumber;
  late final xml.XmlDocument document;

  /// Constructor for FloorSvgParser.
  ///
  /// [svgContent]: The SVG content as a string.
  /// [floorNumber]: Optional floor number. If not provided,
  /// it will be extracted from the SVG.
  FloorSvgParser({required this.svgContent, this.floorNumber}) {
    // Parse the SVG content into an XML document.
    document = xml.XmlDocument.parse(svgContent);
    // Extract the dimensions of the SVG.
    svgSize = _getDimensions();
    // If floorNumber is not provided, extract it from the SVG.
    floorNumber = floorNumber ?? _getFloorNumber();
  }

  /// Converts a hexadecimal color string to a [Color] object.
  ///
  /// Returns `null` if the input is 'none'.
  Color? _colorFromHex(final String hexString) {
    if (hexString.trim().toLowerCase() == 'none') {
      return null;
    }

    // Predefined color names mapped to their hex values.
    const colorMap = {
      'black': '#000000',
      'white': '#FFFFFF',
      'red': '#FF0000',
      'green': '#00FF00',
      'blue': '#0000FF',
      'yellow': '#FFFF00',
      'cyan': '#00FFFF',
      'magenta': '#FF00FF',
    };

    final colorName = hexString.trim().toLowerCase();

    // If the color name exists in the map, recursively convert it.
    if (colorMap.containsKey(colorName)) {
      final hex = colorMap[colorName]!;
      return _colorFromHex(hex);
    }

    // Convert hex string to Color, adding alpha if necessary.
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      // e.g., #RRGGBB
      buffer.write('FF'); // Add full opacity.
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Extracts the x and y coordinates from a SVG path 'd' attribute.
  ///
  /// Assumes the path starts with a 'M' command followed by x and y values.
  Map<String, String> getCoordinatesFromPath(final String pathData) {
    final regex = RegExp(r'M(\d+\.\d+)\s(\d+)');
    final data = regex.firstMatch(pathData);
    return {
      'x': data!.group(1)!,
      'y': data.group(2)!,
    };
  }

  /// Parses the SVG path data and constructs a [Path] object.
  Path parsePathData(final String pathData) {
    final path = Path();
    final commands = _parsePathCommands(pathData);

    double currentX = 0;
    double currentY = 0;

    for (final command in commands) {
      switch (command.command) {
        case 'M':
          currentX = command.coordinates![0];
          currentY = command.coordinates![1];
          path.moveTo(currentX, currentY);
        case 'L':
          currentX = command.coordinates![0];
          currentY = command.coordinates![1];
          path.lineTo(currentX, currentY);
        case 'H':
          currentX = command.coordinates![0];
          path.lineTo(currentX, currentY);
        case 'V':
          currentY = command.coordinates![0];
          path.lineTo(currentX, currentY);
        case 'C':
          path.cubicTo(
            command.coordinates![0],
            command.coordinates![1],
            command.coordinates![2],
            command.coordinates![3],
            command.coordinates![4],
            command.coordinates![5],
          );
          currentX = command.coordinates![4];
          currentY = command.coordinates![5];
        case 'Z':
          path.close();
        default:
          throw FloorParserSvgException(
            'Unknown command: ${command.command}. Allowed commands: MLHVCZ',
          );
      }
    }
    return path;
  }

  /// Parses the SVG path commands from the path data string.
  ///
  /// Returns a list of [PathInstruction] objects.
  List<PathInstruction> _parsePathCommands(final String pathData) {
    final regex = RegExp(r'([MLHVCZ])\s*([^A-Za-z]*)');

    final List<PathInstruction> pathDataMap = [];

    // Iterate through all matches of the regex in the path data.
    for (final match in regex.allMatches(pathData)) {
      if (match.group(1) != null &&
          (match.group(1)!.toLowerCase().trim() == 'z' ||
              match.group(2) != null)) {
        try {
          pathDataMap.add(
            PathInstruction(
              match.group(1)!,
              match.group(1)!.toLowerCase().trim() == 'z'
                  ? []
                  : match
                      .group(2)!
                      .split(RegExp(r'\s+'))
                      .map(double.parse)
                      .toList(),
            ),
          );
        } catch (e) {
          throw FloorParserSvgException('Error parsing path commands: $e');
        }
      }
    }

    return pathDataMap;
  }

  /// Retrieves the dimensions (width and height) of the SVG.
  Size _getDimensions() {
    final svgElement = document.findElements('svg').first;
    final width = double.parse(svgElement.getAttribute('width') ?? '0');
    final height = double.parse(svgElement.getAttribute('height') ?? '0');
    return Size(width, height);
  }

  /// Extracts the floor number from the SVG's 'id' attribute.
  int _getFloorNumber() {
    final svgElement = document.findElements('svg').first;
    final String fullKey = svgElement.getAttribute('id') ?? '';
    try {
      return int.parse(fullKey.substring(fullKey.indexOf('-') + 1).trim());
    } catch (e) {
      throw FloorParserSvgException(
          'SVG ID does not contain a valid floor number. Extracted value: '
          '"${fullKey.substring(fullKey.indexOf('-') + 1).trim()}"');
    }
  }

  /// Retrieves the [Path] object for a given element [key].
  ///
  /// Throws an exception if the element is not found.
  Path getPaths(final String key) {
    final pathElements = document.findAllElements('path');

    for (final pathElement in pathElements) {
      if (pathElement.getAttribute('id') != key) {
        continue;
      }

      final d = pathElement.getAttribute('d') ?? '';
      return parsePathData(d);
    }
    throw FloorParserSvgException(
      'Element with id "$key" not found in getPaths.',
    );
  }

  /// Retrieves the stroke color for a given element [key].
  ///
  /// Returns `null` if the stroke attribute is not defined.
  Color? getColorStroke(final String key) {
    final pathElements = document.findAllElements('path');

    for (final pathElement in pathElements) {
      if (pathElement.getAttribute('id') != key) {
        continue;
      }

      final stroke = pathElement.getAttribute('stroke');
      if (stroke == null) {
        return null;
      }
      return _colorFromHex(stroke);
    }
    return null;
  }

  /// Retrieves the fill color for a given element [key].
  ///
  /// Returns `null` if the fill attribute is not defined.
  Color? getColorFill(final String key) {
    final pathElements = document.findAllElements('path');

    for (final pathElement in pathElements) {
      if (pathElement.getAttribute('id') != key) {
        continue;
      }

      final fill = pathElement.getAttribute('fill');
      if (fill == null) {
        return null;
      }
      return _colorFromHex(fill);
    }
    return null;
  }

  /// Extracts all floor points from the SVG.
  ///
  /// Throws an exception if no route anchor points are found.
  List<FloorPoint> getPoints() {
    final List<FloorPoint> pointList = [];

    // Recursive function to traverse XML elements.
    void traverseElements(final XmlElement element) {
      if (element.name.local == 'circle' || element.name.local == 'path') {
        final String fullKey = (element.getAttribute('id') ?? '').trim();
        // Check if the id contains '-', '=', and 'point'.
        if (!fullKey.contains('-') ||
            !fullKey.contains('=') ||
            !fullKey.contains('point')) {
          return;
        }

        late final String x;
        late final String y;

        if (element.name.local == 'circle') {
          // For circle elements, extract 'cx' and 'cy' attributes.
          x = (element.getAttribute('cx') ?? '').trim();
          y = (element.getAttribute('cy') ?? '').trim();
        } else {
          // For path elements, extract coordinates from the 'd' attribute.
          final coords =
              getCoordinatesFromPath(element.getAttribute('d') ?? '');
          x = coords['x'] ?? '';
          y = coords['y'] ?? '';
        }

        final List<String> parts = fullKey.split('=');
        final String keyMainType = parts[0].split('-')[0];
        final int keyId = int.parse(parts[0].split('-')[1]);
        final List<int> neighbours =
            parts[1].split('-').map(int.parse).toList();

        if (!keyMainType.toLowerCase().trim().contains('point')) {
          return;
        }

        pointList.add(
          FloorPoint(
            id: keyId,
            floor: floorNumber!,
            x: double.parse(x),
            y: double.parse(y),
            neighbours: neighbours,
            sizeParentSvg: svgSize,
          ),
        );
      }

      // Recursively traverse child elements.
      element.children.whereType<XmlElement>().forEach(traverseElements);
    }

    // Start traversal from the root element.
    traverseElements(document.rootElement);

    if (pointList.isEmpty) {
      throw const FloorParserSvgException(
        'This map has no route anchor points.',
      );
    }
    return pointList;
  }

  /// Extracts all floor items (shops, parking, ATMs and more) from the SVG.
  ///
  /// Throws an exception if no such elements are found.
  List<FloorItem> getItems() {
    final List<FloorItem> floorItems = [];

    // Recursive function to process XML elements.
    void processElement(final XmlElement element) {
      final String fullKey = (element.getAttribute('id') ?? '').trim();

      // Skip elements that do not contain '-', '=', or are not 'path' elements.
      if (!fullKey.contains('-') ||
          !fullKey.contains('=') ||
          element.name.local != 'path') {
        element.children.whereType<XmlElement>().forEach(processElement);
        return;
      }

      final List<String> mainParts = fullKey.split('=');
      final List<String> partsWithoutPoint = mainParts[0].split('-');
      final String keyMainType = partsWithoutPoint[0];

      // Skip if the main type is 'point'.
      if (keyMainType == 'point') {
        element.children.whereType<XmlElement>().forEach(processElement);
        return;
      }

      late final int keyId;
      late final int pointId;

      try {
        keyId = int.parse(partsWithoutPoint[partsWithoutPoint.length - 1]);
        pointId = int.parse(mainParts[1]);
      } on Exception {
        throw FloorParserSvgException(
          'ID object must be an integer. Examples: '
          '"shop-1=1" or "toilet-male-1=30". Got: "$fullKey".',
        );
      }

      // Check if the main type is supported.
      if (!SupportedClasses.regexpCheckSupported.hasMatch(keyMainType)) {
        return;
      }
      final drawingInstructions = DrawingInstructions(
        clickableArea: getPaths(fullKey),
        sizeParentSvg: svgSize,
        // TODO: Add colorFill and colorStroke configuration.
        // colorFill: getColorFill(fullKey),
        // colorStroke: getColorStroke(fullKey),
      );
      // Create the appropriate FloorItem based on the main type.
      switch (SupportedClasses.fromString(keyMainType)) {
        case SupportedClasses.shop:
          floorItems.add(
            FloorShop(
              key: keyId,
              floor: floorNumber!,
              idPoint: pointId,
              drawingInstructions: drawingInstructions,
            ),
          );
        case SupportedClasses.parkingSpace:
          floorItems.add(
            FloorParkingSpace(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: drawingInstructions,
              floor: floorNumber!,
            ),
          );
        case SupportedClasses.atmMachine:
          floorItems.add(
            FloorAtmMachine(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: drawingInstructions,
              floor: floorNumber!,
            ),
          );
        case SupportedClasses.toilet:
          floorItems.add(
            FloorHygieneZone(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: drawingInstructions,
              floor: floorNumber!,
              subType: FloorHygieneZoneType.fromString(partsWithoutPoint[1]),
            ),
          );
        case SupportedClasses.stairs:
          floorItems.add(
            FloorStairs(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: drawingInstructions,
              floor: floorNumber!,
              subType: FloorStairsType.fromString(partsWithoutPoint[1]),
            ),
          );
        // Handle unsupported classes.
        // ignore: no_default_cases
        default:
          throw FloorParserSvgException(
            'Unsupported class type: '
            '${SupportedClasses.fromString(keyMainType)}',
          );
      }

      // Recursively process child elements.
      element.children.whereType<XmlElement>().forEach(processElement);
    }

    // Start processing from the root element.
    processElement(document.rootElement);

    if (floorItems.isEmpty) {
      throw const FloorParserSvgException(
        'This map has no elements (e.g., stores, '
        'stairs, toilets). Example: "shop-1=3".',
      );
    }

    return floorItems;
  }
}
