import 'dart:convert';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/location_selection.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:aboglumbo_bbk_panel/services/notification.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class Signup extends StatefulWidget {
  final String uid;

  const Signup({super.key, required this.uid});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  bool isCreatingAccount = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController =
      TextEditingController(); // ✅ Add email field

  XFile? profileImage;
  XFile? idImage;
  List<PlatformFile> certifications = [];

  List<Province> provinces = [];
  Province? selectedProvince;
  Governorate? selectedGovernorate;
  Neighborhood? selectedNeighborhood;

  String? selectedDistrictName;
  LocationModel? selectedLocation;
  List<LocationModel> locations = [];

  List<Map<String, dynamic>> jobCategories = [];
  List<String> selectedJobRoles = [];
  bool isLoadingCategories = true;
  bool isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    _loadJobCategories();
    _loadLocations();
  }

  // ✅ FIXED: Proper conversion from AppServices return type
  Future<void> _loadJobCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final categoriesMap = await AppServices.fetchJobCategories();

      // Convert Map<String, Map<String, String>> to List<Map<String, dynamic>>
      jobCategories = categoriesMap.entries.map((entry) {
        return <String, dynamic>{
          'id': entry.key,
          'name': entry.value['en'] ?? '',
          'nameAr': entry.value['ar'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading job categories: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadCategories ??
                  'Failed to load job categories',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingCategories = false);
      }
    }
  }

  Future<void> _loadLocations() async {
    setState(() => isLoadingLocations = true);
    try {
      // Load JSON from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/saudi_locations.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        provinces = jsonData.map((p) => Province.fromJson(p)).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading locations: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingLocations = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle:
                  AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          final fileSize = await File(croppedFile.path).length();
          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.fileTooLarge ??
                        'File is too large (max 20MB)',
                  ),
                ),
              );
            }
            return;
          }

          setState(() {
            profileImage = XFile(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking profile image: $e');
      }
    }
  }

  Future<void> _pickIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressQuality: 80,
          maxWidth: 2048,
          maxHeight: 2048,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle:
                  AppLocalizations.of(context)?.cropDocument ?? 'Crop Document',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
            ),
            IOSUiSettings(
              title:
                  AppLocalizations.of(context)?.cropDocument ?? 'Crop Document',
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            idImage = XFile(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking ID image: $e');
      }
    }
  }

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

  Future<void> _selectJobRoles() async {
    if (jobCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.noJobCategoriesAvailable ??
                'No job categories available',
          ),
        ),
      );
      return;
    }

    final selectedRoles = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.selectJobRoles ??
                            'Select Job Roles',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, selectedJobRoles),
                        child: Text(
                          AppLocalizations.of(context)?.done ?? 'Done',
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: jobCategories.length,
                      itemBuilder: (context, index) {
                        final category = jobCategories[index];
                        final categoryName =
                            LocalStore.getUserlanguage() == 'ar'
                            ? (category['nameAr'] ?? category['name'])
                            : category['name'];
                        final categoryId = category['id'];

                        final isSelected = selectedJobRoles.contains(
                          categoryId,
                        );

                        return CheckboxListTile(
                          title: Text(categoryName),
                          value: isSelected,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selectedJobRoles.add(categoryId);
                              } else {
                                selectedJobRoles.remove(categoryId);
                              }
                            });
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

    if (selectedRoles != null) {
      setState(() {
        selectedJobRoles = selectedRoles;
      });
    }
  }

  String _getJobRoleNames() {
    if (selectedJobRoles.isEmpty) return '';

    return selectedJobRoles
        .map((roleId) {
          final category = jobCategories.firstWhere(
            (cat) => cat['id'] == roleId,
            orElse: () => {'name': roleId, 'nameAr': roleId},
          );
          return LocalStore.getUserlanguage() == 'ar'
              ? (category['nameAr'] ?? category['name'])
              : category['name'];
        })
        .join(', ');
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validate all location fields are selected
    if (selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectProvince ??
                'Please select a province',
          ),
        ),
      );
      return;
    }

    if (selectedGovernorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectCity ??
                'Please select a city',
          ),
        ),
      );
      return;
    }

    if (selectedNeighborhood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectNeighborhood ??
                'Please select a neighborhood',
          ),
        ),
      );
      return;
    }

    if (selectedJobRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectAtLeastOneJobRole ??
                'Please select at least one job role',
          ),
        ),
      );
      return;
    }

    if (idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseUploadIdDocument ??
                'Please upload ID document',
          ),
        ),
      );
      return;
    }

    // ✅ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 24, child: Loader(color: AppColors.primary)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(dialogContext)?.creatingAccount ??
                      'Creating your account...',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(dialogContext)?.pleaseWait ??
                      'Please wait, this may take a moment',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      String? profileImageUrl;
      String? idImageUrl;
      List<String>? certificationUrls;

      // Upload profile image
      if (profileImage != null) {
        try {
          profileImageUrl = await UploadToFireStorage().uploadFile(
            profileImage!,
            'agents/profiles',
          );
        } catch (e) {
          if (kDebugMode) print('Profile upload failed: $e');
        }
      }

      // Upload ID image
      if (idImage != null) {
        try {
          idImageUrl = await UploadToFireStorage().uploadFile(
            idImage!,
            'agents/documents',
          );
        } catch (e) {
          if (kDebugMode) print('ID upload failed: $e');
        }
      }

      // Upload certifications
      if (certifications.isNotEmpty) {
        certificationUrls = [];
        for (var cert in certifications) {
          try {
            if (cert.path != null) {
              final fileRef = AppFireStorage.agentDocStorageRef.child(
                'agents/certifications/${DateTime.now().millisecondsSinceEpoch}_${cert.name}',
              );
              final uploadTask = fileRef.putFile(File(cert.path!));
              final snapshot = await uploadTask;
              final downloadUrl = await snapshot.ref.getDownloadURL();
              certificationUrls.add(downloadUrl);
            }
          } catch (e) {
            if (kDebugMode) print('Cert upload failed: $e');
          }
        }
      }

      // ✅ Create DetailedLocationModel
      final detailedLocation = DetailedLocationModel(
        provinceId: selectedProvince!.provinceId,
        provinceEn: selectedProvince!.provinceEn,
        provinceAr: selectedProvince!.provinceAr,
        governorateId: selectedGovernorate!.govId,
        governorateEn: selectedGovernorate!.govEn,
        governorateAr: selectedGovernorate!.govAr,
        neighborhoodId: selectedNeighborhood!.neighId,
        neighborhoodEn: selectedNeighborhood!.neighEn,
        neighborhoodAr: selectedNeighborhood!.neighAr,
      );

      // Create user document
      final userModel = UserModel(
        uid: widget.uid,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        country: "SA",
        detailedLocation: detailedLocation,
        jobRoles: selectedJobRoles,
        profileUrl: profileImageUrl,
        docUrl: idImageUrl,
        certifications: certificationUrls,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        isVerified: false,
        isAdmin: false,
        isOnline: false,
      );

      await AppFirestore.usersCollectionRef
          .doc(widget.uid)
          .set(userModel.toJson());

      // Save UID to local storage
      await LocalStore.putUID(widget.uid);

      // Refresh FCM token after account creation
      await NotificationServices.refreshFCMToken();

      // ✅ Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.accountCreatedSuccessfully ??
                  'Account created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Signup error: $e');
      }

      // ✅ Close loading dialog on error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToCreateAccount ??
                  'Failed to create account',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final isArabic = LocalStore.getUserlanguage() == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.completeRegistration ??
              'Complete Registration',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  AppLocalizations.of(context)?.cancelRegistration ??
                      'Cancel Registration?',
                ),
                content: Text(
                  AppLocalizations.of(
                        context,
                      )?.cancelRegistrationConfirmation ??
                      'Are you sure you want to cancel? All entered data will be lost.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context)?.no ?? 'No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      AppLocalizations.of(context)?.yes ?? 'Yes',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: safePadding.bottom + 16,
          ),
          children: [
            // Loading indicator
            if (isLoadingLocations || isLoadingCategories)
              const LinearProgressIndicator(),

            const SizedBox(height: 16),

            // Profile Image Picker
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: profileImage != null
                          ? FileImage(File(profileImage!.path))
                          : null,
                      child: profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name Field
            TextFormWidget(
              controller: nameController,
              label: AppLocalizations.of(context)?.fullName ?? 'Full Name',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              readOnly: false,
              enabled: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)?.pleaseEnterYourName ??
                      'Please enter your name';
                }
                if (value.length < 3) {
                  return AppLocalizations.of(context)?.nameTooShort ??
                      'Name must be at least 3 characters';
                }
                return null;
              },
            ),

            // Phone Field (Read-only)
            TextFormWidget(
              controller: phoneController,
              label:
                  AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
              keyboardType: TextInputType.phone,
              enabled: false,
            ),

            TextFormWidget(
              controller: emailController,
              label:
                  '${AppLocalizations.of(context)?.email ?? 'Email'} (${AppLocalizations.of(context)?.optional ?? 'Optional'})',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                // Only validate if user entered something
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

            // Province Dropdown
            _buildDropdownField<Province>(
              label: AppLocalizations.of(context)?.province ?? 'Province',
              value: selectedProvince,
              items: provinces,
              itemLabel: (province) => province.getName(isArabic),
              onChanged: (province) {
                setState(() {
                  selectedProvince = province;
                  selectedGovernorate = null;
                  selectedNeighborhood = null;
                });
              },
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)?.pleaseSelectProvince ??
                      'Please select a province';
                }
                return null;
              },
            ),

            if (selectedProvince != null) ...[
              const SizedBox(height: 16),

              // Governorate Dropdown
              _buildDropdownField<Governorate>(
                label: AppLocalizations.of(context)?.city ?? 'City',
                value: selectedGovernorate,
                items: selectedProvince!.governorates,
                itemLabel: (gov) => gov.getName(isArabic),
                onChanged: (gov) {
                  setState(() {
                    selectedGovernorate = gov;
                    selectedNeighborhood = null;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)?.pleaseSelectCity ??
                        'Please select a city';
                  }
                  return null;
                },
              ),
            ],

            if (selectedGovernorate != null) ...[
              const SizedBox(height: 16),

              // Neighborhood Dropdown
              _buildDropdownField<Neighborhood>(
                label:
                    AppLocalizations.of(context)?.neighborhood ??
                    'Neighborhood',
                value: selectedNeighborhood,
                items: selectedGovernorate!.neighborhoods,
                itemLabel: (neigh) => neigh.getName(isArabic),
                onChanged: (neigh) {
                  setState(() {
                    selectedNeighborhood = neigh;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(
                          context,
                        )?.pleaseSelectNeighborhood ??
                        'Please select a neighborhood';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Job Roles Selector
            Text(
              AppLocalizations.of(context)?.jobRoles ?? 'Job Roles',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: isLoadingCategories ? null : _selectJobRoles,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedJobRoles.isEmpty
                            ? (AppLocalizations.of(context)?.selectJobRoles ??
                                  'Select Job Roles')
                            : _getJobRoleNames(),
                        style: GoogleFonts.dmSans(
                          color: selectedJobRoles.isEmpty
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ID Document Upload
            Text(
              '${AppLocalizations.of(context)?.idDocument ?? 'ID Document'} *',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickIdImage,
              icon: const Icon(Icons.upload_file),
              label: Text(
                idImage == null
                    ? (AppLocalizations.of(context)?.uploadIdDocument ??
                          'Upload ID Document')
                    : (AppLocalizations.of(context)?.idDocumentUploaded ??
                          'ID Document Uploaded'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: idImage != null
                    ? Colors.green
                    : AppColors.primary,
              ),
            ),

            if (idImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(idImage!.path),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => setState(() => idImage = null),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

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
              icon: const Icon(Icons.attach_file),
              label: Text(
                AppLocalizations.of(context)?.uploadCertifications ??
                    'Upload Certifications',
              ),
            ),

            if (certifications.isNotEmpty)
              ...certifications.asMap().entries.map((entry) {
                int index = entry.key;
                PlatformFile file = entry.value;
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(file.name),
                  subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeCertification(index),
                  ),
                );
              }),

            // Submit Button
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: SizedBox(
                width: double.maxFinite,
                height: 55,
                child: ElevatedButton(
                  onPressed: isCreatingAccount ? null : _submitSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isCreatingAccount
                      ? Loader()
                      : Text(
                          AppLocalizations.of(context)?.createAccount ??
                              'Create Account',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: GoogleFonts.dmSans(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
