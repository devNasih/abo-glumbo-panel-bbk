import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'manage_app_event.dart';
part 'manage_app_state.dart';

class ManageAppBloc extends Bloc<ManageAppEvent, ManageAppState> {
  ManageAppBloc() : super(ManageAppInitial()) {
    on<ManageAppEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
