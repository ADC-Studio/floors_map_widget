import 'package:floors_map_widget/src/models/floor_item.dart';

/// Means the floor item is stairs
final class FloorStairs extends FloorItem {
  /// Type of stairs
  final FloorStairsType type;

  const FloorStairs({
    required super.key,
    required super.aray,
    required super.floor,
    required this.type,
    super.onTap,
    super.icon,
  });
}

enum FloorStairsType {
  stairs('STAIRS'),
  fireEscape('FIRE_ESCAPE'),
  esquator('ESQUATOR'),
  elevator('ELEVATOR');

  final String type;

  const FloorStairsType(this.type);
}
