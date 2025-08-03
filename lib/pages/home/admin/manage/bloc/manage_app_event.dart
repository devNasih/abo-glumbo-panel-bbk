part of 'manage_app_bloc.dart';

sealed class ManageAppEvent extends Equatable {
  const ManageAppEvent();

  @override
  List<Object> get props => [];
}

class ClearTipWalletEvent extends ManageAppEvent {
  final String agentId;
  const ClearTipWalletEvent(this.agentId);

  @override
  List<Object> get props => [agentId];
}

class ApproveRejectAgentEvent extends ManageAppEvent {
  final String agentId;
  final bool isApproved;
  const ApproveRejectAgentEvent(this.agentId, this.isApproved);

  @override
  List<Object> get props => [agentId, isApproved];
}

// Banners
class AddBannerEvent extends ManageAppEvent {
  final BannerModel banner;
  final XFile? imageFile;
  const AddBannerEvent(this.banner, {this.imageFile});

  @override
  List<Object> get props => [banner, imageFile ?? ''];
}

class UpdateBannerEvent extends ManageAppEvent {
  final BannerModel banner;
  final XFile? imageFile;
  const UpdateBannerEvent(this.banner, {this.imageFile});

  @override
  List<Object> get props => [banner, imageFile ?? ''];
}

class DeleteBannerEvent extends ManageAppEvent {
  final String bannerId;
  const DeleteBannerEvent(this.bannerId);

  @override
  List<Object> get props => [bannerId];
}

// Categories
class AddCategoryEvent extends ManageAppEvent {
  final CategoryModel category;
  final XFile? imageFile;
  const AddCategoryEvent(this.category, {this.imageFile});

  @override
  List<Object> get props => [category, imageFile ?? ''];
}

class UpdateCategoryEvent extends ManageAppEvent {
  final CategoryModel category;
  final XFile? imageFile;
  const UpdateCategoryEvent(this.category, {this.imageFile});

  @override
  List<Object> get props => [category, imageFile ?? ''];
}
