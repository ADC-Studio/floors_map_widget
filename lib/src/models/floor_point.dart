/// Means the floor point
final class FloorPoint {
  final int id;
  final double x;
  final double y;
  final List<int> neighbours;
  final int floor;

  const FloorPoint({
    required this.id,
    required this.x,
    required this.y,
    required this.neighbours,
    required this.floor,
  });
}
