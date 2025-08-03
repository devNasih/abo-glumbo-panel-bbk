import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/account.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/admin_home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/worker_home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
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
    _loadUserData();
    super.initState();
  }

  void _loadUserData() {
    final loginState = context.read<LoginBloc>().state;
    if (loginState is! LoginSuccess && loginState is! LoginLoadWorkerData) {
      context.read<LoginBloc>().add(LoadWorkerData(uid: widget.byPassUid));
    }
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
                  Text('Error: ${state.error}'),
                  ElevatedButton(
                    onPressed: _loadUserData,
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
          userData = UserModel();
        }
        List<Widget> adminPages = [
          const AdminHome(),
          // const ManagePage(),
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
          appBar: AppBar(
            titleSpacing: 16,
            title: Text(
              AppLocalizations.of(context)?.manageOrders ?? "Manage Orders",
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // context.push('/notifications');
                },
              ),
            ],
          ),
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
