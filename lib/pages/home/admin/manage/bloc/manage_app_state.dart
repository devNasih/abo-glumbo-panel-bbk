part of 'manage_app_bloc.dart';

sealed class ManageAppState extends Equatable {
  const ManageAppState();
  
  @override
  List<Object> get props => [];
}

final class ManageAppInitial extends ManageAppState {}
