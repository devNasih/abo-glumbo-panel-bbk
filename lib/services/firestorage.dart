import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class UploadToFireStorage {
  Future<XFile?> compressImage(XFile file) async {
    try {
      final fileSize = await File(file.path).length();

      int quality = 85;
      int maxWidth = 1024;
      int maxHeight = 1024;

      if (fileSize > 5 * 1024 * 1024) {
        quality = 45;
        maxWidth = 800;
        maxHeight = 800;
      } else if (fileSize > 2 * 1024 * 1024) {
        quality = 55;
        maxWidth = 900;
        maxHeight = 900;
      } else if (fileSize > 1 * 1024 * 1024) {
        quality = 65;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedPath =
          '${file.path.substring(0, file.path.lastIndexOf('.'))}_compressed_$timestamp.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        compressedPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: true,
      );

      if (compressedFile != null) {
        final compressedSize = await File(compressedFile.path).length();
        final reductionPercent = ((1 - compressedSize / fileSize) * 100)
            .toStringAsFixed(1);
        if (compressedSize > 300 * 1024) {
          final ultraCompressedPath =
              '${file.path.substring(0, file.path.lastIndexOf('.'))}_ultra_$timestamp.jpg';
          final ultraCompressed = await FlutterImageCompress.compressAndGetFile(
            compressedFile.path,
            ultraCompressedPath,
            quality: 30,
            minWidth: 600,
            minHeight: 600,
            format: CompressFormat.jpeg,
            keepExif: false,
          );
          if (ultraCompressed != null) {
            final ultraSize = await File(ultraCompressed.path).length();
            return ultraCompressed;
          }
        }
        return compressedFile;
      }
      return file;
    } catch (e) {
      debugPrint('Compression error: $e');
      return file;
    }
  }

  Future<XFile?> compressToPng(XFile file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pngPath =
          '${file.path.substring(0, file.path.lastIndexOf('.'))}_fallback_$timestamp.png';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        pngPath,
        quality: 80,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.png,
        keepExif: false,
      );

      if (compressedFile != null) {
        final compressedSize = await File(compressedFile.path).length();
        debugPrint('PNG compressed file size: $compressedSize bytes');
        return compressedFile;
      }

      return file;
    } catch (e) {
      debugPrint('PNG compression error: $e');
      return file;
    }
  }

  Future<String?> uploadFile(XFile file, String storagePath) async {
    try {
      final compressedFile = await compressImage(file);
      final finalFile = compressedFile ?? file;
      final fileSize = await File(finalFile.path).length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception(
          'File is too large even after compression. Please select a smaller image or try a different image format.',
        );
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = (timestamp % 10000).toString();
      final fileName = 'img_${timestamp}_$randomSuffix.jpg';
      final ref = AppFireStorage.agentDocStorageRef
          .child(storagePath)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      final uploadTask = ref.putFile(File(finalFile.path), metadata);
      const timeoutDuration = Duration(minutes: 3);

      final snapshot = await uploadTask.timeout(timeoutDuration);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      try {
        if (compressedFile != null && compressedFile.path != file.path) {
          await File(compressedFile.path).delete();
        }
      } catch (e) {
        debugPrint('Error deleting temporary file: $e');
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'unknown':
          if (e.message?.contains('Message too long') == true) {
            errorMessage =
                'Image file is corrupted or in an unsupported format. Please try a different image.';
          } else {
            errorMessage =
                'Upload failed due to an unknown error. Please try again.';
          }
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection and try again.';
          break;
        case 'quota-exceeded':
          errorMessage = 'Storage quota exceeded. Please try again later.';
          break;
        case 'unauthorized':
          errorMessage =
              'You are not authorized to upload files. Please log in again.';
          break;
        case 'cancelled':
          errorMessage = 'Upload was cancelled.';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message ?? 'Unknown error'}';
      }

      throw Exception(errorMessage);
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Upload timed out. The image might be too large or your connection is slow. Please try a smaller image.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      throw Exception(
        'Unexpected error during upload. Please try again with a different image.',
      );
    }
  }
}
