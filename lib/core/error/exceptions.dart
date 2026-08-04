class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);
}
