import 'package:firebase_auth/firebase_auth.dart';
import 'package:doc_sense/features/auth/domain/entities/app_user.dart';

/// Data-layer representation of a user, aware of JSON / Firestore shape.
/// The domain layer never sees this class, only [AppUser].
class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.isPremium,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        isPremium: json['isPremium'] as bool? ?? false,
      );

  factory UserModel.fromFirebaseUser(User user) => UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isPremium: false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isPremium': isPremium,
      };
}
