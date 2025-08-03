import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/multiple_location_selector.dart'
    as LocationSelectorHelper;
import 'package:aboglumbo_bbk_panel/common_widget/removable_image.dart';
import 'package:aboglumbo_bbk_panel/helpers/regex.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class EditServices extends StatefulWidget {
  final ServiceModel? service;
  const EditServices({super.key, this.service});

  @override
  State<EditServices> createState() => _EditServicesState();
}

class _EditServicesState extends State<EditServices> {
  final _formKey = GlobalKey<FormState>();
  bool isActive = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  XFile? selectedImage;
  CategoryModel? selectedCategory;
  List<LocationModel> locations = [];
  List<LocationModel> selectedLocations = [];
  List<CategoryModel> categories = [];

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
        IOSUiSettings(
          title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
          cancelButtonTitle: AppLocalizations.of(context)?.cancel ?? 'Cancel',
          doneButtonTitle: AppLocalizations.of(context)?.done ?? 'Done',
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

  @override
  void initState() {
    super.initState();
    _loadDistrict();
    _loadCategories();
  }

  void _fillOutFields() {
    if (widget.service != null) {
      nameController.text = widget.service!.name ?? '';
      nameArController.text = widget.service!.name_ar ?? '';
      descriptionController.text = widget.service!.description ?? '';
      descriptionArController.text = widget.service!.description_ar ?? '';
      priceController.text = widget.service!.price.toString();
      isActive = widget.service!.isActive;

      // Find and set selected category
      if (widget.service!.category != null && categories.isNotEmpty) {
        try {
          selectedCategory = categories.firstWhere(
            (element) => element.id == widget.service!.category,
          );
        } catch (e) {
          debugPrint('Category not found: $e');
          selectedCategory = null;
        }
      }

      // Set selected locations - only filter if locations are loaded
      if (locations.isNotEmpty && widget.service!.locations.isNotEmpty) {
        selectedLocations = locations.where((location) {
          return widget.service!.locations.contains(location.id);
        }).toList();
      } else {
        selectedLocations = [];
      }
    }
  }

  void _loadDistrict() {
    context.read<AccountBloc>().add(LoadDistrictsEvent());
  }

  void _loadCategories() async {
    // Load categories from stream
    AppServices.getAllCategoriesStream().listen((categoriesList) {
      if (mounted) {
        setState(() {
          categories = categoriesList;
          _fillOutFields(); // Re-fill fields when categories are loaded
        });
      }
    });
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement service save functionality
      // This would typically involve calling an API or service method
      // to save the service data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.service == null
                ? 'Service saved successfully' // Could be localized
                : 'Service updated successfully', // Could be localized
          ),
        ),
      );

      // Optionally navigate back
      Navigator.of(context).pop();
    }
  }

  Future<void> _showLocationSelector() async {
    // Create a copy of currently selected locations to avoid reference issues
    final currentSelectedLocations = selectedLocations
        .map(
          (location) => LocationModel(
            id: location.id,
            name: location.name,
            name_ar: location.name_ar,
            lat: location.lat,
            lon: location.lon,
          ),
        )
        .toList();

    final result = await LocationSelectorHelper.showMultipleLocationSelector(
      context: context,
      locations: locations,
      selectedLocations: currentSelectedLocations,
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

  @override
  void dispose() {
    nameController.dispose();
    nameArController.dispose();
    descriptionController.dispose();
    descriptionArController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)?.localeName == 'ar';
    return BlocConsumer<AccountBloc, AccountState>(
      listener: (context, state) {
        // Handle state changes
      },
      builder: (context, state) {
        if (state is LoadDistrictsSuccess) {
          locations = state.districts;
          // Re-fill fields when locations are loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fillOutFields();
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.service == null
                  ? AppLocalizations.of(context)!.addService
                  : AppLocalizations.of(context)!.editService,
            ),
            actions: [
              IconButton(icon: const Icon(Icons.save), onPressed: _saveService),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)?.active ?? 'Active',
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ),
                TextFormField(
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
                TextFormField(
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
                      )?.pleaseEnterNameInArabic;
                    } else if (!Regex.arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.textMustBeInArabic;
                    }
                    return null;
                  },
                ),
                TextFormField(
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
                      )?.pleaseEnterADescription;
                    }
                    return null;
                  },
                ),
                TextFormField(
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
                      )?.pleaseEnterDescriptionInArabic;
                    } else if (!Regex.arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.textMustBeInArabic;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.price ?? 'Price',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.pleaseEnterAPrice;
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<CategoryModel>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.category ?? 'Category',
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(
                    AppLocalizations.of(context)?.pleaseSelectACategory ??
                        'Please select a category',
                  ),
                  items: categories.map((CategoryModel category) {
                    final isArabic =
                        AppLocalizations.of(context)?.localeName == 'ar';
                    final categoryName = isArabic
                        ? (category.name_ar ?? category.name ?? '')
                        : (category.name ?? '');
                    return DropdownMenuItem<CategoryModel>(
                      value: category,
                      child: Text(categoryName),
                    );
                  }).toList(),
                  onChanged: (CategoryModel? newValue) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(
                        context,
                      )?.pleaseSelectACategory;
                    }
                    return null;
                  },
                ),
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

                // LocationSelectorWidget<LocationModel>(
                //   selectedLocations: selectedLocations,
                //   onLocationTap: _showLocationSelector,
                //   onLocationRemove: (location) {
                //     setState(() {
                //       selectedLocations.removeWhere(
                //         (selected) => selected.id == location.id,
                //       );
                //     });
                //   },
                //   getLocationName: (location) => isArabic == true
                //       ? (location.name_ar ?? location.name ?? '')
                //       : (location.name ?? ''),
                //   labelText:
                //       AppLocalizations.of(context)?.selectLocations ??
                //       'Select Locations',
                //   hintText:
                //       AppLocalizations.of(context)?.tapToSelectLocations ??
                //       'Tap to select locations',
                //   locationSelectedText:
                //       AppLocalizations.of(context)?.locationSelected ??
                //       'location selected',
                //   locationsSelectedText:
                //       AppLocalizations.of(context)?.locationsSelected ??
                //       'locations selected',
                //   chipBackgroundColor: AppColors.secondary,
                // ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton(
                    onPressed: pickImage,
                    child: Text(
                      AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
                    ),
                  ),
                ),
                RemovableImageWidget(
                  selectedImage: selectedImage,
                  networkImageUrl: widget.service?.image,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
