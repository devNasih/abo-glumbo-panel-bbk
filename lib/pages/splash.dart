import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasInitialized = false;
  bool _isUserLogout = false;

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _isUserLogout = LocalStore.getLogoutStatus();
      _initializeApp();
    }
  }

  void _initializeApp() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      if (LocalStore.getUID() != null && !_isUserLogout) {
        context.read<LoginBloc>().add(LoadWorkerData(uid: LocalStore.getUID()));
        final loginBloc = context.read<LoginBloc>();
        await for (final state in loginBloc.stream) {
          if (state is LoginSuccess || state is LoginLoadWorkerData) {
            // Data loaded successfully, navigate to home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
              (Route<dynamic> route) => false,
            );
            break;
          } else if (state is LoginLoadWorkerDataFailure) {
            // Failed to load data, go to login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
            break;
          }
        }
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SvgPicture.asset(
              // selectedLanguage.code == "ar"
              //     ? 'assets/svg/logo_wide_white_ar.svg'
              //     :
              'assets/svg/logo_wide_white_en.svg',
              height: 80,
            ),
          ),
          const SizedBox(height: 50),
          Loader(size: 38, color: Colors.white),
        ],
      ),
    );
  }
}
