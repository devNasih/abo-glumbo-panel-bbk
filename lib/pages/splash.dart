import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
