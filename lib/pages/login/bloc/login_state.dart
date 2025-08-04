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

final class LoginBypassUsingBiometric extends LoginState {
  final UserModel user;
  LoginBypassUsingBiometric({required this.user});
}

final class LoginLoadWorkerData extends LoginState {
  final UserModel user;
  LoginLoadWorkerData({required this.user});
}

final class LoginLoadWorkerDataFailure extends LoginState {
  final String error;
  LoginLoadWorkerDataFailure({required this.error});
}

final class RegistrationLoading extends LoginState {}

final class RegisterSuccess extends LoginState {
  final bool isSuccess;
  RegisterSuccess({required this.isSuccess});
  @override
  List<Object?> get props => [isSuccess];
}

final class RegisterFailure extends LoginState {
  final String error;
  RegisterFailure({required this.error});
}

final class SignUpLoading extends LoginState {}

final class SignUpSuccess extends LoginState {
  final bool isSuccess;
  SignUpSuccess({required this.isSuccess});
  @override
  List<Object?> get props => [isSuccess];
}

final class SignUpFailure extends LoginState {
  final String error;
  SignUpFailure({required this.error});
}
