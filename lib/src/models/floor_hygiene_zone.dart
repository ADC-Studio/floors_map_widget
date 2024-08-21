import 'package:floors_map_widget/floors_map_widget.dart';

/// Means the floor item is hygiene zone
final class FloorHygieneZone extends FloorItem {
  final FloorHygieneZoneType type;

  const FloorHygieneZone({
    required super.key,
    required super.drawingInstructions,
    required super.floor,
    required this.type,
    super.icon,
  });
}
