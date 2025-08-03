part of 'login_bloc.dart';

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final UserModel user;
  LoginSuccess({required this.user});
}

final class LoginFailure extends LoginState {
  final String error;
  LoginFailure({required this.error});
}

final class LoginResetPasswordLoading extends LoginState {}

final class LoginResetPasswordSuccess extends LoginState {
  final bool isSuccess;
  LoginResetPasswordSuccess({required this.isSuccess});
}

final class LoginResetPasswordFailure extends LoginState {
  final String error;
  LoginResetPasswordFailure({required this.error});
}

final class LoginRememberMeToggled extends LoginState {
  final bool value;
  LoginRememberMeToggled(this.value);
}