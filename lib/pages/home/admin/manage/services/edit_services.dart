import 'dart:developer';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/multiple_location_selector.dart';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '/models/categories.dart';
import '/models/service.dart';
import '/models/location.dart';

class AddServicesDevPage extends StatefulWidget {
  const AddServicesDevPage({super.key, this.service});
  final ServiceModel? service;

  @override
  State<AddServicesDevPage> createState() => _AddServicesDevPageState();
}

class _AddServicesDevPageState extends State<AddServicesDevPage> {
  final _formKey = GlobalKey<FormState>();

  bool contentLoading = true;
  List<CategoryModel> categories = [];
  List<LocationModel> locations = []; // Add locations list
  bool isSaving = false;
  double? imageUploadProgress;

  bool isActive = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  XFile? selectedImage;
  CategoryModel? selectedCategory;
  List<LocationModel> selectedLocations = []; // Add selected locations

  final arabicFullRegex = RegExp(r'''^[\u0600-\u06FF
       \u0750-\u077F
       \u08A0-\u08FF
       \uFB50-\uFDFF
       \uFE70-\uFEFF
       \u0660-\u0669
       \u06F0-\u06F9
       \u200C-\u200F
       \s\n\r\d
       \.\,\!\?\،\؛\؟\:\-\(\)\[\]\"\'\u061F]+$''', multiLine: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCategories();
      await loadLocations(); // Load locations
      fillContents();
    });
  }

  Future loadCategories() async {
    setState(() => contentLoading = true);

    try {
      var response = await AppFirestore.categoriesCollectionRef
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        categories = response.docs.map((e) {
          return CategoryModel.fromQuerySnapshot(e);
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadCategories ??
                  'Failed to load categories',
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.retry ?? 'Retry',
              onPressed: loadCategories,
            ),
          ),
        );
      }
    }

    setState(() => contentLoading = false);
  }

  // Add method to load locations
  Future loadLocations() async {
    try {
      var response = await AppFirestore.locationsCollectionRef
          .get(); // Assuming you have a locations collection
      setState(() {
        locations = response.docs.map((e) {
          return LocationModel.fromQuerySnapshot(e);
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadLocations ??
                  'Failed to load locations',
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.retry ?? 'Retry',
              onPressed: loadLocations,
            ),
          ),
        );
      }
      // Set empty list on error to avoid null issues
      setState(() {
        locations = [];
      });
    }
  }

  void fillContents() async {
    if (widget.service != null) {
      nameController.text = widget.service!.name ?? '';
      nameArController.text = widget.service!.name_ar ?? '';
      descriptionController.text = widget.service!.description ?? '';
      descriptionArController.text = widget.service!.description_ar ?? '';
      priceController.text = widget.service!.price.toString();
      isActive = widget.service!.isActive;

      // Fill selected locations if service has locations
      if (widget.service!.locations.isNotEmpty) {
        selectedLocations = locations.where((location) {
          return widget.service!.locations.contains(location.id);
        }).toList();
      } else {
        selectedLocations = [];
      }

      try {
        selectedCategory = categories.firstWhere(
          (element) => element.id == widget.service?.category,
        );
      } catch (e) {
        log('Error: $e');
      }
    }
  }

  Future pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = image);
      await cropImage();
    }
  }

  Future cropImage() async {
    CroppedFile? res = await ImageCropper().cropImage(
      sourcePath: selectedImage!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
        ),
      ],
    );

    if (res != null) {
      setState(() => selectedImage = XFile(res.path));
    } else {
      final bool? shouldKeepImage = await showCropConfirmDialog(context);

      if (shouldKeepImage != true) {
        setState(() => selectedImage = null);
      }
      // If shouldKeepImage is true, we keep the original selectedImage as is
    }
  }

  // Method to show location selector
  Future<void> _showLocationSelector() async {
    final result = await LocationSelectorHelper.showMultipleLocationSelector(
      context: context,
      locations: locations,
      selectedLocations: selectedLocations,
      title:
          AppLocalizations.of(context)?.selectLocations ?? 'Select Locations',
      searchHint:
          AppLocalizations.of(context)?.searchLocation ?? 'Search location',
      noLocationsMessage:
          AppLocalizations.of(context)?.noLocationsFound ??
          'No locations found',
    );

    if (result != null) {
      setState(() {
        selectedLocations = result;
      });
    }
  }

  Future saveContent() async {
    if (selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectALocation ??
                'Please select at least one location',
          ),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
        ServiceModel service = ServiceModel(
          name: nameController.text.trim(),
          name_ar: nameArController.text.trim(),
          description: descriptionController.text.trim(),
          description_ar: descriptionArController.text.trim(),
          price: double.tryParse(priceController.text.trim()),
          category: selectedCategory?.id,
          locations: selectedLocations.isNotEmpty
              ? selectedLocations.map((location) => location.id).toList()
              : [],
          isActive: isActive,
          updatedAt: Timestamp.now(),
        );
        if (widget.service != null) {
          service = service.copyWith(
            id: widget.service!.id,
            locations: selectedLocations.isNotEmpty
                ? selectedLocations.map((location) => location.id).toList()
                : [],
          );
        } else {
          service.createdAt = Timestamp.now();
        }

        String? imageUrl;

        if (selectedImage != null) {
          // upload image and get the url
          final ref = AppFireStorage.servicesStorageRef.child(
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
          final uploadTask = ref.putFile(File(selectedImage!.path));
          uploadTask.snapshotEvents.listen((event) {
            setState(() {
              imageUploadProgress =
                  event.bytesTransferred.toDouble() /
                  event.totalBytes.toDouble();
            });
          });

          await uploadTask;
          imageUrl = await ref.getDownloadURL();
        }

        if (imageUrl != null) {
          service = service.copyWith(image: imageUrl);
        }

        if (widget.service == null) {
          await AppFirestore.servicesCollectionRef.add(service.toJson());
        } else {
          await AppFirestore.servicesCollectionRef
              .doc(widget.service!.id)
              .update(service.toEditJson(previous: widget.service!));
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.service == null
                    ? AppLocalizations.of(context)!.serviceAddedSuccessfully
                    : AppLocalizations.of(context)!.serviceUpdatedSuccessfully,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.failedToSaveService ??
                    'Failed to save service',
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.retry ?? 'Retry',
                onPressed: saveContent,
              ),
            ),
          );
        }
      }
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final isArabic = AppLocalizations.of(context)?.localeName == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == null
              ? AppLocalizations.of(context)!.addService
              : AppLocalizations.of(context)!.editService,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveContent),
        ],
      ),
      body: SavingStackWidget(
        isSaving: isSaving,
        isLoading: contentLoading,
        progress: imageUploadProgress,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: safePadding.bottom,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.name ?? 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.pleaseEnterAName;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: nameArController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.nameArabic ??
                        'Name (Arabic)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterNameInArabic;
                    } else if (!arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.textMustBeInArabic;
                    }

                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.description ??
                        'Description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterADescription;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: descriptionArController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.descriptionArabic ??
                        'Description (Arabic)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterDescriptionInArabic;
                    } else if (!arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.textMustBeInArabic;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.price ?? 'Price',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value == '') {
                      return AppLocalizations.of(context)?.pleaseEnterAPrice;
                    }
                    return null;
                  },
                ),
              ),

              // Location Selector Field
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _showLocationSelector,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)?.selectLocations ??
                              'Select Locations',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.location_on),
                        ),
                        child: Text(
                          selectedLocations.isEmpty
                              ? AppLocalizations.of(
                                      context,
                                    )?.tapToSelectLocations ??
                                    'Tap to select locations'
                              : '${selectedLocations.length} ${selectedLocations.length == 1 ? (AppLocalizations.of(context)?.locationSelected ?? 'location selected') : (AppLocalizations.of(context)?.locationsSelected ?? 'locations selected')}',
                          style: TextStyle(
                            color: selectedLocations.isEmpty
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                    ),

                    // Display selected locations as chips
                    if (selectedLocations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: selectedLocations.map((location) {
                          final locationName = isArabic == true
                              ? (location.name_ar ?? location.name ?? '')
                              : (location.name ?? '');
                          return Chip(
                            label: Text(
                              locationName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.secondary,
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                            onDeleted: () {
                              setState(() {
                                selectedLocations.removeWhere(
                                  (selected) => selected.id == location.id,
                                );
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton(
                  onPressed: pickImage,
                  child: Text(
                    AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
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
                        ? Image.file(
                            File(selectedImage!.path),
                            height: 130,
                            width: 130,
                          )
                        : widget.service?.image != null
                        ? CachedNetworkImage(
                            imageUrl: widget.service?.image ?? "",
                            height: 130,
                            width: 130,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<CategoryModel>(
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem<CategoryModel>(
                      value: category,
                      child: Text(
                        AppLocalizations.of(context)?.localeName == 'ar'
                            ? category.name_ar ?? category.name ?? ''
                            : category.name ?? '',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCategory = value);
                  },
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.category ?? 'Category',
                  ),
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(
                        context,
                      )?.pleaseSelectACategory;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  title: Text(AppLocalizations.of(context)?.active ?? 'Active'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
