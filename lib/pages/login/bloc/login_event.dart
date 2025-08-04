part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class LoginButtonPressed extends LoginEvent {
  final String email;
  final String password;
  LoginButtonPressed({required this.email, required this.password});
  @override
  String toString() =>
      'LoginButtonPressed { email: $email, password: $password }';
}

class ForrgotPasswordPressed extends LoginEvent {
  final String email;
  ForrgotPasswordPressed({required this.email});
  @override
  String toString() => 'ForrgotPasswordPressed { email: $email }';
}

class RememberMeToggled extends LoginEvent {
  final bool value;
  final String? email;
  final String? password;
  RememberMeToggled(this.value, {this.email, this.password});
  @override
  String toString() =>
      'RememberMeToggled { value: $value, email: $email, password: $password }';
}

class BypassUsingBiometric extends LoginEvent {}

class LoadWorkerData extends LoginEvent {
  final String? uid;
  LoadWorkerData({this.uid});
  List<Object?> get props => [uid];
}

class RegisterButtonPressed extends LoginEvent {
  final String email;
  final String password;
  final String confirmPassword;
  RegisterButtonPressed({
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
  @override
  List<Object?> get props => [email, password, confirmPassword];
}

class SignUpButtonPressed extends LoginEvent {
  final String email;
  final String password;
  final XFile? profileImage;
  final XFile? idImage;
  UserModel userModel;
  SignUpButtonPressed({
    required this.email,
    required this.password,
    this.profileImage,
    this.idImage,
    required this.userModel,
  });
  @override
  List<Object?> get props => [
    email,
    password,
    profileImage,
    idImage,
    userModel,
  ];
}
