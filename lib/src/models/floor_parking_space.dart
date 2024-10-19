import 'package:floors_map_widget/src/models/floor_item.dart';

/// Means the floor item is parking space
final class FloorParkingSpace extends FloorItem {
  /// Title of parking space
  final String? title;

  /// WILL ADD SUPPORT IN NEW VERSION
  /// Return true if parking space has the charging place
  final bool? hasChargingPlace;

  /// WILL ADD SUPPORT IN NEW VERSION
  /// Return true if parking space has the washing place
  final bool? hasWashingPlace;

  const FloorParkingSpace({
    required super.id,
    required super.drawingInstructions,
    required super.floor,
    this.title,
    this.hasChargingPlace,
    this.hasWashingPlace,
    super.icon,
    super.idPoint,
  });
}
