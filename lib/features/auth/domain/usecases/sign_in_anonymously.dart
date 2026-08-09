import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/auth/domain/entities/app_user.dart';
import 'package:doc_sense/features/auth/domain/repositories/auth_repository.dart';

class SignInAnonymously implements UseCase<AppUser, NoParams> {
  final AuthRepository repository;

  const SignInAnonymously(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) {
    return repository.signInAnonymously();
  }
}
