import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  static Future<UserCredential?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel> checkUser(String uid) async {
    try {
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        LocalStore.putUID(userData?['uid'] ?? uid);
        LocalStore.putlogoutStatus(false);
        return UserModel.fromJson(userData ?? {});
      } else {
        throw Exception("User does not exist");
      }
    } catch (e) {
      throw Exception("Error fetching user");
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Error sending password reset email");
    }
  }

  static Future<bool> registerUser(
    String email,
    String password,
    UserModel userModel,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception("Failed to create user account");
      }

      userModel.uid = userCredential.user?.uid;

      await AppFirestore.usersCollectionRef
          .doc(userModel.uid)
          .set(userModel.toJson());

      LocalStore.putUID(userModel.uid ?? '');
      LocalStore.putlogoutStatus(false);

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }
}
