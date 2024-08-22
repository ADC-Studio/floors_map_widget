import 'package:floors_map_widget/src/models/floor_item.dart';

/// Means the floor item is shop
final class FloorShop extends FloorItem {
  /// Title of shop
  final String? title;

  final String? description;

  /// Store the open time
  final DateTime? openTime;

  /// Store the close time
  final DateTime? closeTime;

  const FloorShop({
    required super.key,
    required super.drawingInstructions,
    required super.floor,
    this.title,
    this.description,
    this.openTime,
    this.closeTime,
    super.icon,
    super.idPoint,
  });
}
