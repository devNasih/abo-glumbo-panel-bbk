import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> providers = [BlocProvider<LoginBloc>(create: (context) => LoginBloc())];
