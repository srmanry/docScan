import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';

/// Every domain use case implements this contract.
/// [Type] is the success return type, [Params] is the input.
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Use for use cases that take no parameters.
class NoParams {
  const NoParams();
}
