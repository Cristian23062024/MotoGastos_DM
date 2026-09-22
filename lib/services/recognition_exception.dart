/// Error controlado al intentar reconocer una moto en una foto: la UI lo
/// captura y muestra [message] junto con la opción de reintentar.
class RecognitionException implements Exception {
  final String message;
  final Object? cause;

  const RecognitionException(this.message, [this.cause]);

  @override
  String toString() => 'RecognitionException: $message';
}
