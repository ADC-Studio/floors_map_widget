/// A custom exception thrown when parsing SVG fails in the FloorParser.
class FloorParserSvgException implements Exception {
  /// A descriptive message of the error.
  final String message;

  /// An optional error code for categorizing the exception.
  final int? errorCode;

  /// An optional underlying cause of the exception.
  final Exception? cause;

  /// Creates a [FloorParserSvgException] with the given [message].
  ///
  /// Optionally, an [errorCode] and [cause] can be provided to give more
  /// context about the exception.
  const FloorParserSvgException(
    this.message, {
    this.errorCode,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FloorParserSvgException: $message');
    if (errorCode != null) {
      buffer.write(' (Error Code: $errorCode)');
    }
    if (cause != null) {
      buffer.write(' | Cause: $cause');
    }
    return buffer.toString();
  }
}
