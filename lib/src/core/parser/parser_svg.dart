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
    try {
      // Parse the SVG content into an XML document.
      document = xml.XmlDocument.parse(svgContent);
      // Extract the dimensions of the SVG.
      svgSize = _getDimensions();
      // If floorNumber is not provided, extract it from the SVG.
      floorNumber = floorNumber ?? _getFloorNumber();
    } on FloorParserSvgException {
      rethrow;
    } on Exception catch (e) {
      throw FloorParserSvgException(e.toString(), cause: e);
    }
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
  static final pointPathCoorsRegex = RegExp(r'M ?(-?\d+\.?\d*)[, ]+(-?\d+\.?\d*)');
  /// Extracts the x and y coordinates from a SVG path 'd' attribute.
  ///
  /// Assumes the path starts with a 'M' command followed by x and y values.
  Map<String, String> getCoordinatesFromPath(final String pathData) {
    // Fixed to support cordinates separated by comma ("M 0,708.66 H 868.072 V 0 H 0 Z")
    final data = FloorSvgParser.pointPathCoorsRegex.firstMatch(pathData);
    if (data == null){
      throw FloorParserSvgException('Could not match coordinates from Point path: $pathData. Pattern: ${FloorSvgParser.pointPathCoorsRegex.pattern}');
    }
    final x = data!.group(1);
    final y = data.group(2);
    return {
      'x': x!,
      'y': y!,
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
  static final svgCommandPathRegex = RegExp(r'([MLHVCZ])\s*([^A-Za-z]*)');
  static final svgCommandSeparatorRegex = RegExp(r'\s+|,');
  /// Parses the SVG path commands from the path data string.
  ///
  /// Returns a list of [PathInstruction] objects.
  List<PathInstruction> _parsePathCommands(final String pathData) {

    final List<PathInstruction> pathDataMap = [];

    final svgCommandMatches = FloorSvgParser.svgCommandPathRegex.allMatches(pathData);

    // Iterate through all matches of the regex in the path data.
    for (final match in svgCommandMatches) {
      final String command = match.group(1)!.trim()!; // command group will never be null
      final String coordinatesSegment = (match.group(2)?? '').trim();


      // Skip processing if there are no coordinates and it's not a 'Z' command
      if (command.toLowerCase() != 'z' && coordinatesSegment.trim().isEmpty) {
        // TODO: Check if it is appropiate to stop execution instead of skipping
        continue;
      }

      try {
        // List with all coordinates (x & y) present in the command
        final List<double> coords= command.toLowerCase() == 'z' ? [] 
              : coordinatesSegment!.trim().split(FloorSvgParser.svgCommandSeparatorRegex).map(
                double.parse).toList();

        // Handle abbreviated commands if present
        if (command == 'M' || command == 'm') {
          // Handle abbreviated Move: first pair is M, subsequent pairs are L
          for (int i = 0; i < coords.length; i += 2) {
            final String effectiveCmd = (i == 0) ? command : (command == 'M' ? 'L' : 'l');
            pathDataMap.add(PathInstruction(effectiveCmd, [coords[i], coords[i + 1]]));
          }
        } else if (command == 'L' || command == 'l' || command == 'T' || command == 't') {
          // Expand abbreviated Lines/Smooth Quadratics (pairs of 2)
          for (int i = 0; i < coords.length; i += 2) {
            pathDataMap.add(PathInstruction(command, [coords[i], coords[i + 1]]));
          }
        } else if (command == 'C' || command == 'c') {
          // Expand abbreviated Cubics (groups of 6)
          for (int i = 0; i < coords.length; i += 6) {
            pathDataMap.add(PathInstruction(command, coords.sublist(i, i + 6)));
          }
        } else if (command == 'S' || command == 's' || command == 'Q' || command == 'q') {
          // Expand abbreviated Smooth Cubics/Quadratics (groups of 4)
          for (int i = 0; i < coords.length; i += 4) {
            pathDataMap.add(PathInstruction(command, coords.sublist(i, i + 4)));
          }
        } else {
          // H, V, and Z (or single-param commands)
          pathDataMap.add(PathInstruction(command, coords));
        }
        
      } catch (e) {
        throw FloorParserSvgException('Error parsing path commands: $e');
      }
    
    }

    return pathDataMap;
  }

  /// Retrieves the dimensions (width and height) of the SVG.
  // Size _getDimensions() {
  //   final svgElement = document.findElements('svg').first;
  //   final width = double.parse(svgElement.getAttribute('width') ?? '0');
  //   final height = double.parse(svgElement.getAttribute('height') ?? '0');
  //   return Size(width, height);
  // }
  Size _getDimensions() {
    final svgElement = document.findAllElements('svg').first;
    final viewBox = svgElement.getAttribute('viewBox');

    if (viewBox != null && viewBox.isNotEmpty) {
      // viewBox format: "min-x min-y width height"
      final parts = viewBox.split(RegExp(r'\s+|,')).where((s) => s.isNotEmpty).map(double.parse).toList();
      if (parts.length == 4) {
        // Return the internal coordinate width/height
        return Size(parts[2], parts[3]); 
      }
    }

    double parseDimension(String? raw) {
      if (raw == null || raw.isEmpty) return 0;
      final match = RegExp(r'([\d.]+)').firstMatch(raw);
      if (match == null) return 0;
      final value = double.parse(match.group(1)!);

      // Optionally handle mm/cm/in to px
      if (raw.contains('mm')) return value * 3.7795275591; // 1mm ≈ 3.78px
      if (raw.contains('cm')) return value * 37.795275591;
      if (raw.contains('in')) return value * 96.0;
      return value;
    }

    // Only fallback to width/height if viewBox is missing
    final width = parseDimension(svgElement.getAttribute('width'));
    final height = parseDimension(svgElement.getAttribute('height'));
    return Size(width, height);
  }
//   Size _getDimensions() {
//     final svgElement = document.findElements('svg').first;

//     double parseDimension(String? raw) {
//       if (raw == null || raw.isEmpty) return 0;
//       final match = RegExp(r'([\d.]+)').firstMatch(raw);
//       if (match == null) return 0;
//       final value = double.parse(match.group(1)!);

//       // Optionally handle mm/cm/in to px
//       if (raw.contains('mm')) return value * 3.7795275591; // 1mm ≈ 3.78px
//       if (raw.contains('cm')) return value * 37.795275591;
//       if (raw.contains('in')) return value * 96.0;
//       return value;
//     }

//     final width = parseDimension(svgElement.getAttribute('width'));
//     final height = parseDimension(svgElement.getAttribute('height'));
//     return Size(width, height);
// }

  /// Extracts the floor number from the SVG's 'id' attribute.
  int _getFloorNumber() {
    // TODO: Return default floor number when it could not be determined
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

    // A bit more performant
    final pathElement = document.findAllElements('path').firstWhere(
      (element) => element.getAttribute('id') == key,
      orElse: () => 
        throw FloorParserSvgException('Element with id "$key" not found in getPaths.')
     
    );

    final d = pathElement.getAttribute('d') ?? '';
    return parsePathData(d);
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
    // TODO: Allow other type of drawings to be specified as nodes (if required)
    final supportedTypes = {'ellipse', 'circle', 'path'};

    // Recursive function to traverse XML elements.
    void traverseElements(final XmlElement element, final supportedTypes) {
      final localName = element.localName;
      if (supportedTypes.contains(localName)) {
        final String fullKey = (element.getAttribute('id') ?? '').trim();
        // Check if the id matches the point regex.
        // TODO: Consider to use compiled regex for better performance
        if (!FloorSvgParser.pointIdRegex.hasMatch(fullKey)) {
          return;
        }
        late final String x;
        late final String y;

        if (localName == 'circle' || localName == 'ellipse') {
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
        // TODO: use compiled regex to optimize on documents with lot of points
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
      element.children.whereType<XmlElement>()
        .forEach((child) => traverseElements(child, supportedTypes));

    }

    // Start traversal from the root element.
    traverseElements(document.rootElement, supportedTypes);

    if (pointList.isEmpty) {
      throw const FloorParserSvgException(
        'This map has no route anchor points.',
      );
    }
    return pointList;
  }

  static final buildingIdRegex = RegExp(r'^((?!point-)[a-zA-Z]+)-(?:([a-zA-Z]+)-)?(\d+)=([\d]+)$');
  static final pointIdRegex = RegExp(r'^point-(\d+)(?:=([\d-]*))?$');

  /// Receives a building element ID and returns its components.
  static ({String? type, String? subtype, int? id, List<int> linkedIds}) parseBuildingId(String? idAttr) {
    // If the element does not have id, return default empty set
    if ((idAttr ?? '').isEmpty) {
      return (type: null, subtype: null, id: null, linkedIds: []);
    }

    // Try to match building pattern
    final match = FloorSvgParser.buildingIdRegex.firstMatch(idAttr!);
    if (match == null) {
      return (type: null, subtype: null, id: null, linkedIds: []);
    }

    // Extract components using group indices
    final String? buildingType = match.group(1);     // e.g., "stairs", "shop"
    final String? buildingSubtype = match.group(2);  // e.g., "elevator", "male" or null
    final String? uniqueIdStr = match.group(3);      // ID as string
    final String? connectionsStr = match.group(4);   // Connections as string

    // Parse unique ID
    final int? uniqueIdNumber =  int.tryParse(uniqueIdStr ?? '');

    // Parse linked elements (splitting by '-') (As of now regex only matches one linked id 
    //  (we might support more than one entrace in the future) )
    final List<int> linkedElementsIdList = [];
    if ((connectionsStr ?? '').isNotEmpty) {
      // split('-') and map to integers
      for (var linkedId in connectionsStr!.split('-')) {
        final parsed = int.tryParse(linkedId);
        if (parsed != null) {
          linkedElementsIdList.add(parsed);
        }
      }
    }

    return (
      type: buildingType,
      subtype: buildingSubtype,
      id: uniqueIdNumber,
      linkedIds: linkedElementsIdList
    );
  }

  ///
  /// Throws an exception if no such elements are found.
  List<FloorItem> getItems() {
    final List<FloorItem> floorItems = [];
    
    // Find all the path elements that are floorItems (elements whose id matches the building regex)
    final pathElements = document.findAllElements('path');

    pathElements.forEach((final XmlElement svgPath){
        final String fullKey = (svgPath.getAttribute('id') ?? '').trim();

        // not a building / floorItem
        if (fullKey.isEmpty || !buildingIdRegex.hasMatch(fullKey)) {
          return;
        }

        var buildingAttributes = parseBuildingId(fullKey);

        final int itemId = buildingAttributes.id!;
        // For now we onlly support 1 point id
        final int pointId = buildingAttributes.linkedIds[0];

        // TODO: Think a way to refactor the API so that the client can define its own
        //  supported buildings 
        // Check if the main type is supported.
        final String keyMainType = buildingAttributes.type!;
        if (!SupportedClasses.regexpCheckSupported.hasMatch(keyMainType)) {
          return;
        }
        final drawingInstructions = DrawingInstructions(
          clickableArea: getPaths(fullKey),
          sizeParentSvg: svgSize,
          // Will add colorFill and colorStroke configuration in new versions.
          // colorFill: getColorFill(fullKey),
          // colorStroke: getColorStroke(fullKey),
        );
        // Create the appropriate FloorItem based on the main type.
        switch (SupportedClasses.fromString(keyMainType)) {
          case SupportedClasses.shop:
            floorItems.add(
              FloorShop(
                id: itemId,
                floor: floorNumber!,
                idPoint: pointId,
                drawingInstructions: drawingInstructions,
              ),
            );
          case SupportedClasses.parkingSpace:
            floorItems.add(
              FloorParkingSpace(
                id: itemId,
                idPoint: pointId,
                drawingInstructions: drawingInstructions,
                floor: floorNumber!,
              ),
            );
          case SupportedClasses.atmMachine:
            floorItems.add(
              FloorAtmMachine(
                id: itemId,
                idPoint: pointId,
                drawingInstructions: drawingInstructions,
                floor: floorNumber!,
              ),
            );
          case SupportedClasses.toilet:
            floorItems.add(
              FloorHygieneZone(
                id: itemId,
                idPoint: pointId,
                drawingInstructions: drawingInstructions,
                floor: floorNumber!,
                subType: FloorHygieneZoneType.fromString(buildingAttributes.subtype!),
              ),
            );
          case SupportedClasses.stairs:
            floorItems.add(
              FloorStairs(
                id: itemId,
                idPoint: pointId,
                drawingInstructions: drawingInstructions,
                floor: floorNumber!,
                subType: FloorStairsType.fromString(buildingAttributes.subtype!),
              ),
            );
          // Handle unsupported classes.
          // ignore: no_default_cases
          default:
            throw FloorParserSvgException(
              'Unsupported class type: '
              '$keyMainType',
            );
        }





    });

    

    // Recursive function to process XML elements.
    // void processElement(final XmlElement element) {
    //   final String fullKey = (element.getAttribute('id') ?? '').trim();


    //   // Skip elements that do not contain '-', '=', or are not 'path' elements.
    //   if (!fullKey.contains('-') ||
    //       !fullKey.contains('=') ||
    //       element.localName != 'path') {
    //     element.children.whereType<XmlElement>().forEach(processElement);
    //     return;
    //   }

    //   final List<String> mainParts = fullKey.split('=');
    //   final List<String> partsWithoutPoint = mainParts[0].split('-');
    //   final String keyMainType = partsWithoutPoint[0];

    //   // Skip if the main type is 'point'.
    //   if (keyMainType == 'point') {
    //     element.children.whereType<XmlElement>().forEach(processElement);
    //     return;
    //   }
    //   // Recursively process child elements.
    //   element.children.whereType<XmlElement>().forEach(processElement);
    // }


    if (floorItems.isEmpty) {
      throw const FloorParserSvgException(
        'This map has no elements (e.g., stores, '
        'stairs, toilets). Example: "shop-1=3".',
      );
    }

    return floorItems;
  }
}
