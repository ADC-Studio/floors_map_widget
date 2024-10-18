import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

abstract class FloorSubTypes {}

/// SupportedClasses in floor_map
enum SupportedClasses {
  shop('shop'),
  parkingSpace('parkingspace'),
  atmMachine('atmmachine'),
  toilet('toilet'),
  stairs('stairs');

  final String toNameClass;

  const SupportedClasses(this.toNameClass);

  /// Static method to get the value of toNameClass by instance
  static String getNameClass(final SupportedClasses instance) =>
      instance.toNameClass;

  static IconData getStandartIcon(final SupportedClasses instance) {
    switch (instance) {
      case SupportedClasses.shop:
        return Icons.shopify;
      case SupportedClasses.parkingSpace:
        return Icons.local_parking;
      case SupportedClasses.atmMachine:
        return Icons.local_atm;
      case SupportedClasses.toilet:
        return Icons.wc;
      case SupportedClasses.stairs:
        return Icons.stairs;
    }
  }

  /// Method for converting a string to SupportedClasses
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

enum FloorStairsType implements FloorSubTypes {
  stairs('simple'),
  fireEscape('fire_escape'),
  escalator('escalator'),
  elevator('elevator');

  final String type;

  const FloorStairsType(this.type);

  /// Method for converting a string to SupportedClasses
  static FloorStairsType fromString(final String str) {
    for (final value in FloorStairsType.values) {
      if (value.type.toLowerCase() == str.toLowerCase()) {
        return value;
      }
    }
    throw FloorParserSvgException('Unsupported FloorStairsType: $str');
  }
}

enum FloorHygieneZoneType implements FloorSubTypes {
  maleRoom('male'),
  femaleRoom('female'),
  motherAndChildRoom('mother_and_child');

  final String type;

  const FloorHygieneZoneType(this.type);

  /// Method for converting a string to SupportedClasses
  static FloorHygieneZoneType fromString(final String str) {
    for (final value in FloorHygieneZoneType.values) {
      if (value.type.toLowerCase() == str.toLowerCase()) {
        return value;
      }
    }
    throw FloorParserSvgException('Unsupported FloorHygieneZoneType: $str');
  }
}
