abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

class AiFailure extends Failure {
  const AiFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
