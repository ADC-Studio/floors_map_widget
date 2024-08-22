import 'package:floors_map_widget/floors_map_widget.dart';

/// Means the floor item is stairs
final class FloorStairs extends FloorItem {
  /// Type of stairs
  final FloorStairsType type;

  const FloorStairs({
    required super.key,
    required super.drawingInstructions,
    required super.floor,
    required this.type,
    super.icon,
    super.idPoint,
  });
}
