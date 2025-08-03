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

  // Forget Password
  static Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Error sending password reset email");
    }
  }
}
