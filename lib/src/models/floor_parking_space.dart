import 'package:floors_map_widget/src/models/floor_item.dart';

/// Means the floor item is parking space
final class FloorParkingSpace extends FloorItem {
  /// Title of parking space
  final String? title;

  /// TODO: ADD SUPPORT
  /// Return true if parking space has the charging place
  final bool? hasChargingPlace;

  /// TODO: ADD SUPPORT
  /// Return true if parking space has the washing place
  final bool? hasWashingPlace;

  const FloorParkingSpace({
    required super.key,
    required super.drawingInstructions,
    required super.floor,
    this.title,
    this.hasChargingPlace,
    this.hasWashingPlace,
    super.icon,
    super.idPoint,
  });
}
