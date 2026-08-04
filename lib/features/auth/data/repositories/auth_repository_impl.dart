import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/exceptions.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:doc_sense/features/auth/domain/entities/app_user.dart';
import 'package:doc_sense/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() => _run(remoteDataSource.signInWithGoogle);

  @override
  Future<Either<Failure, AppUser>> signInWithApple() => _run(remoteDataSource.signInWithApple);

  @override
  Future<Either<Failure, AppUser>> signInWithEmail(String email, String password) =>
      _run(() => remoteDataSource.signInWithEmail(email, password));

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  Future<Either<Failure, AppUser>> _run(Future<AppUser> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
