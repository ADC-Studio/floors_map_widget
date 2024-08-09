import 'package:floors_map_widget/src/models/floor_item.dart';

/// Means the floor item is hygiene zone
final class FloorHygieneZone extends FloorItem {
  final FloorHygieneZoneType type;

  const FloorHygieneZone({
    required super.key,
    required super.aray,
    required super.floor,
    required this.type,
    super.onTap,
    super.icon,
  });
}

enum FloorHygieneZoneType {
  maleRoom('MALE'),
  femaleRoom('FEMALE'),
  motherAndChildRoom('MOTHER_AND_CHILD');

  final String type;

  const FloorHygieneZoneType(this.type);
}
