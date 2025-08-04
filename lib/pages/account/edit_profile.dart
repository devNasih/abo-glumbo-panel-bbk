import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/sheets/locations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  final UserModel? workerData;
  const EditProfile({super.key, this.workerData});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  String? profileImageUrl = null;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController districtNameController = TextEditingController();
  final TextEditingController jobRolesController = TextEditingController();
  final List<LocationModel> districts = [];
  XFile? selectedImage;
  XFile? selectedProfileImage;

  void fillContent() {
    if (widget.workerData != null) {
      profileImageUrl = widget.workerData!.profileUrl;
      nameController.text = widget.workerData!.name ?? '';
      emailController.text = widget.workerData!.email ?? '';
      phoneController.text = widget.workerData!.phone ?? '';
      districtNameController.text = widget.workerData!.districtName ?? '';
      jobRolesController.text = widget.workerData!.jobRoles?.join(', ') ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    fillContent();
    _loadDistricts();
  }

  void _loadDistricts() {
    context.read<AccountBloc>().add(LoadDistrictsEvent());
  }

  Future<void> pickImage(bool isProfile) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: isProfile ? 800 : 1200,
        maxHeight: isProfile ? 800 : 1200,
      );

      if (image != null) {
        final file = File(image.path);

        // Check if file exists
        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Selected file could not be found. Please try again.',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Image is too large. Please select an image smaller than 5MB.',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        debugPrint('Selected image size: $fileSize bytes');

        if (isProfile) {
          setState(() => selectedProfileImage = image);
          await cropImage(true);
        } else {
          setState(() => selectedImage = image);
          await cropImage(false);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> cropImage(bool isProfile) async {
    try {
      final sourcePath = isProfile
          ? selectedProfileImage!.path
          : selectedImage!.path;

      CroppedFile? res = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: isProfile
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: isProfile,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            aspectRatioLockEnabled: isProfile,
          ),
        ],
      );

      if (res != null) {
        if (isProfile) {
          setState(() => selectedProfileImage = XFile(res.path));
        } else {
          setState(() => selectedImage = XFile(res.path));
        }
      } else {
        final bool? shouldKeepImage = await showCropConfirmDialog(context);

        if (shouldKeepImage != true) {
          if (isProfile) {
            setState(() => selectedProfileImage = null);
          } else {
            setState(() => selectedImage = null);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping image: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final locale = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(locale?.profileManagement ?? 'Profile Management'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is UpdateProfileSuccess) {
            if (state.isUpdated) {
              final updatedUser =
                  state.updatedUser ??
                  UserModel(
                    uid: widget.workerData?.uid ?? '',
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    districtName: districtNameController.text,
                    jobRoles: jobRolesController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    profileUrl: profileImageUrl,
                    lanCode: widget.workerData?.lanCode,
                    country: widget.workerData?.country,
                    createdAt: widget.workerData?.createdAt,
                    updatedAt: widget.workerData?.updatedAt,
                    isAdmin: widget.workerData?.isAdmin,
                    isVerified: widget.workerData?.isVerified,
                    docUrl: widget.workerData?.docUrl,
                    fcmToken: widget.workerData?.fcmToken,
                    location: widget.workerData?.location,
                    liveLocation: widget.workerData?.liveLocation,
                  );

              Navigator.pop(context, updatedUser);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    locale?.profileUpdatedSuccessfully ??
                        'Profile updated successfully',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    locale?.failedToUpdateProfile ?? 'Profile update failed',
                  ),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is LoadDistrictsSuccess) {
            districts.clear();
            districts.addAll(state.districts);
          } else if (state is LoadDistrictsFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
          return SavingStackWidget(
            isSaving: state is UpdateProfileLoading,
            isLoading: state is UpdateProfileLoading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: safePadding.bottom + 16,
                ),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.grey2.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: selectedProfileImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(selectedProfileImage!.path),
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  ),
                                )
                              : profileImageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profileImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => pickImage(true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormWidget(
                    controller: nameController,
                    label: locale?.yourName ?? 'Your Name',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale?.nameIsRequired ?? 'Name is required';
                      } else if (value.length < 3) {
                        return locale?.enterAValidName ?? 'Enter a valid name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    controller: emailController,
                    label: locale?.emailAddress ?? 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale?.emailIsRequired ?? 'Email is required';
                      } else if (!value.contains("@")) {
                        return locale?.enterAValidEmail ??
                            'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    isPhoneNumber: true,
                    label: locale?.phoneNumber ?? 'Phone Number',
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    controller: districtNameController,
                    label: locale?.districtName ?? 'District Name',
                    onTap: () =>
                        showLocationPicker(context, (selectedDistrict) {
                          districtNameController.text = selectedDistrict;
                        }, districts),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale?.districtNameIsRequired ??
                            'District name is required';
                      }
                      return null;
                    },
                    suffix: const Icon(Icons.keyboard_arrow_down),
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    controller: jobRolesController,
                    label: locale?.jobRoles ?? 'Job Roles',
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale?.jobRolesAreRequired ??
                            'Job roles are required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FilledButton(
                      onPressed: () => pickImage(false),
                      child: Text(
                        locale?.uploadYourIqama ?? 'Upload your iqama',
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: selectedImage != null
                            ? Image.file(File(selectedImage!.path), height: 130)
                            : widget.workerData?.docUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.workerData!.docUrl ?? "",
                                height: 130,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.maxFinite,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AccountBloc>().add(
                            UpdateProfileEvent(
                              user: UserModel(
                                uid: widget.workerData?.uid ?? '',
                                name: nameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                districtName: districtNameController.text,
                                jobRoles: jobRolesController.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .toList(),
                                profileUrl: profileImageUrl,
                              ),
                              selectedIqamaImage: selectedImage,
                              selectedProfileImage: selectedProfileImage,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: state is UpdateProfileLoading
                          ? Loader(color: Colors.white, size: 20)
                          : Text(
                              locale?.update ?? 'Update',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    districtNameController.dispose();
    jobRolesController.dispose();
    super.dispose();
  }
}
