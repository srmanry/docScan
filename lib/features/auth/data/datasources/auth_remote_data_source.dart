import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:doc_sense/core/error/exceptions.dart';
import 'package:doc_sense/features/auth/data/models/user_model.dart';

/// Talks to the actual auth backend (Firebase Auth / Supabase Auth).
/// Throws [ServerException] on failure; the repository maps that to [Failure].
abstract class AuthRemoteDataSource {
  Future<UserModel> signInAnonymously();
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  Future<UserModel> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  static final Future<void> _googleSignInInit = GoogleSignIn.instance.initialize();

  AuthRemoteDataSourceImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw const ServerException('Anonymous sign-in failed');
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Anonymous sign-in failed');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleSignInInit;
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ServerException('Google sign-in did not return a valid ID token');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final currentUser = _firebaseAuth.currentUser;

      final userCredential = currentUser != null && currentUser.isAnonymous
          ? await currentUser.linkWithCredential(credential)
          : await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw const ServerException('Google sign-in failed');
      }

      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw const ServerException('Google sign-in did not return a valid ID token');
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        final signedIn = await _firebaseAuth.signInWithCredential(credential);
        final user = signedIn.user;
        if (user == null) {
          throw const ServerException('Google sign-in failed');
        }
        return UserModel.fromFirebaseUser(user);
      }
      throw ServerException(e.message ?? 'Google sign-in failed');
    } on GoogleSignInException catch (e) {
      throw ServerException(e.description ?? 'Google sign-in failed');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    throw const ServerException('Apple sign-in is not configured yet');
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    throw const ServerException('Email sign-in is not configured yet');
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignInInit;
      await GoogleSignIn.instance.signOut();
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Sign-out failed');
    } on GoogleSignInException catch (e) {
      throw ServerException(e.description ?? 'Google sign-out failed');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      return user == null ? null : UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Failed to load current user');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
