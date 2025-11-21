import 'dart:ui';
import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
    on<RequestPayoutEvent>(_onPayoutRequest);
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
      bool docUrlUpdated = false;

      if (event.selectedIqamaImage != null) {
        try {
          iqamaImageUrl = await UploadToFireStorage().uploadFile(
            event.selectedIqamaImage!,
            'agents/documents',
          );
          docUrlUpdated = true;
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
                docUrlUpdated = true;
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
      bool profileUrlUpdated = false;

      if (event.selectedProfileImage != null) {
        try {
          profileUrl = await UploadToFireStorage().uploadFile(
            event.selectedProfileImage!,
            'agents/profiles',
          );
          profileUrlUpdated = true;
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
                profileUrlUpdated = true;
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

      // Handle Certifications Upload
      bool certificationsUpdated = false;
      if (event.newCertifications != null &&
          event.newCertifications!.isNotEmpty) {
        List<String> currentCertifications = event.user.certifications ?? [];

        for (var cert in event.newCertifications!) {
          if (cert.path != null) {
            try {
              final fileRef = AppFireStorage.agentDocStorageRef.child(
                'agents/certifications/${DateTime.now().millisecondsSinceEpoch}_${cert.name}',
              );
              final uploadTask = fileRef.putFile(File(cert.path!));
              final snapshot = await uploadTask;
              final downloadUrl = await snapshot.ref.getDownloadURL();
              currentCertifications.add(downloadUrl);
              certificationsUpdated = true;
            } catch (e) {
              print('Failed to upload certification: ${cert.name}, error: $e');
            }
          }
        }
        event.user.certifications = currentCertifications;
      } else {
        certificationsUpdated = true;
      }

      await AppServices.updateUserProfile(
        event.user,
        updateProfileUrl: profileUrlUpdated,
        updateDocUrl: docUrlUpdated,
        updateCertifications: certificationsUpdated,
      );

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

  Future _onPayoutRequest(
    RequestPayoutEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(RequestPayoutLoading(locale: state.locale));

    try {
      await AppServices.requestPayout(event.amount, event.user);
      emit(RequestPayoutSuccess(locale: state.locale));
    } catch (e) {
      emit(RequestPayoutFailure(error: e.toString(), locale: state.locale));
    }
  }
}
