import 'package:dartz/dartz.dart';
import 'package:doc_sense/core/error/failures.dart';
import 'package:doc_sense/features/auth/domain/entities/app_user.dart';

/// Domain-level contract. Presentation depends on this, not on
/// any concrete data source (Firebase, Supabase, ...).
abstract class AuthRepository {
  Future<Either<Failure, AppUser>> signInWithGoogle();
  Future<Either<Failure, AppUser>> signInWithApple();
  Future<Either<Failure, AppUser>> signInWithEmail(String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, AppUser?>> getCurrentUser();
}
