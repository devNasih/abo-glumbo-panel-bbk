import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery with error handling and validation
  static Future<XFile?> pickImage({
    required BuildContext context,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int maxSizeInMB = 5,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image == null) return null;

      // Check if file exists
      final file = File(image.path);
      if (!await file.exists()) {
        _showError(
          context,
          'Selected file could not be found. Please try again.',
        );
        return null;
      }

      // Check file size
      final fileSize = await file.length();
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;

      if (fileSize > maxSizeInBytes) {
        _showError(
          context,
          'Image is too large. Please select an image smaller than ${maxSizeInMB}MB.',
        );
        return null;
      }

      debugPrint('Selected image size: $fileSize bytes');
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showError(context, 'Error selecting image: ${e.toString()}');
      return null;
    }
  }

  /// Crop image with error handling
  static Future<XFile?> cropImage({
    required BuildContext context,
    required String sourcePath,
    CropAspectRatio? aspectRatio,
    bool lockAspectRatio = false,
  }) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: lockAspectRatio,
            initAspectRatio: aspectRatio != null
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            aspectRatioLockEnabled: lockAspectRatio,
            resetAspectRatioEnabled: !lockAspectRatio,
          ),
        ],
      );

      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      _showError(context, 'Error cropping image: ${e.toString()}');
      return null;
    }
  }

  /// Pick and optionally crop image in one operation
  static Future<XFile?> pickAndCropImage({
    required BuildContext context,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int maxSizeInMB = 5,
    CropAspectRatio? aspectRatio,
    bool lockAspectRatio = false,
    bool autoCrop = true,
  }) async {
    final XFile? pickedImage = await pickImage(
      context: context,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxSizeInMB: maxSizeInMB,
    );

    if (pickedImage == null) return null;

    if (autoCrop) {
      final XFile? croppedImage = await cropImage(
        context: context,
        sourcePath: pickedImage.path,
        aspectRatio: aspectRatio,
        lockAspectRatio: lockAspectRatio,
      );

      return croppedImage ?? pickedImage; // Return original if crop failed
    }

    return pickedImage;
  }

  /// Show error message
  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Common image picker configurations
class ImagePickerConfigs {
  static const CropAspectRatio squareAspectRatio = CropAspectRatio(
    ratioX: 1,
    ratioY: 1,
  );
  static const CropAspectRatio bannerAspectRatio = CropAspectRatio(
    ratioX: 370,
    ratioY: 136,
  );
  static const CropAspectRatio profileAspectRatio = CropAspectRatio(
    ratioX: 1,
    ratioY: 1,
  );

  // Profile image config
  static Future<XFile?> pickProfileImage(BuildContext context) {
    return ImagePickerHelper.pickAndCropImage(
      context: context,
      maxWidth: 800.0,
      maxHeight: 800.0,
      aspectRatio: profileAspectRatio,
      lockAspectRatio: true,
    );
  }

  // Banner image config
  static Future<XFile?> pickBannerImage(BuildContext context) {
    return ImagePickerHelper.pickAndCropImage(
      context: context,
      maxWidth: 1920.0,
      maxHeight: 1080.0,
      aspectRatio: bannerAspectRatio,
      lockAspectRatio: true,
    );
  }

  // Service image config
  static Future<XFile?> pickServiceImage(BuildContext context) {
    return ImagePickerHelper.pickAndCropImage(
      context: context,
      maxWidth: 1200.0,
      maxHeight: 1200.0,
      aspectRatio: squareAspectRatio,
      lockAspectRatio: true,
    );
  }

  // Category image config
  static Future<XFile?> pickCategoryImage(BuildContext context) {
    return ImagePickerHelper.pickAndCropImage(
      context: context,
      maxWidth: 512.0,
      maxHeight: 512.0,
      aspectRatio: squareAspectRatio,
      lockAspectRatio: true,
    );
  }
}
