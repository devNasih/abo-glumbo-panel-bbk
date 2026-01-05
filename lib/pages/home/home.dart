import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/technician_welcome_modal.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/account.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/warranty_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/admin_home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage_app.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/dashboard.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/worker_home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';

import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/styles/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class Home extends StatefulWidget {
  final String? byPassUid;
  final int? newIndex;
  final String? selectedFilter;
  final bool isNewRegistration;
  const Home({
    super.key,
    this.byPassUid,
    this.newIndex,
    this.selectedFilter,
    this.isNewRegistration = false,
  });

  static bool hasShownWelcomeModal = false;

  static void resetWelcomeModal() {
    hasShownWelcomeModal = false;
  }

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  String selectedBookingStatus = 'P';

  // Role switcher state: 'admin' or 'technician'
  String _currentRole = 'admin'; // Default to admin for users with admin access
  bool _isLoadingRole = true;

  @override
  void initState() {
    log('initState');
    log('newIndex: ${widget.newIndex}');
    currentIndex = widget.newIndex ?? 0;
    log('selectedfilter: ${widget.selectedFilter}');
    if (widget.selectedFilter != null) {
      selectedBookingStatus = widget.selectedFilter!;
    } else {
      selectedBookingStatus = 'P';
    }
    // Initialize notifications explicitly
    Future.delayed(Duration.zero, () async {
      await NotificationServices.initializeNotifications();
      await NotificationServices.setupFCMListeners();
      await NotificationServices.checkForInitialMessage();
    });
    _loadRolePreference(); // Load saved role preference
    if (widget.byPassUid != null && widget.byPassUid!.isNotEmpty) {
      _handleBypassLogin();
    } else {
      // ✅ ADDED: Load user data if not bypassing
      final uid = LocalStore.getUID();
      if (uid != null && uid.isNotEmpty) {
        context.read<LoginBloc>().add(LoadWorkerData(uid: uid));
      }
    }
    super.initState();
  }

  void _handleBypassLogin() {
    context.read<LoginBloc>().add(LoadWorkerData(uid: widget.byPassUid!));
  }

  // Load role preference from local storage
  Future<void> _loadRolePreference() async {
    final savedRole = await LocalStore.getRolePreference();
    setState(() {
      _currentRole = savedRole ?? 'admin';
      _isLoadingRole = false;
    });
  }

  // Save role preference to local storage
  Future<void> _saveRolePreference(String role) async {
    await LocalStore.setRolePreference(role);
  }

  // Toggle between admin and technician roles
  void _toggleRole() {
    setState(() {
      _currentRole = _currentRole == 'admin' ? 'technician' : 'admin';
      if (_currentRole == 'technician') {
        Home.hasShownWelcomeModal = false;
      }
      currentIndex = 0; // Reset to home page when switching roles
    });
    _saveRolePreference(_currentRole);

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _currentRole == 'admin'
                  ? Icons.admin_panel_settings_rounded
                  : Icons.engineering_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              'Switched to ${_currentRole == 'admin' ? 'Admin' : 'Technician'} Mode',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _currentRole == 'admin'
            ? Colors.blue.shade600
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        if (state is LoginLoadWorkerDataFailure) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (currentIndex == 0) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    actionsAlignment: MainAxisAlignment.start,
                    title: Text(locale?.exitAppTitle ?? 'Exit App'),
                    content: Text(
                      locale?.exitAppMessage ??
                          'Are you sure you want to exit the app?',
                    ),
                    actions: [
                      eButton(
                        onPressed: () => Navigator.of(context).pop(),
                        text: locale?.cancel ?? 'Cancel',
                        context: context,
                        textColor: Colors.black,
                        backgroundColor: Colors.white,
                      ),
                      eButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        text: locale?.exit ?? 'Exit',
                        context: context,
                        textColor: Colors.white,
                        backgroundColor: AppColors.primary,
                      ),
                    ],
                  ),
                );
              } else {
                setState(() {
                  currentIndex = 0;
                });
              }
            },
            child: Scaffold(
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
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
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
            body: Center(child: Loader(color: AppColors.primary)),
          );
        }

        // Show welcome modal when:
        // 1. Availability is disabled (isOnline != true) - for both new registrations and subsequent logins
        // 2. Only applies to non-admin or level-1 granted admins in technician mode
        if ((userData.isAdmin != true ||
                (userData.isGrantedAdminByMain == true &&
                    userData.adminAccessLevel == 1 &&
                    _currentRole == 'technician')) &&
            userData.isOnline != true &&
            !Home.hasShownWelcomeModal) {
          Home.hasShownWelcomeModal = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            TechnicianWelcomeModal.show(
              context,
              onEnableAvailability: () {
                Navigator.of(context).pop();
                setState(() {
                  currentIndex = 0; // Navigate to dashboard
                });
              },
            );
          });
        }

        if (userData.isVerified != true) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (currentIndex == 0) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    actionsAlignment: MainAxisAlignment.start,
                    title: Text(locale?.exitAppTitle ?? 'Exit App'),
                    content: Text(
                      locale?.exitAppMessage ??
                          'Are you sure you want to exit the app?',
                    ),
                    actions: [
                      eButton(
                        onPressed: () => Navigator.of(context).pop(),
                        text: locale?.cancel ?? 'Cancel',
                        context: context,
                        textColor: Colors.black,
                        backgroundColor: Colors.white,
                      ),
                      eButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        text: locale?.exit ?? 'Exit',
                        context: context,
                        textColor: Colors.white,
                        backgroundColor: AppColors.primary,
                      ),
                    ],
                  ),
                );
              } else {
                setState(() {
                  currentIndex = 0;
                });
              }
            },
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (currentIndex == 0) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      actionsAlignment: MainAxisAlignment.start,
                      title: Text(locale?.exitAppTitle ?? 'Exit App'),
                      content: Text(
                        locale?.exitAppMessage ??
                            'Are you sure you want to exit the app?',
                      ),
                      actions: [
                        eButton(
                          onPressed: () => Navigator.of(context).pop(),
                          text: locale?.cancel ?? 'Cancel',
                          context: context,
                          textColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                        eButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          text: locale?.exit ?? 'Exit',
                          context: context,
                          textColor: Colors.white,
                          backgroundColor: AppColors.primary,
                        ),
                      ],
                    ),
                  );
                } else {
                  setState(() {
                    currentIndex = 0;
                  });
                }
              },
              child: Scaffold(
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
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
              ),
            ),
          );
        }
        // Determine which pages to show based on role switcher
        // Only users who were GRANTED admin access by main admin can switch roles
        // This excludes the main admin themselves and any default admin accounts
        final bool canSwitchRoles = userData.isGrantedAdminByMain == true;
        final roleSwitchCallback = canSwitchRoles ? _toggleRole : null;

        List<Widget> adminPages = [
          AdminHome(onToggleRole: roleSwitchCallback),
          ManageApp(userData: userData),
          WarrantyPage(
            workerData: userData,
            isTechnicianView: false,
            isInAdminMode: true,
          ),
          AccountPage(workerData: userData),
        ];
        List<Widget> workerPages = [
          DashboardScreen(
            workerData: userData,
            onToggleRole: roleSwitchCallback,
          ),
          WorkerHome(
            selectedIndex: selectedBookingStatus,
            isInAdminMode: canSwitchRoles && _currentRole == 'admin',
          ),
          WarrantyPage(
            workerData: userData,
            isTechnicianView: true,
            isInAdminMode: canSwitchRoles && _currentRole == 'admin',
          ),
          AccountPage(workerData: userData),
        ];

        // Determine current pages based on role switcher or default admin status
        final currentPages = canSwitchRoles
            ? (_currentRole == 'admin' ? adminPages : workerPages)
            : (userData.isAdmin == true ? adminPages : workerPages);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (currentIndex == 0) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  actionsAlignment: MainAxisAlignment.start,
                  title: Text(locale?.exitAppTitle ?? 'Exit App'),
                  content: Text(
                    locale?.exitAppMessage ??
                        'Are you sure you want to exit the app?',
                  ),
                  actions: [
                    eButton(
                      onPressed: () => Navigator.of(context).pop(),
                      text: locale?.cancel ?? 'Cancel',
                      context: context,
                      textColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                    eButton(
                      text: locale?.exit ?? 'Exit',
                      onPressed: () => Navigator.of(context).pop(true),
                      context: context,
                      textColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              );
            } else {
              setState(() {
                currentIndex = 0;
              });
            }
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: currentPages[currentIndex],
            ),
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
                // Show appropriate navigation based on current role
                if (canSwitchRoles && _currentRole == 'admin') ...{
                  NavigationDestination(
                    icon: Icon(Icons.settings_rounded, color: AppColors.grey),
                    selectedIcon: Icon(
                      Icons.settings_rounded,
                      color: AppColors.secondary,
                    ),
                    label: AppLocalizations.of(context)?.manage ?? 'Manage',
                  ),
                } else if (canSwitchRoles && _currentRole == 'technician') ...{
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.format_list_bulleted,
                      color: AppColors.secondary,
                    ),
                    icon: Icon(
                      Icons.format_list_bulleted,
                      color: AppColors.grey,
                    ),
                    label: AppLocalizations.of(context)?.orders ?? 'Orders',
                  ),
                } else if (!canSwitchRoles) ...{
                  // For users without admin access, always show Orders
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.format_list_bulleted,
                      color: AppColors.secondary,
                    ),
                    icon: Icon(
                      Icons.format_list_bulleted,
                      color: AppColors.grey,
                    ),
                    label: AppLocalizations.of(context)?.orders ?? 'Orders',
                  ),
                } else if (!canSwitchRoles && _currentRole != 'techncian') ...{
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.format_list_bulleted,
                      color: AppColors.secondary,
                    ),
                    icon: Icon(
                      Icons.format_list_bulleted,
                      color: AppColors.grey,
                    ),
                    label: AppLocalizations.of(context)?.manage ?? '',
                  ),
                },

                NavigationDestination(
                  icon: Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.grey,
                  ),
                  selectedIcon: Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.secondary,
                  ),
                  label: AppLocalizations.of(context)!.warrantyClaims,
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
          ),
        );
      },
    );
  }
}
