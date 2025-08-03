import 'dart:ui';

import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc() : super(AccountInitial(locale: getSavedLocale())) {
    on<UpdateProfileEvent>(_updateProfile);
    on<LoadDistrictsEvent>(_loadDistricts);
    on<ChangeLanguageEvent>(_onChangeLocale);
    on<UpdateWorkerNotificationLanguageEvent>(
      _updateWorkerNotificationLanguage,
    );
  }
  static Locale getSavedLocale() {
    String languageCode = LocalStore.getUserlanguage();
    return Locale(languageCode);
  }

  void _onChangeLocale(
    ChangeLanguageEvent event,
    Emitter<AccountState> emit,
  ) async {
    await LocalStore.putUserlanguage(event.languageCode);
    emit(state.copyWith(locale: Locale(event.languageCode)));
  }

  Future<void> _updateProfile(
    UpdateProfileEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(UpdateProfileLoading(locale: state.locale));
    try {
      String? iqamaImageUrl;
      if (event.selectedIqamaImage != null) {
        try {
          iqamaImageUrl = await UploadToFireStorage().uploadFile(
            event.selectedIqamaImage!,
            'agents/documents',
          );
        } catch (uploadError) {
          if (uploadError.toString().contains('corrupted') ||
              uploadError.toString().contains('unsupported format')) {
            try {
              final pngFile = await UploadToFireStorage().compressToPng(
                event.selectedIqamaImage!,
              );
              if (pngFile != null &&
                  pngFile.path != event.selectedIqamaImage!.path) {
                iqamaImageUrl = await UploadToFireStorage().uploadFile(
                  pngFile,
                  'agents/documents',
                );
              } else {
                rethrow;
              }
            } catch (_) {
              emit(
                UpdateProfileFailure(
                  error: uploadError.toString(),
                  locale: state.locale,
                ),
              );
              return;
            }
          } else {
            emit(
              UpdateProfileFailure(
                error: uploadError.toString(),
                locale: state.locale,
              ),
            );
            return;
          }
        }
      }
      String? profileUrl;
      if (event.selectedProfileImage != null) {
        try {
          profileUrl = await UploadToFireStorage().uploadFile(
            event.selectedProfileImage!,
            'agents/profiles',
          );
        } catch (uploadError) {
          if (uploadError.toString().contains('corrupted') ||
              uploadError.toString().contains('unsupported format')) {
            try {
              final pngFile = await UploadToFireStorage().compressToPng(
                event.selectedProfileImage!,
              );
              if (pngFile != null &&
                  pngFile.path != event.selectedProfileImage!.path) {
                profileUrl = await UploadToFireStorage().uploadFile(
                  pngFile,
                  'agents/profiles',
                );
              } else {
                rethrow;
              }
            } catch (_) {
              emit(
                UpdateProfileFailure(
                  error: uploadError.toString(),
                  locale: state.locale,
                ),
              );
              return;
            }
          } else {
            emit(
              UpdateProfileFailure(
                error: uploadError.toString(),
                locale: state.locale,
              ),
            );
            return;
          }
        }
      }
      if (profileUrl != null) {
        event.user.profileUrl = profileUrl;
      }
      if (iqamaImageUrl != null) {
        event.user.docUrl = iqamaImageUrl;
      }
      await AppServices.updateUserProfile(event.user);
      emit(
        UpdateProfileSuccess(
          isUpdated: true,
          locale: state.locale,
          updatedUser: event.user,
        ),
      );
    } on Exception catch (e) {
      emit(UpdateProfileFailure(error: e.toString(), locale: state.locale));
    } catch (e) {
      emit(UpdateProfileFailure(error: e.toString(), locale: state.locale));
    }
  }

  Future<void> _loadDistricts(
    LoadDistrictsEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(LoadDistrictsLoading(locale: state.locale));
    try {
      List<LocationModel> districts = await AppServices.getDistricts();
      emit(LoadDistrictsSuccess(districts: districts, locale: state.locale));
    } catch (e) {
      emit(LoadDistrictsFailure(error: e.toString(), locale: state.locale));
    }
  }

  Future<void> _updateWorkerNotificationLanguage(
    UpdateWorkerNotificationLanguageEvent event,
    Emitter<AccountState> emit,
  ) async {
    try {
      await AppServices.updateWorkerLanguage(event.languageCode);
      emit(
        UpdateWorkerNotificationLanguageSuccess(
          languageCode: event.languageCode,
          locale: state.locale,
        ),
      );
    } catch (e) {
      emit(
        UpdateWorkerNotificationLanguageFailure(
          error: e.toString(),
          locale: state.locale,
        ),
      );
    }
  }
}
