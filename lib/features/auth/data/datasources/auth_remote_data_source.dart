import 'package:doc_sense/core/error/exceptions.dart';
import 'package:doc_sense/features/auth/data/models/user_model.dart';

/// Talks to the actual auth backend (Firebase Auth / Supabase Auth).
/// Throws [ServerException] on failure; the repository maps that to [Failure].
abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  Future<UserModel> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

/// TODO: replace with a FirebaseAuthDataSource / SupabaseAuthDataSource
/// once the backend is chosen. Kept as an in-memory stub so the rest of
/// the app (routing, DI, UI) is runnable today.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  UserModel? _currentUser;

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      _currentUser = const UserModel(id: 'stub-google', email: 'user@gmail.com');
      return _currentUser!;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    _currentUser = const UserModel(id: 'stub-apple', email: 'user@icloud.com');
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    _currentUser = UserModel(id: 'stub-email', email: email);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;
}
