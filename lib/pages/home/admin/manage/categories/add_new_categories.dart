import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/removable_image.dart';
import 'package:aboglumbo_bbk_panel/helpers/regex.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to crop image')));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null
              ? AppLocalizations.of(context)!.addCategory
              : AppLocalizations.of(context)!.editCategory,
        ),
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
                  } else if (Regex.arabicFullRegex.hasMatch(value)) {
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
                    onChanged: (value) {
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
                onPressed: () => pickImage(),
                icon: const Icon(Icons.image),
                label: Text(
                  AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
                ),
              ),
            ),
            if ((selectedImage != null) ||
                (widget.category?.svg != null && !shouldRemoveExistingImage))
              RemovableImageWidget(
                key: ValueKey(
                  '${selectedImage?.path}_${shouldRemoveExistingImage}_${widget.category?.svg}',
                ),
                selectedImage: selectedImage,
                networkImageUrl: !shouldRemoveExistingImage
                    ? widget.category?.svg
                    : null,
                onRemove: _removeImage,
              ),
          ],
        ),
      ),
    );
  }
}
