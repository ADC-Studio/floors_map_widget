import 'dart:ui';

import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:floors_map_widget/src/core/parser/path_instruction.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xml.dart';

class SvgParser {
  final String svgContent;
  late Size svgSize;
  late int? floorNumber;
  late final xml.XmlDocument document;

  SvgParser({required this.svgContent, this.floorNumber}) {
    document = xml.XmlDocument.parse(svgContent);
    svgSize = _getDimensions();
    floorNumber = floorNumber ?? _getFloorNumber();
  }

  Color? _colorFromHex(final String hexString) {
    if (hexString.trim().toLowerCase() == 'none') {
      return null;
    }

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

    if (colorMap.containsKey(colorName)) {
      final hex = colorMap[colorName]!;
      return _colorFromHex(hex);
    }

    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('FF');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Map<String, String> getCoordinatesFromPath(final String pathData) {
    final regex = RegExp(r'M(\d+\.\d+)\s(\d+)');
    final data = regex.firstMatch(pathData);
    return {
      'x': data!.group(1)!,
      'y': data.group(2)!,
    };
  }

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
            'Unknow command: $command. Allowed: MLHVC',
          );
      }
    }
    return path;
  }

  List<PathInstruction> _parsePathCommands(final String pathData) {
    final regex = RegExp(r'([MLHVCZ])\s*([^A-Za-z]*)');

    final List<PathInstruction> pathDataMap = [];

    // Поиск совпадений
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
                  : match.group(2)!.split(' ').map(double.parse).toList(),
            ),
          );
        } catch (e) {
          throw FloorParserSvgException(e.toString());
        }
      }
    }

    return pathDataMap;
  }

  Size _getDimensions() {
    final svgElement = document.findElements('svg').first;
    final width = double.parse(svgElement.getAttribute('width') ?? '0');
    final height = double.parse(svgElement.getAttribute('height') ?? '0');
    return Size(width, height);
  }

  int _getFloorNumber() {
    final svgElement = document.findElements('svg').first;
    final String fullKey = svgElement.getAttribute('id') ?? '';
    try {
      return int.parse(fullKey.substring(fullKey.indexOf('-') + 1).trim());
    } catch (e) {
      throw FloorParserSvgException('Id Svg Image not contains floor number. '
          'Get: ${fullKey.substring(fullKey.indexOf('-') + 1).trim()}');
    }
  }

  Path getPaths(final String key) {
    final pathElements = document.findAllElements('path');

    for (final pathElement in pathElements) {
      if (pathElement.getAttribute('id') != key) {
        continue;
      }

      final d = pathElement.getAttribute('d') ?? '';
      return parsePathData(d);
    }
    throw FloorParserSvgException('Element $key not found in getPaths time');
  }

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

  List<FloorPoint> getPoints() {
    final List<FloorPoint> pointList = [];

    // Рекурсивная функция для обхода элементов
    void traverseElements(final XmlElement element) {
      if (element.name.local == 'circle' || element.name.local == 'path') {
        final String fullKey = (element.getAttribute('id') ?? '').trim();
        if (!fullKey.contains('-') ||
            !fullKey.contains('=') ||
            !fullKey.contains('point')) {
          return;
        }

        late final String x;
        late final String y;

        if (element.name.local == 'circle') {
          x = (element.getAttribute('cx') ?? '').trim();
          y = (element.getAttribute('cy') ?? '').trim();
        } else {
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

      // Рекурсивный вызов для всех дочерних элементов
      element.children.whereType<XmlElement>().forEach(traverseElements);
    }

    // Начинаем обход с корневого элемента документа
    traverseElements(document.rootElement);

    if (pointList.isEmpty) {
      throw FloorParserSvgException('This map has no route anchor points');
    }
    return pointList;
  }

  List<FloorItem> getItems() {
    final List<FloorItem> floorItems = [];

    // Рекурсивный метод для обработки всех элементов
    void processElement(final XmlElement element) {
      // Проверяем текущий элемент
      final String fullKey = (element.getAttribute('id') ?? '').trim();

      if (!fullKey.contains('-') ||
          !fullKey.contains('=') ||
          element.name.local != 'path') {
        element.children.whereType<XmlElement>().forEach(processElement);
        return;
      }

      final List<String> mainParts = fullKey.split('=');
      final List<String> partsWithoutPoint = mainParts[0].split('-');
      final String keyMainType = partsWithoutPoint[0];

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
          'ID object there must be int. Example: shop-1=1'
          ' or toilet-male-1=30. Get: $fullKey',
        );
      }

      if (!SupportedClasses.regexpCheckSupported.hasMatch(keyMainType)) {
        return;
      }

      switch (SupportedClasses.fromString(keyMainType)) {
        case SupportedClasses.shop:
          floorItems.add(
            FloorShop(
              key: keyId,
              floor: floorNumber!,
              idPoint: pointId,
              drawingInstructions: DrawingInstructions(
                clickableArea: getPaths(fullKey),
                sizeParentSvg: svgSize,
                //TODO: ADD IN CONFIG
                // colorFill: getColorFill(fullKey),
                // colorStroke: getColorStroke(fullKey),
              ),
            ),
          );
        case SupportedClasses.parkingSpace:
          floorItems.add(
            FloorParkingSpace(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: DrawingInstructions(
                clickableArea: getPaths(fullKey),
                sizeParentSvg: svgSize,
                //TODO: ADD IN CONFIG
                // colorFill: getColorFill(fullKey),
                // colorStroke: getColorStroke(fullKey),
              ),
              floor: floorNumber!,
            ),
          );
        case SupportedClasses.atmMachine:
          floorItems.add(
            FloorAtmMachine(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: DrawingInstructions(
                clickableArea: getPaths(fullKey),
                sizeParentSvg: svgSize,
                //TODO: ADD IN CONFIG
                // colorFill: getColorFill(fullKey),
                // colorStroke: getColorStroke(fullKey),
              ),
              floor: floorNumber!,
            ),
          );
        case SupportedClasses.toilet:
          floorItems.add(
            FloorHygieneZone(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: DrawingInstructions(
                clickableArea: getPaths(fullKey),
                sizeParentSvg: svgSize,
                //TODO: ADD IN CONFIG
                // colorFill: getColorFill(fullKey),
                // colorStroke: getColorStroke(fullKey),
              ),
              floor: floorNumber!,
              subType: FloorHygieneZoneType.fromString(partsWithoutPoint[1]),
            ),
          );
        case SupportedClasses.stairs:
          floorItems.add(
            FloorStairs(
              key: keyId,
              idPoint: pointId,
              drawingInstructions: DrawingInstructions(
                clickableArea: getPaths(fullKey),
                sizeParentSvg: svgSize,
                //TODO: ADD IN CONFIG
                // colorFill: getColorFill(fullKey),
                // colorStroke: getColorStroke(fullKey),
              ),
              floor: floorNumber!,
              subType: FloorStairsType.fromString(partsWithoutPoint[1]),
            ),
          );
        // ignore: no_default_cases
        default:
          throw FloorParserSvgException(
            'Not found: ${SupportedClasses.fromString(keyMainType)}',
          );
      }

      // Рекурсивно обрабатываем все дочерние элементы
      element.children.whereType<XmlElement>().forEach(processElement);
    }

    // // Начинаем обработку с корневых элементов
    // document.rootElement.children
    //     .whereType<XmlElement>()
    //     .toList()
    //     .forEach(processElement);

    // Начинаем обработку с корневых элементов

    processElement(document.rootElement);

    if (floorItems.isEmpty) {
      throw FloorParserSvgException('This map has no any elements '
          '(stores, stairs, toilet) Example store-1=3');
    }

    return floorItems;
  }
}
