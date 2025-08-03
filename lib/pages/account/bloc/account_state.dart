part of 'account_bloc.dart';

class AccountState extends Equatable {
  final Locale locale;
  const AccountState({this.locale = const Locale('en')});
  AccountState copyWith({Locale? locale}) {
    return AccountState(locale: locale ?? this.locale);
  }

  @override
  List<Object?> get props => [locale];
}

final class AccountInitial extends AccountState {
  const AccountInitial({required super.locale});
}

final class UpdateProfileLoading extends AccountState {
  const UpdateProfileLoading({required super.locale});
}

final class UpdateProfileSuccess extends AccountState {
  final bool isUpdated;
  final UserModel? updatedUser;

  const UpdateProfileSuccess({
    required this.isUpdated,
    required super.locale,
    this.updatedUser,
  });
}

final class UpdateProfileFailure extends AccountState {
  final String error;
  const UpdateProfileFailure({required this.error, required super.locale});
}

final class LoadDistrictsLoading extends AccountState {
  const LoadDistrictsLoading({required super.locale});
}

final class LoadDistrictsSuccess extends AccountState {
  final List<LocationModel> districts;

  const LoadDistrictsSuccess({required this.districts, required super.locale});
}

final class LoadDistrictsFailure extends AccountState {
  final String error;

  const LoadDistrictsFailure({required this.error, required super.locale});
}

final class UpdateWorkerNotificationLanguageSuccess extends AccountState {
  final String languageCode;

  const UpdateWorkerNotificationLanguageSuccess({
    required this.languageCode,
    required super.locale,
  });
}

final class UpdateWorkerNotificationLanguageFailure extends AccountState {
  final String error;

  const UpdateWorkerNotificationLanguageFailure({
    required this.error,
    required super.locale,
  });
}
