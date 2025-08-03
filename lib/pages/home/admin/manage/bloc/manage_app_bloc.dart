import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

part 'manage_app_event.dart';
part 'manage_app_state.dart';

class ManageAppBloc extends Bloc<ManageAppEvent, ManageAppState> {
  ManageAppBloc() : super(ManageAppInitial()) {
    on<ClearTipWalletEvent>(_clearTipWallet);
    on<ApproveRejectAgentEvent>(_approveRejectAgent);
    on<AddBannerEvent>(_addBanner);
    on<UpdateBannerEvent>(_updateBanner);
    on<DeleteBannerEvent>(_deleteBanner);
    // Categories
    on<AddCategoryEvent>(_addCategory);
    on<UpdateCategoryEvent>(_updateCategory);
  }

  Future<void> _clearTipWallet(
    ClearTipWalletEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(ClearingWallet());
    try {
      await AppServices.clearTippingAmount(event.agentId);
      emit(WalletCleared());
    } catch (e) {
      emit(WalletClearError(e.toString()));
    }
  }

  Future<void> _approveRejectAgent(
    ApproveRejectAgentEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(ApprovingAgent());
    try {
      await AppServices.approveOrRejectAgent(event.agentId, event.isApproved);
      emit(AgentApproved(event.isApproved));
    } catch (e) {
      emit(AgentApprovalError(e.toString()));
    }
  }

  Future<void> _addBanner(
    AddBannerEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(AddingBanner());
    try {
      String? bannerImage;
      if (event.imageFile != null) {
        final ref = AppFireStorage.bannersStorageRef.child(
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        final uploadTask = ref.putFile(File(event.imageFile!.path));
        await uploadTask;
        bannerImage = await ref.getDownloadURL();
      }
      final String bannerId = AppFirestore.bannersCollectionRef.doc().id;
      final banner = BannerModel(
        id: bannerId,
        url: event.banner.url,
        image: bannerImage,
        label: event.banner.label,
        active: event.banner.active,
        section: event.banner.section,
      );
      await AppServices.addBanner(banner, bannerId);
      emit(BannerAdded(true));
    } catch (e) {
      emit(BannerAddError(e.toString()));
    }
  }

  Future<void> _updateBanner(
    UpdateBannerEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(UpdatingBanner());
    try {
      String? bannerImage =
          event.banner.image; // Keep existing image by default

      // If a new image file is provided, upload it
      if (event.imageFile != null) {
        final ref = AppFireStorage.bannersStorageRef.child(
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        final uploadTask = ref.putFile(File(event.imageFile!.path));
        await uploadTask;
        bannerImage = await ref.getDownloadURL();
      }

      final updatedBanner = BannerModel(
        id: event.banner.id,
        url: event.banner.url,
        image: bannerImage,
        label: event.banner.label,
        active: event.banner.active,
        section: event.banner.section,
      );

      await AppServices.updateBanner(updatedBanner);
      emit(BannerUpdated(true));
    } catch (e) {
      emit(BannerUpdateError(e.toString()));
    }
  }

  Future<void> _deleteBanner(
    DeleteBannerEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(DeletingBanner());
    try {
      await AppServices.deleteBanner(event.bannerId);
      emit(BannerDeleted(true));
    } catch (e) {
      emit(BannerDeleteError(e.toString()));
    }
  }

  Future<void> _addCategory(
    AddCategoryEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(AddingCategory());
    try {
      String? categoryImage;
      if (event.imageFile != null) {
        final ref = AppFireStorage.categoryStorageRef.child(
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        final uploadTask = ref.putFile(File(event.imageFile!.path));
        await uploadTask;
        categoryImage = await ref.getDownloadURL();
      }
      final String categoryId = AppFirestore.categoriesCollectionRef.doc().id;
      final category = CategoryModel(
        id: categoryId,
        name: event.category.name,
        name_ar: event.category.name_ar,
        svg: categoryImage,
        isActive: event.category.isActive,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await AppFirestore.categoriesCollectionRef
          .doc(categoryId)
          .set(category.toJson());
      emit(CategoryAdded(true));
    } catch (e) {
      emit(CategoryAddError(e.toString()));
    }
  }

  Future<void> _updateCategory(
    UpdateCategoryEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(UpdatingCategory());
    try {
      String? categoryImage =
          event.category.icon; // Keep existing image by default

      // If a new image file is provided, upload it
      if (event.imageFile != null) {
        final ref = AppFireStorage.categoryStorageRef.child(
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        final uploadTask = ref.putFile(File(event.imageFile!.path));
        await uploadTask;
        categoryImage = await ref.getDownloadURL();
      }

      final updatedCategory = CategoryModel(
        id: event.category.id,
        name: event.category.name,
        name_ar: event.category.name_ar,
        svg: categoryImage,
        isActive: event.category.isActive,
        createdAt: event.category.createdAt,
        updatedAt: Timestamp.now(),
      );

      await AppFirestore.categoriesCollectionRef
          .doc(event.category.id)
          .update(updatedCategory.toJson());
      emit(CategoryUpdated(true));
    } catch (e) {
      emit(CategoryUpdateError(e.toString()));
    }
  }
}
