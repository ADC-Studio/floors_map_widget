class FloorPointPriority implements Comparable<FloorPointPriority> {
  final int index;
  final double priority;

  FloorPointPriority(
    this.index,
    this.priority,
  );

  @override
  int compareTo(final FloorPointPriority other) =>
      priority.compareTo(other.priority);
}
