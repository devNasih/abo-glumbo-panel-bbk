import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_loginWorker);
    on<ForrgotPasswordPressed>(_resetPasswordWorker);
    on<RememberMeToggled>(_rememberMeToggled);
    on<LoadWorkerData>(_loadWorkerData);
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
    if (event.value) {
      // Save remember me state
      await LocalStore.putRememberMe(true);

      // Save credentials only if both email and password are provided
      if (event.email != null && event.password != null) {
        await LocalStore.rememberEmailAndPassword(
          event.email!,
          event.password!,
        );
      }
    } else {
      // Clear remember me state and credentials
      await LocalStore.putRememberMe(false);
      await LocalStore.clearRememberedCredentials();
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
      await Future.any([
        _performSignUp(event),
        Future.delayed(const Duration(minutes: 5), () {
          throw Exception('Signup process timed out. Please try again.');
        }),
      ]).then((result) {
        if (result == true) {
          emit(SignUpSuccess(isSuccess: true));
        } else {
          emit(SignUpSuccess(isSuccess: false));
        }
      });
    } catch (e) {
      emit(SignUpFailure(error: e.toString()));
    }
  }

  Future<bool> _performSignUp(SignUpButtonPressed event) async {
    String? profileImageUrl;
    String? idImageUrl;

    if (event.profileImage != null) {
      profileImageUrl = await UploadToFireStorage().uploadFile(
        event.profileImage!,
        'agents/profiles',
      );
    }

    if (event.idImage != null) {
      idImageUrl = await UploadToFireStorage().uploadFile(
        event.idImage!,
        'agents/documents',
      );
    }

    event.userModel.profileUrl = profileImageUrl;
    event.userModel.docUrl = idImageUrl;

    return await AuthServices.registerUser(
      event.email,
      event.password,
      event.userModel,
    );
  }
}
