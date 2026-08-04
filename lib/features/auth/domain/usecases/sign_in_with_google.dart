import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/auth/domain/entities/app_user.dart';
import 'package:doc_sense/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<AppUser, NoParams> {
  final AuthRepository repository;

  const SignInWithGoogle(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}
