// Определяем пользовательский класс ошибки
class FloorParserSvgException implements Exception {
  final String message;

  FloorParserSvgException(this.message);

  @override
  String toString() => 'ParserSvgException: $message';
}
