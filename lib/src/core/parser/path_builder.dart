import 'package:collection/collection.dart';
import 'package:floors_map_widget/src/models/floor_point.dart';
import 'package:floors_map_widget/src/models/floor_point_priority.dart';

// ignore: avoid_classes_with_only_static_members
abstract class PathBuilder {
  const PathBuilder();

  static List<int> findShortestPath(
    final int startId,
    final int endId,
    final List<FloorPoint> points,
  ) {
    // Создание маппинга идентификаторов точек на их индексы
    final idToIndex = Map<int, int>.fromIterable(
      points,
      key: (p) => p.id,
      value: (p) => points.indexOf(p),
    );

    // Проверка существования идентификаторов
    if (!idToIndex.containsKey(startId) || !idToIndex.containsKey(endId)) {
      throw ArgumentError('Start or End ID does not exist in the points list.');
    }

    // Получение индексов начальной и конечной точек
    final startIndex = idToIndex[startId]!;
    final endIndex = idToIndex[endId]!;

    final distances = List<double>.filled(points.length, double.infinity);
    final prevNodes = List<int?>.filled(points.length, null);
    final priorityQueue = PriorityQueue<FloorPointPriority>();

    distances[startIndex] = 0; // Weight
    priorityQueue.add(FloorPointPriority(startIndex, 0));

    while (priorityQueue.isNotEmpty) {
      final current = priorityQueue.removeFirst();
      print('Processing node: ${points[current.index].id}');

      if (current.index == endIndex) {
        break;
      }

      for (int neighbourId in points[current.index].neighbours) {
        final neighbourIndex = idToIndex[neighbourId]!;
        double altPoint = distances[current.index] +
            _calculateDistance(points[current.index], points[neighbourIndex]);

        print('Checking neighbour: ${points[neighbourIndex].id}');
        print(
            'Alt point: $altPoint, Current distance: ${distances[neighbourIndex]}');

        if (altPoint < distances[neighbourIndex]) {
          distances[neighbourIndex] = altPoint;
          prevNodes[neighbourIndex] = current.index;
          priorityQueue.add(
            FloorPointPriority(neighbourIndex, altPoint),
          );
        }
      }
    }

    // Проверка достижимости конечной точки
    // if (distances[endIndex] == double.infinity) {
    //   // Если конечная точка недостижима
    //   print('End node is unreachable');
    //   return [];
    // }

    print('Path found');
    return _buildPath(prevNodes, endIndex, idToIndex);
  }

  static List<int> _buildPath(
    final List<int?> prevNodes,
    final int end,
    final Map<int, int> idToIndex,
  ) {
    final path = <int>[];
    for (int? at = end; at != null; at = prevNodes[at]) {
      final id = idToIndex.entries.firstWhere((e) => e.value == at).key;
      path.insert(0, id);
    }
    return path;
  }

  static double _calculateDistance(final FloorPoint a, final FloorPoint b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();
}
