import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_loginWorker);
    on<ForrgotPasswordPressed>(_resetPasswordWorker);
    on<RememberMeToggled>(_rememberMeToggled);
    on<LoadWorkerData>(_loadWorkerData);
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
    if (event.email == null && event.password == null) {
      await LocalStore.putRememberMe(false);
      emit(LoginRememberMeToggled(false));
      return;
    }

    if (event.value) {
      if (event.email != null && event.password != null) {
        await LocalStore.rememberEmailAndPassword(
          event.email!,
          event.password!,
        );
      }
    } else {
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
}
