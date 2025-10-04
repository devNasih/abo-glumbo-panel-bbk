part of 'manage_app_bloc.dart';

sealed class ManageAppState extends Equatable {
  const ManageAppState();

  @override
  List<Object> get props => [];
}

final class ManageAppInitial extends ManageAppState {}

final class ClearingWallet extends ManageAppState {}

final class WalletCleared extends ManageAppState {}

final class WalletClearError extends ManageAppState {
  final String error;
  const WalletClearError(this.error);
  @override
  List<Object> get props => [error];
}

final class ApprovingAgent extends ManageAppState {}

final class AgentApproved extends ManageAppState {
  final bool isApproved;
  const AgentApproved(this.isApproved);
  @override
  List<Object> get props => [isApproved];
}

final class AgentApprovalError extends ManageAppState {
  final String error;
  const AgentApprovalError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddingBanner extends ManageAppState {}

final class BannerAdded extends ManageAppState {
  final bool isAdded;
  const BannerAdded(this.isAdded);

  @override
  List<Object> get props => [isAdded];
}

final class BannerAddError extends ManageAppState {
  final String error;
  const BannerAddError(this.error);

  @override
  List<Object> get props => [error];
}

final class UpdatingBanner extends ManageAppState {}

final class BannerUpdated extends ManageAppState {
  final bool isUpdated;
  const BannerUpdated(this.isUpdated);
  @override
  List<Object> get props => [isUpdated];
}

final class BannerUpdateError extends ManageAppState {
  final String error;
  const BannerUpdateError(this.error);

  @override
  List<Object> get props => [error];
}

final class DeletingBanner extends ManageAppState {}

final class BannerDeleted extends ManageAppState {
  final bool isDeleted;
  const BannerDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class BannerDeleteError extends ManageAppState {
  final String error;
  const BannerDeleteError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddingCategory extends ManageAppState {}

final class CategoryAdded extends ManageAppState {
  final bool isAdded;
  const CategoryAdded(this.isAdded);

  @override
  List<Object> get props => [isAdded];
}

final class CategoryAddError extends ManageAppState {
  final String error;
  const CategoryAddError(this.error);

  @override
  List<Object> get props => [error];
}

final class UpdatingCategory extends ManageAppState {}

final class CategoryUpdated extends ManageAppState {
  final bool isUpdated;
  const CategoryUpdated(this.isUpdated);
  @override
  List<Object> get props => [isUpdated];
}

final class CategoryUpdateError extends ManageAppState {
  final String error;
  const CategoryUpdateError(this.error);

  @override
  List<Object> get props => [error];
}

final class AddFaq extends ManageAppState {}
final class AddingFaq extends ManageAppState {}

final class FaqAdded extends ManageAppState {
  final bool isAdded;
  const FaqAdded(this.isAdded);

  @override
  List<Object> get props => [isAdded];
}
final class FaqAddError extends ManageAppState {
  final String error;
  const FaqAddError(this.error);

  @override
  List<Object> get props => [error];
}
final class DeleteFaq extends ManageAppState {}
final class DeletingFaq extends ManageAppState {}

final class FaqDeleted extends ManageAppState {
  final bool isDeleted;
  const FaqDeleted(this.isDeleted);

  @override
  List<Object> get props => [isDeleted];
}

final class FaqDeleteError extends ManageAppState {
  final String error;
  const FaqDeleteError(this.error); 

  @override
  List<Object> get props => [error];
}
