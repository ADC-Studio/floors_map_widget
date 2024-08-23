import 'package:floors_map_widget/floors_map_widget.dart';

FloorStairs getNearestStair(
  final int startId,
  final Iterable<FloorStairs> stairs,
  final List<FloorPoint> coords,
) {
  final stairsWithoutFireExists =
      stairs.where((final el) => el.type != FloorStairsType.fireEscape);
  double pathToNearestStair = double.infinity;
  int nearestStairId = 0;
  for (final el in stairsWithoutFireExists) {
    final path =
        PathBuilder(startId: startId, endId: el.idPoint!, coords: coords)
            .findShortestPath();
    if ((path['length'] as double) < pathToNearestStair) {
      pathToNearestStair = path['length'];
      nearestStairId = el.idPoint!;
    }
  }
  return stairs.firstWhere((final el) {
    print(el.idPoint);
    print(nearestStairId);
    return el.idPoint == nearestStairId;
  });
}
