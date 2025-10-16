import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/custom_exception.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/customer_support.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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
    on<AddFaqEvent>(_addFaq);
    on<DeleteFaqEvent>(_deleteFaq);
    on<UpdateFaqEvent>(_updateFaq);
    on<CustomerBlockUnblockEvent>(_blockUnblockCustomer);
    on<AddCustomerServiceContactEvent>(_addCustomerServiceDetails);
    on<DeleteCustomerServiceContactEvent>(_deleteCustomerServiceDetails);
    on<UpdateCustomerServiceContactEvent>(_updateCustomerServiceDetails);
    on<SetPrimaryCustomerServiceContactEvent>(
      _setPrimaryCustomerServiceContact,
    );
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

  Future<void> _addFaq(AddFaqEvent event, Emitter<ManageAppState> emit) async {
    emit(AddingFaq());
    try {
      await AppServices.addFaq(event.faqEntry);
      emit(FaqAdded());
    } on DuplicateStandException catch (e) {
      emit(FaqAddError(e.message)); // emit error state with duplicate message
    } catch (e) {
      emit(FaqAddError(e.toString()));
    }
  }

  Future<void> _updateFaq(
    UpdateFaqEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(UpdatingFaq());
    try {
      await AppServices.updateFaq(event.faqEntry);
      emit(FaqUpdated(true));
    } catch (e) {
      emit(FaqUpdateError(e.toString()));
    }
  }

  Future<void> _deleteFaq(
    DeleteFaqEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(DeletingFaq());
    try {
      await AppServices.deleteFaq(event.faqId);
      emit(FaqDeleted(true));
    } catch (e) {
      emit(FaqDeleteError(e.toString()));
    }
  }

  Future<void> _blockUnblockCustomer(
    CustomerBlockUnblockEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(CustomerBlockUnblocking());
    try {
      await AppServices.blockUnblockCustomer(event.customerId, event.isBlocked);
      emit(BlockUnblockCustomer(event.isBlocked));
    } catch (e) {
      emit(BlockUnblockCustomerError(e.toString()));
    }
  }

  Future<void> _addCustomerServiceDetails(
    AddCustomerServiceContactEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(AddingCustomerSupport());
    try {
      await AppServices.addCustomerServiceDetails(event.contact);
      emit(CustomerSupportAdded(true));
    } catch (e) {
      emit(CustomerSupportAddError(e.toString()));
    }
  }

  Future<void> _updateCustomerServiceDetails(
    UpdateCustomerServiceContactEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(UpdatingCustomerSupport());
    try {
      await AppServices.updateCustomerService(event.contact);
      emit(CustomerSupportUpdated(true));
    } catch (e) {
      emit(CustomerSupportUpdateError(e.toString()));
    }
  }

  Future<void> _deleteCustomerServiceDetails(
    DeleteCustomerServiceContactEvent event,
    Emitter<ManageAppState> emit,
  ) async {
    emit(DeletingCustomerSupport());
    try {
     // Get the contact to delete
    final contact = await AppServices.getCustomerServiceById(event.contactId);
    
    if (contact == null) {
      emit(CustomerSupportDeleteError(AppLocalizations.of(event.context)!.contactNotFound));
      return;
    }
    
    // Get all contacts of the same type
    final allContacts = await AppServices.getCustomerServiceByType(
      contact.type,
    );
    
    // Prevent deletion if only one contact exists
    if (allContacts.length <= 1) {
      emit(CustomerSupportDeleteError(
        AppLocalizations.of(event.context)!.cannotDeleteLastContact(contact.type),
      ));
      return;
    }
    
    // If deleting primary contact, set another one as primary
    if (contact.isActive == true) {
      final newPrimary = allContacts.firstWhere((c) => c.id != event.contactId);
      await AppServices.updateCustomerService(
        CustomerSupportModel(
          id: newPrimary.id,
          name: newPrimary.name,
          detail: newPrimary.detail,
          type: newPrimary.type,
          isActive: true,
        ),
      );
    }
    
    await AppServices.deleteCustomerService(event.contactId);
    
      emit(CustomerSupportDeleted(true));
    } catch (e) {
      emit(CustomerSupportDeleteError(e.toString()));
    }
  }

  Future<void> _setPrimaryCustomerServiceContact(
    SetPrimaryCustomerServiceContactEvent
    event, // Changed from SettingPrimaryCustomerSupport
    Emitter<ManageAppState> emit,
  ) async {
    emit(SettingPrimaryCustomerSupport());

    try {
      // Use Firestore batch to update multiple documents atomically
      final batch = FirebaseFirestore.instance.batch();

      // Set all contacts of this type to isActive: false
      for (var contact in event.allContactsOfType) {
        if (contact.id != null) {
          final docRef = AppFirestore.customerServiceCollectionRef.doc(
            contact.id,
          );
          batch.update(docRef, {'isActive': false});
        }
      }

      // Set the selected contact to isActive: true
      if (event.selectedContact.id != null) {
        final selectedDocRef = AppFirestore.customerServiceCollectionRef.doc(
          event.selectedContact.id,
        );
        batch.update(selectedDocRef, {'isActive': true});
      }

      // Commit all updates atomically
      await batch.commit();

      emit(
        CustomerSupportUpdated(true),
      ); // Added true parameter to match your other emissions
    } catch (e) {
      emit(CustomerSupportUpdateError(e.toString()));
    }
  }
}
