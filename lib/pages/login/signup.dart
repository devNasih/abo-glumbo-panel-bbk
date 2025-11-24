import 'dart:convert';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/searchable_dropdown.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/location_selection.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
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
import 'package:open_filex/open_filex.dart';

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

  List<Region> regions = [];
  Region? selectedRegion;
  City? selectedCity;
  District? selectedDistrict;

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
        'assets/data/saudi_hierarchical.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        regions = jsonData.map((r) => Region.fromJson(r)).toList();
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

  Future<int?> _showSourceSelector() async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                AppLocalizations.of(context)?.selectSource ?? 'Select Source',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)?.camera ?? 'Camera'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(AppLocalizations.of(context)?.files ?? 'Files'),
              onTap: () => Navigator.pop(context, 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeIdImage() async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        idImage = null;
      });
    }
  }

  Future<void> _pickIdImage() async {
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      XFile? image;
      bool isImage = true;

      if (source == 0) {
        // Camera
        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
      } else {
        // Files
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.path != null) {
            image = XFile(file.path!);
            final ext = file.extension?.toLowerCase();
            isImage = ['jpg', 'jpeg', 'png'].contains(ext);
          }
        }
      }

      if (image != null) {
        if (isImage) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            compressQuality: 80,
            maxWidth: 2048,
            maxHeight: 2048,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle:
                    AppLocalizations.of(context)?.cropDocument ??
                    'Crop Document',
                toolbarColor: AppColors.primary,
                toolbarWidgetColor: Colors.white,
                statusBarColor: AppColors.primary,
              ),
              IOSUiSettings(
                title:
                    AppLocalizations.of(context)?.cropDocument ??
                    'Crop Document',
              ),
            ],
          );

          if (croppedFile != null) {
            setState(() {
              idImage = XFile(croppedFile.path);
            });
          }
        } else {
          setState(() {
            idImage = image;
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
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      if (source == 0) {
        // Camera
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (image != null) {
          final file = File(image.path);
          final size = await file.length();

          // Validate size
          if (size > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${image.name} ${AppLocalizations.of(context)?.fileTooLarge ?? 'is too large (max 5MB)'}',
                  ),
                ),
              );
            }
            return;
          }

          setState(() {
            certifications.add(
              PlatformFile(name: image.name, path: image.path, size: size),
            );
          });
        }
      } else {
        // Files
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
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking certifications: $e');
      }
    }
  }

  Future<void> _removeCertification(int index) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        certifications.removeAt(index);
      });
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
            content: Text(
              AppLocalizations.of(context)?.areYouSureYouWantToDeleteThisFile ??
                  'Are you sure you want to remove this file?',
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
        ) ??
        false;
  }

  void _showFullScreenImage(XFile file, BuildContext context) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)!.idDocument,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(File(file.path)),
              ),
            ),
          ),
        ),
      );
    } else {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open file: ${file.path}')),
          );
        }
      }
    }
  }

  void _viewCertification(PlatformFile file) async {
    if (file.path == null) return;
    final ext = file.extension?.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(file.name),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              InteractiveViewer(child: Image.file(File(file.path!))),
            ],
          ),
        ),
      );
    } else {
      final result = await OpenFilex.open(file.path!);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open file: ${file.path}')),
          );
        }
      }
    }
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
    if (selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectProvince ??
                'Please select a region',
          ),
        ),
      );
      return;
    }

    if (selectedCity == null) {
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

    if (selectedDistrict == null) {
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
          final ext = idImage!.path.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png'].contains(ext)) {
            idImageUrl = await UploadToFireStorage().uploadFile(
              idImage!,
              'agents/documents',
            );
          } else {
            final fileRef = AppFireStorage.agentDocStorageRef.child(
              'agents/documents/${DateTime.now().millisecondsSinceEpoch}_${idImage!.name}',
            );
            final uploadTask = fileRef.putFile(File(idImage!.path));
            final snapshot = await uploadTask;
            idImageUrl = await snapshot.ref.getDownloadURL();
          }
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

      // Create user document
      final userModel = UserModel(
        role: "technician",
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleCancelRegistration(); // ✅ We control navigation
        }
      },

      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context)?.completeRegistration ??
                'Complete Registration',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleCancelRegistration,
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: safePadding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(
                            context,
                          )?.pleaseEnterYourName ??
                          'Please enter your name';
                    }
                    if (value.trim().length < 3) {
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
                      AppLocalizations.of(context)?.phoneNumber ??
                      'Phone Number',
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

                // Region Dropdown
                _buildDropdownField<Region>(
                  hintText: AppLocalizations.of(
                    context,
                  )!.typeProvinceNameToSearch,
                  label: AppLocalizations.of(context)!.province,
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
                      return AppLocalizations.of(
                            context,
                          )?.pleaseSelectProvince ??
                          'Please select a region';
                    }
                    return null;
                  },
                ),

                if (selectedRegion != null) ...[
                  const SizedBox(height: 16),

                  // City Dropdown
                  _buildDropdownField<City>(
                    hintText: AppLocalizations.of(
                      context,
                    )!.typeCityNameToSearch,
                    label: AppLocalizations.of(context)!.city,
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
                        return AppLocalizations.of(context)!.pleaseSelectCity;
                      }
                      return null;
                    },
                  ),
                ],

                if (selectedCity != null) ...[
                  const SizedBox(height: 16),
                  // District Dropdown
                  _buildDropdownField<District>(
                    hintText: AppLocalizations.of(
                      context,
                    )!.typeNeighborhoodNameToSearch,
                    label: AppLocalizations.of(context)!.neighborhood,
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
                        return AppLocalizations.of(
                          context,
                        )!.pleaseSelectNeighborhood;
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Job Roles Selector
                Text(
                  AppLocalizations.of(context)!.jobRoles,
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
                                ? (AppLocalizations.of(
                                        context,
                                      )?.selectJobRoles ??
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
                  '${AppLocalizations.of(context)!.idDocument} *',
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
                        ? AppLocalizations.of(context)!.uploadIdDocument
                        : AppLocalizations.of(context)!.changeIdDocument,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: idImage != null
                        ? Colors.green
                        : AppColors.primary,
                  ),
                ),

                if (idImage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(idImage!, context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.idDocument,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.open_in_new,
                              color: Colors.grey.shade700,
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeIdImage(),
                              child: Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Certifications Upload
                Text(
                  '${AppLocalizations.of(context)!.certifications} (${AppLocalizations.of(context)!.optional})',
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
                    AppLocalizations.of(context)!.uploadCertifications,
                  ),
                ),

                if (certifications.isNotEmpty)
                  ...certifications.asMap().entries.map((entry) {
                    int index = entry.key;
                    PlatformFile file = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: GestureDetector(
                        onTap: () => _viewCertification(file),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Row(
                            children: [
                              Text(
                                file.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.open_in_new,
                                color: Colors.grey.shade700,
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeCertification(index),
                                child: Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    // return ListTile(
                    //   onTap: () => _viewCertification(file),
                    //   leading: const Icon(Icons.description),
                    //   title: Text(file.name),
                    //   subtitle: Align(
                    //     alignment: isArabic
                    //         ? Alignment.centerRight
                    //         : Alignment.centerLeft,
                    //     child: Directionality(
                    //       textDirection: TextDirection.ltr,
                    //       child: Text(
                    //         '${(file.size / 1024).toStringAsFixed(2)} KB',
                    //       ),
                    //     ),
                    //   ),
                    //   trailing: IconButton(
                    //     icon: const Icon(Icons.delete, color: Colors.red),
                    //     onPressed: () => _removeCertification(index),
                    //   ),
                    // );
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
                              AppLocalizations.of(context)!.createAccount,
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
        ),
      ),
    );
  }

  Widget _buildDropdownField<T extends Object>({
    required String label,
    required T? value,
    required List<T> items,
    required String hintText,
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
      hintText: hintText,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<bool> _handleCancelRegistration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelRegistration),
        content: Text(
          AppLocalizations.of(context)!.cancelRegistrationConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.yes,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }

      await LocalStore.clearUID();
      await LocalStore.putlogoutStatus(true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

      return false; // ✅ allow pop after handling
    }

    return false; // ✅ prevent default pop
  }
}
