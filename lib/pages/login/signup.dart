import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/multiple_location_selector.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/sanitize_number_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class Signup extends StatefulWidget {
  final String email;
  final String password;
  const Signup({super.key, required this.email, required this.password});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool isDetectingLocation = false;
  bool isDeletingUser = false;

  List<LocationModel> locations = [];
  LocationModel? selectedLocation;
  XFile? selectedImage;
  XFile? selectedProfileImage;
  bool isSaving = false;
  double? imageUploadProgress;
  String? docUrl;
  String? profileImageUrl;
  final Map<String, Map<String, String>> jobCategories = {
    'plumbing': {'en': 'Plumbing', 'ar': 'السباكة'},
    'ac': {'en': 'A/C', 'ar': 'تكييف الهواء'},
    'cleaning': {'en': 'Cleaning', 'ar': 'التنظيف'},
    'electrician': {'en': 'Electrician', 'ar': 'كهربائي'},
    'flooring': {'en': 'Flooring', 'ar': 'الأرضيات'},
    'painter': {'en': 'Painter', 'ar': 'دهان'},
    'other': {'en': 'Other', 'ar': 'أخرى'},
  };

  final _formkey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController districtNameController = TextEditingController();
  final TextEditingController jobRolesController = TextEditingController();
  List<String> selectedJobRoles = [];
  Future pickImage(bool isProfile) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!await validateFileSize(image)) {
        return;
      }

      if (isProfile) {
        setState(() => selectedProfileImage = image);
        cropImage(true);
      } else {
        setState(() => selectedImage = image);
        cropImage(false);
      }
    }
  }

  Future cropImage(bool isProfile) async {
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
          toolbarTitle: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: isProfile,
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
  }

  Future<bool> validateFileSize(XFile file) async {
    final fileSize = await File(file.path).length();
    const maxSize = 20 * 1024 * 1024;

    if (fileSize > maxSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File is too large. Please select a smaller image (max 20MB).',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    return true;
  }

  @override
  void initState() {
    loadLocations();
    super.initState();
  }

  Future<void> _determinePosition() async {
    setState(() => isDetectingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.locationPermissionsAreDenied ??
                      'Location permissions are denied.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() => isDetectingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                      context,
                    )?.locationPermissionsArePermanentlyDenied ??
                    'Location permissions are permanently denied',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => isDetectingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromLatLng(position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.failedToDetectLocation ?? 'Failed to detect location'}: ${e.toString()}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => isDetectingLocation = false);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final localityName = place.locality ?? "Unknown";

        setState(() {
          selectedLocation = LocationModel(
            name: localityName,
            name_ar: localityName,
          );
          districtNameController.text = localityName;
        });
        if (districtNameController.text.isEmpty) {
          setState(() => isDetectingLocation = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.failedToGetAddress ?? 'Failed to get address'}: ${e.toString()}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String getJobCategoryDisplayName(String key) {
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isArabic = currentLanguage == 'ar';
    return jobCategories[key]?[isArabic ? 'ar' : 'en'] ?? key;
  }

  String getJobCategoryKey(String displayName) {
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isArabic = currentLanguage == 'ar';

    for (var entry in jobCategories.entries) {
      if (entry.value[isArabic ? 'ar' : 'en'] == displayName) {
        return entry.key;
      }
    }
    return displayName;
  }

  void selectLocationBottomSheet() async {
    final TextEditingController searchController = TextEditingController();
    List<LocationModel> filteredLocations = List.from(locations);
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isArabic = currentLanguage == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final safePaddings = MediaQuery.of(context).padding;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.selectLocation ??
                              'Select Location',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)?.searchLocation,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          if (value.isEmpty) {
                            filteredLocations = List.from(locations);
                          } else {
                            filteredLocations = locations.where((location) {
                              final nameMatch =
                                  location.name?.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ) ??
                                  false;
                              final nameArMatch =
                                  location.name_ar?.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ) ??
                                  false;
                              return nameMatch || nameArMatch;
                            }).toList();
                          }
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: AppColors.secondary,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)?.useCurrentLocation ??
                          'Use Current Location',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _determinePosition();
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: filteredLocations.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)?.noLocationsFound ??
                                  'No locations found',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredLocations.length,
                            padding: EdgeInsets.only(
                              bottom: safePaddings.bottom + 16,
                            ),
                            itemBuilder: (context, index) {
                              final location = filteredLocations[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.grey2,
                                ),
                                title: Text(
                                  isArabic
                                      ? (location.name_ar ??
                                            location.name ??
                                            '')
                                      : (location.name ?? ''),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  setState(() => selectedLocation = location);
                                  districtNameController.text = isArabic
                                      ? (location.name_ar ??
                                            location.name ??
                                            '')
                                      : (location.name ?? '');
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future loadLocations() async {
    try {
      var response = await AppFirestore.locationsCollectionRef.get();
      final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
      final isArabic = currentLanguage == 'ar';

      setState(() {
        locations = response.docs
            .map((e) => LocationModel.fromQuerySnapshot(e))
            .toList();

        locations.sort((a, b) {
          final aName = isArabic ? (a.name_ar ?? a.name ?? '') : (a.name ?? '');
          final bName = isArabic ? (b.name_ar ?? b.name ?? '') : (b.name ?? '');
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
      });
    } catch (e) {
      return;
    }
  }

  void selectJobRolesBottomSheet() {
    List<String> tempSelectedJobRoles = List.from(selectedJobRoles);
    TextEditingController customRolesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentLanguage =
                AppLocalizations.of(context)?.localeName ?? 'en';
            final isArabic = currentLanguage == 'ar';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.selectJobRoles ??
                                  'Select Job Roles',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            ...jobCategories.entries.map((entry) {
                              final displayName =
                                  entry.value[isArabic ? 'ar' : 'en'] ??
                                  entry.value['en']!;

                              final isSelected =
                                  tempSelectedJobRoles.contains(displayName) ||
                                  tempSelectedJobRoles.contains(
                                    entry.value['en'],
                                  ) ||
                                  tempSelectedJobRoles.contains(
                                    entry.value['ar'],
                                  );

                              return CheckboxListTile(
                                title: Text(
                                  displayName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: isSelected,
                                activeColor: AppColors.secondary,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      tempSelectedJobRoles.removeWhere(
                                        (role) =>
                                            role == displayName ||
                                            role == entry.value['en'] ||
                                            role == entry.value['ar'],
                                      );

                                      tempSelectedJobRoles.add(displayName);
                                    } else {
                                      tempSelectedJobRoles.removeWhere(
                                        (role) =>
                                            role == displayName ||
                                            role == entry.value['en'] ||
                                            role == entry.value['ar'],
                                      );
                                    }
                                  });
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.addCustomJobRoles ??
                                    'Add Custom Job Roles',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: customRolesController,
                                decoration: InputDecoration(
                                  hintText:
                                      AppLocalizations.of(
                                        context,
                                      )?.enterAdditionalJobRoles ??
                                      'Enter additional job roles (comma separated)',
                                  hintStyle: GoogleFonts.dmSans(fontSize: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    List<String> finalJobRoles = List.from(
                                      tempSelectedJobRoles,
                                    );

                                    if (customRolesController.text.isNotEmpty) {
                                      final customRoles = customRolesController
                                          .text
                                          .split(',')
                                          .map((e) => e.trim())
                                          .where((e) => e.isNotEmpty)
                                          .toList();

                                      for (var role in customRoles) {
                                        if (!finalJobRoles.contains(role)) {
                                          finalJobRoles.add(role);
                                        }
                                      }
                                    }

                                    setState(() {
                                      selectedJobRoles.clear();
                                      selectedJobRoles.addAll(finalJobRoles);
                                      jobRolesController.text = finalJobRoles
                                          .join(', ');
                                    });

                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)?.done ??
                                        'Done',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final locale = AppLocalizations.of(context);
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, loginState) {
        final isLoading = loginState is SignUpLoading;
        return BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is SignUpSuccess) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(byPassUid: LocalStore.getUID()),
                ),
                (route) => false,
              );
            }
            if (state is SignUpFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Scaffold(
            body: Form(
              key: _formkey,
              child: ListView(
                padding: EdgeInsets.only(
                  top: safePadding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: safePadding.bottom + 16,
                ),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      Text(
                        locale?.createAccount ?? '',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    locale?.pleaseFillTheInputBelowHereToContinue ?? '',
                    style: GoogleFonts.dmSans(
                      color: Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 34),
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
                    label: locale?.yourName ?? '',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return locale?.nameIsRequired ?? '';
                      } else if (value.length < 3) {
                        return locale?.enterAValidName ?? '';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    controller: phoneNumberController,
                    label: locale?.phoneNumber ?? '',
                    isPhoneNumber: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      TextFormWidget(
                        controller: districtNameController,
                        label: locale?.districtName ?? '',
                        onTap: () async {
                          final location =
                              await LocationSelectorHelper.showLocationSelector(
                                context: context,
                                locations: locations,
                                selectedLocation: selectedLocation,
                                onUseCurrentLocation: () async =>
                                    await _determinePosition(),
                              );
                          if (location != null) {
                            setState(() {
                              selectedLocation = location;
                              final isArabic =
                                  AppLocalizations.of(context)?.localeName ==
                                  'ar';
                              districtNameController.text = isArabic
                                  ? (location.name_ar ?? location.name ?? '')
                                  : (location.name ?? '');
                            });
                          }
                        },
                        validator: (value) {
                          if (selectedLocation == null) {
                            return locale?.locationIsRequired ?? '';
                          }
                          return null;
                        },
                        suffix: isDetectingLocation
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                height: 10,
                                width: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    controller: jobRolesController,
                    label: locale?.jobRoles ?? '',
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onTap: selectJobRolesBottomSheet,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                              context,
                            )?.jobRolesAreRequired ??
                            'Job Roles are required';
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
                        AppLocalizations.of(context)?.uploadYourIqama ??
                            'Upload your iqama',
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
                            : docUrl != null
                            ? CachedNetworkImage(
                                imageUrl: docUrl ?? "",
                                height: 130,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              try {
                                if (!_formkey.currentState!.validate()) return;
                                if (selectedImage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.pleaseSelectYourIdDocument ??
                                            'Please select your ID document',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                if (selectedJobRoles.isEmpty &&
                                    jobRolesController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.pleaseSelectAtLeastOneJobRole ??
                                            'Please select at least one job role',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                bool isPhoneNumberExists =
                                    await AppServices.checkThePhoneExists(
                                      SanitizeNumberHelper.sanitizePhoneNumber(
                                        phoneNumberController.text.trim(),
                                      ),
                                    );
                                if (isPhoneNumberExists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.phoneNumberAlreadyExists ??
                                            'Phone number already exists',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                List<String> jobRoles = [];
                                for (String role in selectedJobRoles) {
                                  String jobKey = getJobCategoryKey(role);
                                  if (jobCategories.containsKey(jobKey)) {
                                    jobRoles.add(
                                      jobCategories[jobKey]!['en']!.trim(),
                                    );
                                  } else {
                                    jobRoles.add(role.trim());
                                  }
                                }

                                if (jobRolesController.text.trim().isNotEmpty) {
                                  final customRoles = jobRolesController.text
                                      .trim()
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();

                                  for (String customRole in customRoles) {
                                    if (!jobRoles.contains(customRole)) {
                                      jobRoles.add(customRole.trim());
                                    }
                                  }
                                }
                                jobRoles = jobRoles
                                    .map((e) => e.trim())
                                    .toSet()
                                    .toList();
                                UserModel user = UserModel(
                                  name: nameController.text.trim(),
                                  email: widget.email,
                                  phone: phoneNumberController.text.trim(),
                                  country: "SA",
                                  districtName: districtNameController.text
                                      .trim(),
                                  jobRoles: jobRoles,
                                  createdAt: Timestamp.now(),
                                  updatedAt: Timestamp.now(),
                                  isVerified: false,
                                );

                                context.read<LoginBloc>().add(
                                  SignUpButtonPressed(
                                    email: widget.email,
                                    password: widget.password,
                                    userModel: user,
                                    idImage: selectedImage,
                                    profileImage: selectedProfileImage,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'An error occurred: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLoading
                            ? AppColors.secondary.withOpacity(0.6)
                            : AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? Loader(size: 20, color: Colors.white)
                          : Text(
                              locale?.createAccount ?? '',
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
          ),
        );
      },
    );
  }
}
