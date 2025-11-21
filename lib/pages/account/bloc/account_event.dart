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
  final List<PlatformFile>? newCertifications;

  UpdateProfileEvent({
    required this.user,
    this.selectedIqamaImage,
    this.selectedProfileImage,
    this.newCertifications,
  });
  @override
  List<Object?> get props => [
    user,
    selectedIqamaImage,
    selectedProfileImage,
    newCertifications,
  ];
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

class RequestPayoutEvent extends AccountEvent {
  final String user;
  final String amount;
  RequestPayoutEvent(this.user, this.amount);
  @override
  List<Object?> get props => [user, amount];
}
