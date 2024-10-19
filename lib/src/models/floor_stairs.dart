import 'package:floors_map_widget/floors_map_widget.dart';

/// Means the floor item is stairs
final class FloorStairs extends FloorItem {
  const FloorStairs({
    required super.id,
    required super.drawingInstructions,
    required super.floor,
    required super.subType,
    super.icon,
    super.idPoint,
  });
}
