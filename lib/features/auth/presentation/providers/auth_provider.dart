import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doc_sense/core/di/injection_container.dart';
import 'package:doc_sense/core/usecase/usecase.dart';
import 'package:doc_sense/features/auth/domain/entities/app_user.dart';
import 'package:doc_sense/features/auth/domain/usecases/get_current_user.dart';
import 'package:doc_sense/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:doc_sense/features/auth/domain/usecases/sign_out.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;

  AuthNotifier(this._signInWithGoogle, this._signOut, this._getCurrentUser)
      : super(const AuthInitial()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    final result = await _signInWithGoogle(const NoParams());
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = AuthAuthenticated(user),
    );
  }

  Future<void> signOut() async {
    final result = await _signOut(const NoParams());
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthUnauthenticated(),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(sl(), sl(), sl());
});
