import 'package:flutter/widgets.dart';

/// Parent class for all floor items
abstract class FloorItem {
  /// Unique identifier for floor item
  final String key;

  /// Clickable aray for floor item
  final Positioned aray;

  /// Floor where item is placed
  final int floor;

  /// Method which run when user click on aray
  final VoidCallback? onTap;

  /// Icon for marker
  final Widget? icon;

  const FloorItem({
    required this.key,
    required this.aray,
    required this.floor,
    this.onTap,
    this.icon,
  });
}
