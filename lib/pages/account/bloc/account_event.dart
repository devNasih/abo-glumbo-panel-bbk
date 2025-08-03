part of 'account_bloc.dart';

@immutable
sealed class AccountEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateProfileEvent extends AccountEvent {
  final UserModel user;
  final XFile? selectedIqamaImage;
  final XFile? selectedProfileImage;
  UpdateProfileEvent({
    required this.user,
    this.selectedIqamaImage,
    this.selectedProfileImage,
  });
  @override
  List<Object?> get props => [user, selectedIqamaImage, selectedProfileImage];
}

class LoadDistrictsEvent extends AccountEvent {}

class ChangeLanguageEvent extends AccountEvent {
  final String languageCode;
  ChangeLanguageEvent(this.languageCode);
  @override
  List<Object?> get props => [languageCode];
}

class UpdateWorkerNotificationLanguageEvent extends AccountEvent {
  final String languageCode;
  UpdateWorkerNotificationLanguageEvent(this.languageCode);
  
  @override
  List<Object?> get props => [languageCode];
}
