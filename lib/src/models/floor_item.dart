// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/widgets.dart';

/// Parent class for all floor items
abstract class FloorItem {
  /// Unique identifier for floor item
  final String key;

  /// DrawingInstructions for floor item
  final DrawingInstructions drawingInstructions;

  /// Floor where item is placed
  final int floor;

  /// Icon for marker
  final Widget? icon;

  const FloorItem({
    required this.key,
    required this.drawingInstructions,
    required this.floor,
    this.icon,
  });

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FloorItem &&
        other.key == key &&
        other.drawingInstructions == drawingInstructions &&
        other.floor == floor &&
        other.icon == icon;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      drawingInstructions.hashCode ^
      floor.hashCode ^
      icon.hashCode;

  @override
  String toString() => 'FloorItem(key: $key, drawingInstructions: '
      '$drawingInstructions, floor: $floor, icon: $icon)';
}
