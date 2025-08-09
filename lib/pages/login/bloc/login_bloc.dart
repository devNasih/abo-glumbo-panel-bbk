import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_loginWorker);
    on<ForrgotPasswordPressed>(_resetPasswordWorker);
    on<RememberMeToggled>(_rememberMeToggled);
    on<LoadWorkerData>(_loadWorkerData);
    on<RefreshUserData>(_refreshUserData);
    on<RegisterButtonPressed>(_registerWorker);
    on<SignUpButtonPressed>(_signUpWorker);
  }

  Future<void> _loginWorker(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      UserCredential? res = await AuthServices.loginWithEmailAndPassword(
        event.email,
        event.password,
      );
      if (res?.user != null) {
        UserModel user = await AuthServices.checkUser(res!.user!.uid);
        emit(LoginSuccess(user: user));
      } else {
        emit(
          LoginFailure(error: "Login failed, please check your credentials"),
        );
      }
    } on FirebaseAuthException catch (e) {
      emit(LoginFailure(error: e.message ?? "Firebase Auth error"));
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }

  Future<void> _resetPasswordWorker(
    ForrgotPasswordPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginResetPasswordLoading());
    try {
      bool isAvailable = await AppServices.checkTheMailExists(event.email);
      if (isAvailable) {
        await AuthServices.resetPassword(event.email);
        emit(LoginResetPasswordSuccess(isSuccess: true));
      } else {
        emit(LoginResetPasswordSuccess(isSuccess: false));
      }
    } catch (e) {
      emit(LoginResetPasswordFailure(error: e.toString()));
    }
  }

  Future<void> _rememberMeToggled(
    RememberMeToggled event,
    Emitter<LoginState> emit,
  ) async {
    if (kDebugMode) {
      print(
        'RememberMeToggled - value: ${event.value}, email: ${event.email}, password: ${event.password != null ? 'provided' : 'null'}',
      );
    }

    if (event.value) {
      // Always save remember me state when toggled on
      await LocalStore.putRememberMe(true);
      if (kDebugMode) {
        print('Remember me enabled and saved to local storage');
      }

      // Save credentials if both email and password are provided
      if (event.email != null &&
          event.password != null &&
          event.email!.isNotEmpty &&
          event.password!.isNotEmpty) {
        await LocalStore.rememberEmailAndPassword(
          event.email!,
          event.password!,
        );
        if (kDebugMode) {
          print('Saved credentials to local storage');
        }
      } else {
        if (kDebugMode) {
          print(
            'Email or password is empty, remember me enabled but credentials not saved yet',
          );
        }
      }
    } else {
      // Clear remember me state and credentials when toggled off
      await LocalStore.putRememberMe(false);
      await LocalStore.clearRememberedCredentials();
      if (kDebugMode) {
        print('Cleared remember me and credentials');
      }
    }
    emit(LoginRememberMeToggled(event.value));
  }

  Future<void> _loadWorkerData(
    LoadWorkerData event,
    Emitter<LoginState> emit,
  ) async {
    try {
      UserModel user = await AuthServices.checkUser(
        event.uid ?? LocalStore.getUID()!,
      );
      if (user.uid == null || user.uid!.isEmpty) {
        emit(LoginLoadWorkerDataFailure(error: "User not found"));
      } else {
        emit(LoginLoadWorkerData(user: user));
      }
    } catch (e) {
      emit(LoginLoadWorkerDataFailure(error: e.toString()));
    }
  }

  Future<void> _refreshUserData(
    RefreshUserData event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // First try to get cached user data
      UserModel? cachedUser = LocalStore.getCachedUserData();
      if (cachedUser != null) {
        emit(LoginLoadWorkerData(user: cachedUser));
        return;
      }

      // If no cached data, fetch from Firebase
      UserModel user = await AuthServices.checkUser(
        event.uid ?? LocalStore.getUID()!,
      );
      if (user.uid == null || user.uid!.isEmpty) {
        emit(LoginLoadWorkerDataFailure(error: "User not found"));
      } else {
        emit(LoginLoadWorkerData(user: user));
      }
    } catch (e) {
      emit(LoginLoadWorkerDataFailure(error: e.toString()));
    }
  }

  Future<void> _registerWorker(
    RegisterButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      bool isEmailExists = await AppServices.isEmailRegistered(event.email);
      if (!isEmailExists) {
        emit(RegisterSuccess(isSuccess: true));
      } else {
        emit(RegisterSuccess(isSuccess: false));
      }
    } catch (e) {
      emit(RegisterFailure(error: e.toString()));
    }
  }

  Future<void> _signUpWorker(
    SignUpButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(SignUpLoading());
    try {
      // Add timeout to the entire signup process
      bool result = await Future.any([
        _performSignUp(event),
        Future.delayed(const Duration(minutes: 5), () {
          throw Exception('Signup process timed out. Please try again.');
        }),
      ]);

      if (result == true) {
        emit(SignUpSuccess(isSuccess: true));
      } else {
        emit(
          SignUpFailure(error: 'Account creation failed. Please try again.'),
        );
      }
    } catch (e) {
      // Filter out technical errors that shouldn't be shown to users
      String errorMessage = e.toString();
      if (errorMessage.contains('unauthorized') ||
          errorMessage.contains('permission denied')) {
        // These are technical issues that should be handled internally
        emit(SignUpFailure(error: 'Please try creating your account again.'));
      } else {
        emit(SignUpFailure(error: errorMessage));
      }
    }
  }

  Future<bool> _performSignUp(SignUpButtonPressed event) async {
    String? profileImageUrl;
    String? idImageUrl;

    try {
      // Create the user account first to authenticate with Firebase
      bool userCreated = await AuthServices.registerUser(
        event.email,
        event.password,
        event.userModel,
      );

      if (!userCreated) {
        return false;
      }

      // Wait a moment to ensure Firebase Auth state is fully synced
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify the user is actually authenticated before proceeding
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('Error: User account created but not authenticated');
        }
        return false;
      }

      // Now that the user is authenticated, upload the files
      if (event.profileImage != null) {
        try {
          profileImageUrl = await _uploadFileWithRetry(
            event.profileImage!,
            'agents/profiles',
          );
          if (kDebugMode) {
            print('Profile image uploaded successfully');
          }
        } catch (profileUploadError) {
          if (kDebugMode) {
            print('Profile image upload failed: $profileUploadError');
          }
          // Continue with signup even if profile image upload fails
        }
      }

      if (event.idImage != null) {
        try {
          idImageUrl = await _uploadFileWithRetry(
            event.idImage!,
            'agents/documents',
          );
          if (kDebugMode) {
            print('ID document uploaded successfully');
          }
        } catch (idUploadError) {
          if (kDebugMode) {
            print('ID document upload failed: $idUploadError');
          }
          // Continue with signup even if ID document upload fails
        }
      }

      // Update the user document with the image URLs if they were uploaded
      if (profileImageUrl != null || idImageUrl != null) {
        try {
          Map<String, dynamic> updateData = {};
          if (profileImageUrl != null) {
            updateData['profileUrl'] = profileImageUrl;
          }
          if (idImageUrl != null) {
            updateData['docUrl'] = idImageUrl;
          }
          updateData['updatedAt'] = Timestamp.now();

          await AppFirestore.usersCollectionRef
              .doc(event.userModel.uid)
              .update(updateData);

          if (kDebugMode) {
            print('User document updated with image URLs');
          }
        } catch (updateError) {
          if (kDebugMode) {
            print(
              'Failed to update user document with image URLs: $updateError',
            );
          }
          // Continue with signup even if document update fails
        }
      }

      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Signup error: $error');
      }

      // If this is an authentication-related error, don't retry
      if (error.toString().contains('email-already-in-use') ||
          error.toString().contains('weak-password') ||
          error.toString().contains('invalid-email')) {
        rethrow; // Let the calling method handle these specific errors
      }

      return false;
    }
  }

  Future<String?> _uploadFileWithRetry(
    XFile file,
    String storagePath, {
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await UploadToFireStorage().uploadFile(file, storagePath);
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow; // If final attempt fails, throw the error
        }
        // Wait before retrying
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        if (kDebugMode) {
          print('Upload attempt ${attempt + 1} failed, retrying...');
        }
      }
    }
    return null;
  }
}
