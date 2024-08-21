import 'package:floors_map_widget/floors_map_widget.dart';

/// SupportedClasses in floor_map
enum SupportedClasses {
  shop('shop'),
  parkingSpace('parkingspace'),
  atmMachine('atmmachine'),
  toilet('toilet'),
  stairs('stairs');

  final String toNameClass;

  const SupportedClasses(this.toNameClass);

  // Статический метод для получения значения toNameClass по экземпляру
  static String getNameClass(final SupportedClasses instance) =>
      instance.toNameClass;

  // Метод для конвертации строки в SupportedClasses
  static SupportedClasses fromString(final String str) {
    for (final value in SupportedClasses.values) {
      if (value.toNameClass.toLowerCase() == str.toLowerCase()) {
        return value;
      }
    }
    throw FloorParserSvgException('Unsupported class: $str');
  }

  static final regexpCheckSupported = RegExp(
    r'\b(shop|parking\s*space|ATM\s*machine|Toilet|Stairs)\b',
    caseSensitive: false,
  );
}

enum FloorStairsType {
  stairs('simple'),
  fireEscape('fire_escape'),
  esquator('escalator'),
  elevator('elevator');

  final String type;

  const FloorStairsType(this.type);

  // Метод для конвертации строки в SupportedClasses
  static FloorStairsType fromString(final String str) {
    for (final value in FloorStairsType.values) {
      if (value.type.toLowerCase() == str.toLowerCase()) {
        return value;
      }
    }
    throw FloorParserSvgException('Unsupported FloorStairsType: $str');
  }
}

enum FloorHygieneZoneType {
  maleRoom('male'),
  femaleRoom('female'),
  motherAndChildRoom('mother_and_child');

  final String type;

  const FloorHygieneZoneType(this.type);

  // Метод для конвертации строки в SupportedClasses
  static FloorHygieneZoneType fromString(final String str) {
    for (final value in FloorHygieneZoneType.values) {
      if (value.type.toLowerCase() == str.toLowerCase()) {
        return value;
      }
    }
    throw FloorParserSvgException('Unsupported FloorHygieneZoneType: $str');
  }
}
