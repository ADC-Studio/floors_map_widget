import 'package:collection/collection.dart';
import 'dart:math';
import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:floors_map_widget/src/models/floor_point_priority.dart';

final class PathBuilder {
  final int startId;
  final int endId;
  final List<FloorPoint> coords;

  const PathBuilder({
    required this.startId,
    required this.endId,
    required this.coords,
  });

  List<int> findShortestPath() {
    // Intialize the distance list
    final distances = List<double>.filled(coords.length, double.infinity);
    // Nodes we are already used
    final prevNodes = List<int?>.filled(coords.length, null);
    // Queue with priorities
    final priorityQueue = PriorityQueue<FloorPointPriority>();

    if (coords.indexWhere((el) => el.id == startId) == -1 ||
        coords.indexWhere((el) => el.id == endId) == -1) {
      throw ArgumentError('Start or end node does not exist in the graph.');
    }
    // Remap for elements with id
    final start =
        coords.indexOf(coords.where((final el) => el.id == startId).first);
    final end =
        coords.indexOf(coords.where((final el) => el.id == endId).first);

    distances[start] = 0;
    priorityQueue.add(FloorPointPriority(start, 0));

    while (priorityQueue.isNotEmpty) {
      final current = priorityQueue.removeFirst();
      if (current.index == end) {
        break;
      }

      for (int neighbor in coords[current.index].neighbours) {
        final FloorPoint? nPoint =
            coords.firstWhereOrNull((final el) => el.id == neighbor);
        if (nPoint == null) {
          print('null error');
          continue;
        }
        final nId = coords.indexOf(nPoint);
        print('Current node: ${current.index}, checking neighbor: $nId');
        // Search more shorter path
        double alt = distances[current.index] +
            _calculateDistance(coords[current.index], coords[nId]);
        if (alt < distances[nId]) {
          print(
              'Updating: Node $nId from Node ${current.index} with distance $alt');
          distances[nId] = alt;
          // Move to the next point
          prevNodes[nId] = current.index;
          // Change the priority
          priorityQueue.add(FloorPointPriority(nId, alt));
        }
      }
    }

    // Build the path with all previous nodes to the end
    return _buildPath(prevNodes, end);
  }

  List<int> _buildPath(
    final List<int?> prevNodes,
    final int end,
  ) {
    print('PrevNodes: $prevNodes');
    final path = <int>[];
    for (int? at = end; at != null; at = prevNodes[at]) {
      path.insert(0, coords[at].id);
    }
    return path;
  }

  double _calculateDistance(final FloorPoint a, final FloorPoint b) {
    return ((a.x - b.x).abs() + (a.y - b.y).abs());
  }
}

extension on double {
  double sqrt() {
    return this / 2;
  }
}
