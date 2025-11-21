import 'dart:convert';
import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/common_widget/searchable_dropdown.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location_selection.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  List<Region> regions = [];
  Region? selectedRegion;
  City? selectedCity;
  District? selectedDistrict;
  bool isLoadingLocations = true;
  XFile? selectedImage;
  XFile? selectedProfileImage;
  List<String> selectedCertifications = [];
  List<PlatformFile> certifications = [];

  // Job categories and selected job roles
  Map<String, Map<String, String>> jobCategories = {};
  List<String> selectedJobRoles = [];
  bool isCategoriesLoading = true;

  Future<void> _pickCertifications() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        // Validate file sizes
        for (var file in result.files) {
          if (file.size > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${file.name} ${AppLocalizations.of(context)?.fileTooLarge ?? 'is too large (max 5MB)'}',
                  ),
                ),
              );
            }
            return;
          }
        }

        setState(() {
          certifications.addAll(result.files);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking certifications: $e');
      }
    }
  }

  void _removeCertification(int index) {
    setState(() {
      certifications.removeAt(index);
    });
  }

  void fillContent() {
    if (widget.workerData != null) {
      profileImageUrl = widget.workerData!.profileUrl;
      nameController.text = widget.workerData!.name ?? '';
      emailController.text = widget.workerData!.email ?? '';
      phoneController.text = widget.workerData!.phone ?? '';
      selectedJobRoles = widget.workerData!.jobRoles ?? [];
      selectedCertifications = widget.workerData!.certifications ?? [];

      // ✅ Pre-select location from detailedLocation
      if (widget.workerData!.detailedLocation != null) {
        final detailedLoc = widget.workerData!.detailedLocation!;
        // Will be set after provinces are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preselectLocation(detailedLoc);
        });
      }
    }
  }

  void _preselectLocation(DetailedLocationModel detailedLoc) {
    if (regions.isEmpty) return;

    // Find and select region
    final region = regions.firstWhere(
      (r) => r.regionId == detailedLoc.regionId,
      orElse: () => regions.first,
    );

    setState(() {
      selectedRegion = region;

      // Find and select city
      if (region.cities.isNotEmpty) {
        final city = region.cities.firstWhere(
          (c) => c.cityId == detailedLoc.cityId,
          orElse: () => region.cities.first,
        );

        selectedCity = city;

        // Find and select district
        if (city.districts.isNotEmpty) {
          final district = city.districts.firstWhere(
            (d) => d.districtId == detailedLoc.neighborhoodId,
            orElse: () => city.districts.first,
          );

          selectedDistrict = district;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fillContent();
    _loadLocations();
    loadJobCategories();
  }

  /// Load job categories from Firebase
  Future<void> loadJobCategories() async {
    setState(() {
      isCategoriesLoading = true;
    });

    try {
      final categories = await AppServices.fetchJobCategories();
      setState(() {
        jobCategories = categories;
        isCategoriesLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        isCategoriesLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadCategories ??
                  'Failed to load job categories',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLocations() async {
    setState(() => isLoadingLocations = true);
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/saudi_hierarchical.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        regions = jsonData.map((r) => Region.fromJson(r)).toList();
        isLoadingLocations = false;
      });

      // After loading, pre-select if data exists
      if (widget.workerData?.detailedLocation != null) {
        _preselectLocation(widget.workerData!.detailedLocation!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading locations: $e');
      }
      setState(() => isLoadingLocations = false);
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

  void selectJobRolesBottomSheet() {
    List<String> tempSelectedJobRoles = List.from(selectedJobRoles);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentLanguage =
                AppLocalizations.of(context)?.localeName ?? 'en';
            final isArabic = currentLanguage == 'ar';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Drag handle
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.selectJobRoles ??
                                        'Select Job Roles',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tempSelectedJobRoles.length} ${AppLocalizations.of(context)?.selected ?? 'selected'}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selected roles preview (chips)

                      // Available roles list
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (jobCategories.isNotEmpty)
                              Text(
                                AppLocalizations.of(context)?.availableRoles ??
                                    'Available Roles',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 8),

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

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelectedJobRoles.removeWhere(
                                            (role) =>
                                                role == displayName ||
                                                role == entry.value['en'] ||
                                                role == entry.value['ar'],
                                          );
                                        } else {
                                          tempSelectedJobRoles.removeWhere(
                                            (role) =>
                                                role == displayName ||
                                                role == entry.value['en'] ||
                                                role == entry.value['ar'],
                                          );
                                          tempSelectedJobRoles.add(displayName);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.secondary.withOpacity(
                                                0.08,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.secondary.withOpacity(
                                                  0.3,
                                                )
                                              : Colors.grey[200]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkbox
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.secondary
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.secondary
                                                    : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),

                                          // Role name
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.secondary
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Bottom action button
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: tempSelectedJobRoles.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      selectedJobRoles.clear();
                                      selectedJobRoles.addAll(
                                        tempSelectedJobRoles,
                                      );
                                    });
                                    Navigator.pop(context);
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)?.apply ?? 'Apply'} (${tempSelectedJobRoles.length})',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

        if (!await file.exists()) {
          return;
        }

        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.imageIsTooLargePleaseSelectAnImageSmallerThan5MB,
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
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
      if (mounted) {
        // Handle error gracefully
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
            content: Text(
              '${AppLocalizations.of(context)?.error}: ${e.toString()}',
            ),
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
    final isArabic = LocalStore.getUserlanguage() == 'ar';
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
                    // ✅ Use detailedLocation instead of districtName
                    detailedLocation: DetailedLocationModel(
                      regionId: selectedRegion?.regionId,
                      regionEn: selectedRegion?.regionEn,
                      regionAr: selectedRegion?.regionAr,
                      cityId: selectedCity?.cityId,
                      cityEn: selectedCity?.cityEn,
                      cityAr: selectedCity?.cityAr,
                      neighborhoodId: selectedDistrict?.districtId,
                      neighborhoodEn: selectedDistrict?.districtEn,
                      neighborhoodAr: selectedDistrict?.districtAr,
                    ),
                    jobRoles: selectedJobRoles,
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

              LocalStore.storeUserData(updatedUser);
              context.read<LoginBloc>().add(RefreshUserData());

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
                                    placeholder: (context, url) => Center(
                                      child: Loader(
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
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
                    label:
                        "${locale?.emailAddress ?? 'Email Address'} ${locale?.optional ?? "Optional"}",
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    readOnly: false,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!emailRegex.hasMatch(value)) {
                          return AppLocalizations.of(
                                context,
                              )?.pleaseEnterValidEmail ??
                              'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormWidget(
                    readOnly: true,
                    enabled: false,
                    forceLtr: isArabic,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    isPhoneNumber: true,
                    label: locale?.phoneNumber ?? 'Phone Number',
                    validator: (value) {
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField<Region>(
                    label: '${locale?.province ?? 'Region'} *',
                    value: selectedRegion,
                    items: regions,
                    itemLabel: (region) => region.getName(isArabic),
                    onChanged: (region) {
                      setState(() {
                        selectedRegion = region;
                        selectedCity = null;
                        selectedDistrict = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return locale?.pleaseSelectProvince ??
                            'Please select a region';
                      }
                      return null;
                    },
                  ),

                  if (selectedRegion != null) ...[
                    const SizedBox(height: 16),

                    // ✅ City Dropdown
                    _buildDropdownField<City>(
                      label: '${locale?.city ?? 'City'} *',
                      value: selectedCity,
                      items: selectedRegion!.cities,
                      itemLabel: (city) => city.getName(isArabic),
                      onChanged: (city) {
                        setState(() {
                          selectedCity = city;
                          selectedDistrict = null;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return locale?.pleaseSelectCity ??
                              'Please select a city';
                        }
                        return null;
                      },
                    ),
                  ],

                  if (selectedCity != null) ...[
                    const SizedBox(height: 16),

                    // ✅ District Dropdown
                    _buildDropdownField<District>(
                      label: '${locale?.neighborhood ?? 'District'} *',
                      value: selectedDistrict,
                      items: selectedCity!.districts,
                      itemLabel: (district) => district.getName(isArabic),
                      onChanged: (district) {
                        setState(() {
                          selectedDistrict = district;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return locale?.pleaseSelectNeighborhood ??
                              'Please select a district';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Replace TextFormWidget with custom job roles container
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale?.jobRoles ?? 'Job Roles',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: isCategoriesLoading
                            ? null
                            : selectJobRolesBottomSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: selectedJobRoles.isEmpty
                                    ? Text(
                                        locale?.selectJobRoles ??
                                            'Select job roles',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: selectedJobRoles.map((role) {
                                          return Chip(
                                            label: Text(
                                              getJobCategoryDisplayName(
                                                getJobCategoryKey(role),
                                              ),
                                              style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                              ),
                                            ),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                            onDeleted: () {
                                              setState(() {
                                                selectedJobRoles.remove(role);
                                              });
                                            },
                                            backgroundColor: AppColors.secondary
                                                .withOpacity(0.1),
                                            labelStyle: TextStyle(
                                              color: AppColors.secondary,
                                            ),
                                            deleteIconColor:
                                                AppColors.secondary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          );
                                        }).toList(),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: selectedJobRoles.isEmpty
                                    ? Colors.grey
                                    : AppColors.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 16),

                  // Certifications Upload
                  // Certifications Upload
                  Text(
                    '${AppLocalizations.of(context)?.certifications ?? 'Certifications'} (${AppLocalizations.of(context)?.optional ?? 'Optional'})',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickCertifications,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      AppLocalizations.of(context)?.uploadCertifications ??
                          'Upload Certifications',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Display existing certifications (URLs)
                  if (widget.workerData!.certifications != null &&
                      widget.workerData!.certifications!.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.workerData!.certifications!.length,
                      itemBuilder: (context, index) {
                        // final certUrl = widget.user.certifications![index];
                        return ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text('Certificate ${index + 1}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.workerData!.certifications!.removeAt(
                                  index,
                                );
                              });
                            },
                          ),
                        );
                      },
                    ),

                  // Display newly picked certifications (Local Files)
                  if (certifications.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: certifications.length,
                      itemBuilder: (context, index) {
                        final file = certifications[index];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(file.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeCertification(index),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.maxFinite,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // ✅ Validation for location
                          if (selectedRegion == null ||
                              selectedCity == null ||
                              selectedDistrict == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select complete address'),
                              ),
                            );
                            return;
                          }

                          // Validation for job roles
                          if (selectedJobRoles.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  locale?.pleaseSelectAtLeastOneJobRole ??
                                      'Please select at least one job role',
                                ),
                              ),
                            );
                            return;
                          }

                          // ✅ Create DetailedLocationModel
                          final detailedLocation = DetailedLocationModel(
                            regionId: selectedRegion!.regionId,
                            regionEn: selectedRegion!.regionEn,
                            regionAr: selectedRegion!.regionAr,
                            cityId: selectedCity!.cityId,
                            cityEn: selectedCity!.cityEn,
                            cityAr: selectedCity!.cityAr,
                            neighborhoodId: selectedDistrict!.districtId,
                            neighborhoodEn: selectedDistrict!.districtEn,
                            neighborhoodAr: selectedDistrict!.districtAr,
                            lat: selectedDistrict!.latitude,
                            lon: selectedDistrict!.longitude,
                          );

                          context.read<AccountBloc>().add(
                            UpdateProfileEvent(
                              user: UserModel(
                                uid: widget.workerData?.uid ?? '',
                                name: nameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                detailedLocation:
                                    detailedLocation, // ✅ Use detailedLocation
                                jobRoles: selectedJobRoles,
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
                                certifications: widget
                                    .workerData!
                                    .certifications, // Pass existing (modified) certifications
                              ),
                              selectedIqamaImage: selectedImage,
                              selectedProfileImage: selectedProfileImage,
                              newCertifications:
                                  certifications, // Pass new certifications
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

  Widget _buildDropdownField<T extends Object>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return SearchableDropdown<T>(
      label: label,
      value: value,
      items: items,
      itemLabel: itemLabel,
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
