import 'package:aboglumbo_bbk_panel/pages/home/admin/bloc/admin_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> providers = [
  BlocProvider<LoginBloc>(create: (context) => LoginBloc()),
  BlocProvider<ManageAppBloc>(create: (context) => ManageAppBloc()),
  BlocProvider<AdminBloc>(create: (context) => AdminBloc()),
];
