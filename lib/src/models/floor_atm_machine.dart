import 'package:floors_map_widget/src/models/floor_item.dart';

/// Means the floor item is ATM machine
final class FloorAtmMachine extends FloorItem {
  /// Title for ATM Machine (Sber, Tinkoff, etc)
  final String title;

  const FloorAtmMachine({
    required super.key,
    required super.aray,
    required super.floor,
    required this.title,
    super.onTap,
    super.icon,
  });
}
