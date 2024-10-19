import 'package:floors_map_widget/floors_map_widget.dart';

/// Means the floor item is hygiene zone
final class FloorHygieneZone extends FloorItem {
  const FloorHygieneZone({
    required super.id,
    required super.drawingInstructions,
    required super.floor,
    required super.subType,
    super.icon,
    super.idPoint,
  });
}
