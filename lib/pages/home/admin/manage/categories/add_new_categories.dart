import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/removable_image.dart';
import 'package:aboglumbo_bbk_panel/helpers/regex.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class AddNewCategories extends StatefulWidget {
  final CategoryModel? category;
  const AddNewCategories({super.key, this.category});

  @override
  State<AddNewCategories> createState() => _AddNewCategoriesState();
}

class _AddNewCategoriesState extends State<AddNewCategories> {
  final _formKey = GlobalKey<FormState>();
  bool isActive = false;
  bool shouldRemoveExistingImage = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  XFile? selectedImage;
  @override
  void initState() {
    _fillOutFields();
    super.initState();
  }

  void _fillOutFields() {
    if (widget.category != null) {
      nameController.text = widget.category!.name ?? '';
      nameArController.text = widget.category!.name_ar ?? '';
      isActive = widget.category!.isActive ?? false;
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImage = image;
          shouldRemoveExistingImage = false;
        });
        await cropImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.imageLoadError ??
                  'Error picking image',
            ),
          ),
        );
      }
    }
  }

  Future cropImage() async {
    try {
      CroppedFile? res = await ImageCropper().cropImage(
        sourcePath: selectedImage!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
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
        setState(() {
          selectedImage = XFile(res.path);
          shouldRemoveExistingImage = false; // Ensure this is reset
        });
      } else {
        final bool? shouldKeepImage = await showCropConfirmDialog(context);

        if (shouldKeepImage != true) {
          setState(() {
            selectedImage = null;
            shouldRemoveExistingImage = false; // Reset this too
          });
        }
        // If shouldKeepImage is true, we keep the original selectedImage as is
        // and ensure shouldRemoveExistingImage is false
        else {
          setState(() {
            shouldRemoveExistingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.imageCropError ??
                  'Error cropping image',
            ),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      if (selectedImage != null) {
        selectedImage = null;
      } else if (widget.category?.svg != null) {
        shouldRemoveExistingImage = true;
      }
    });
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = CategoryModel(
        id: widget.category?.id,
        name: nameController.text.trim(),
        name_ar: nameArController.text.trim(),
        isActive: isActive,
        icon: widget.category?.icon,
        svg: widget.category?.svg,
      );

      if (widget.category == null) {
        // Adding new category
        context.read<ManageAppBloc>().add(
          AddCategoryEvent(category, imageFile: selectedImage),
        );
      } else {
        // Updating existing category
        context.read<ManageAppBloc>().add(
          UpdateCategoryEvent(category, imageFile: selectedImage),
        );
      }
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
    final safePadding = MediaQuery.of(context).padding;
    return BlocConsumer<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is CategoryAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.categoryAddedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is CategoryUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.categoryUpdatedSuccessfully ??
                    'Category updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is CategoryAddError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.errorAddingCategory ?? 'Error adding category'}: ${state.error}',
              ),
            ),
          );
        } else if (state is CategoryUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.errorUpdatingCategory ?? 'Error updating category'}: ${state.error}',
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AddingCategory || state is UpdatingCategory;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.category == null
                  ? AppLocalizations.of(context)!.addCategory
                  : AppLocalizations.of(context)!.editCategory,
            ),
            actions: [
              if (!isLoading)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveCategory,
                ),
              if (isLoading) Loader(color: Colors.white, size: 20),
            ],
          ),
          body: Form(
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
                    enabled: !isLoading,
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
                    enabled: !isLoading,
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
                      } else if (!Regex.arabicFullRegex.hasMatch(value)) {
                        return AppLocalizations.of(context)!.textMustBeInArabic;
                      }

                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.active ?? 'Active',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  isActive = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : () => pickImage(),
                    icon: const Icon(Icons.image),
                    label: Text(
                      AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
                    ),
                  ),
                ),
                if ((selectedImage != null) ||
                    (widget.category?.svg != null &&
                        !shouldRemoveExistingImage))
                  RemovableImageWidget(
                    key: ValueKey(
                      '${selectedImage?.path}_${shouldRemoveExistingImage}_${widget.category?.svg}',
                    ),
                    selectedImage: selectedImage,
                    networkImageUrl: !shouldRemoveExistingImage
                        ? widget.category?.svg
                        : null,
                    onRemove: isLoading ? null : _removeImage,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
