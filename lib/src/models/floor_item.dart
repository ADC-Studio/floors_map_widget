// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/widgets.dart';

/// Parent class for all floor items
abstract class FloorItem {
  /// Unique identifier for floor item
  final int id;

  /// DrawingInstructions for floor item
  final DrawingInstructions drawingInstructions;

  /// Floor where item is placed
  final int floor;

  /// Icon for marker
  final Widget? icon;

  /// Id negbour point
  final int? idPoint;

  final FloorSubTypes? subType;

  const FloorItem({
    required this.id,
    required this.drawingInstructions,
    required this.floor,
    this.icon,
    this.idPoint,
    this.subType,
  });

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FloorItem && other.hashCode == hashCode;
  }

  @override
  int get hashCode => Object.hashAll(
        [
          id.hashCode,
          drawingInstructions.hashCode,
          floor.hashCode,
          icon.hashCode,
          subType.hashCode,
        ],
      );

  @override
  String toString() => 'FloorItem(key: $id, drawingInstructions: '
      '$drawingInstructions, floor: $floor, icon: $icon, '
      'subType: $subType)';
}
