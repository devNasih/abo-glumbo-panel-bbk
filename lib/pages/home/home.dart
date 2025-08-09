import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/account.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/admin_home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage_app.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/worker_home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/notification.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/styles/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class Home extends StatefulWidget {
  final String? byPassUid;
  const Home({super.key, this.byPassUid});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;

  @override
  void initState() {
    NotificationServices.initializeFCM();
    if (widget.byPassUid != null && widget.byPassUid!.isNotEmpty) {
      _handleBypassLogin();
    }
    super.initState();
  }

  void _handleBypassLogin() {
    context.read<LoginBloc>().add(LoadWorkerData(uid: widget.byPassUid!));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        if (state is LoginLoadWorkerDataFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${locale?.error}: ${state.error}'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        UserModel userData;
        if (state is LoginSuccess) {
          userData = state.user;
        } else if (state is LoginLoadWorkerData) {
          userData = state.user;
        } else {
          return Scaffold(
            body: Center(child: Loader(color: AppColors.black2)),
          );
        }
        if (userData.isVerified != true) {
          return Scaffold(
            appBar: AppBar(
              title: Text(locale?.account ?? ''),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 80,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(
                            context,
                          )?.pleaseWaitAccountVerification ??
                          'Please wait for account verification',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(
                            context,
                          )?.accountVerificationPending ??
                          'Your account is pending verification. You will be notified once it is approved.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(locale?.goToLogin ?? 'Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        List<Widget> adminPages = [
          AdminHome(),
          const ManageApp(),
          AccountPage(workerData: userData),
        ];

        List<Widget> workerPages = [
          WorkerHome(),
          AccountPage(workerData: userData),
        ];
        final currentPages = userData.isAdmin == true
            ? adminPages
            : workerPages;
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: currentPages[currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              if (index < currentPages.length) {
                setState(() => currentIndex = index);
              }
            },
            height: 70,
            destinations: [
              NavigationDestination(
                icon: SvgPicture.asset(
                  AppIcons.homeNav,
                  colorFilter: ColorFilter.mode(
                    AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  AppIcons.homeNav,
                  colorFilter: ColorFilter.mode(
                    AppColors.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                label: locale?.home ?? '',
              ),
              if (userData.isAdmin == true)
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded, color: AppColors.grey),
                  selectedIcon: Icon(
                    Icons.settings_rounded,
                    color: AppColors.secondary,
                  ),
                  label: AppLocalizations.of(context)?.manage ?? 'Manage',
                ),
              NavigationDestination(
                icon: SvgPicture.asset(
                  AppIcons.profileNav,
                  colorFilter: ColorFilter.mode(
                    AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  AppIcons.profileNav,
                  colorFilter: ColorFilter.mode(
                    AppColors.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                label: locale?.account ?? '',
              ),
            ],
          ),
        );
      },
    );
  }
}
