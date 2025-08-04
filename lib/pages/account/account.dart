import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/danger_alerts.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/language.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/account/edit_profile.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/biometric_service.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountPage extends StatefulWidget {
  final UserModel? workerData;
  const AccountPage({super.key, this.workerData});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isBiometricEnabled = false;
  late UserModel? currentWorkerData;
  List<LanguageModel> languages = [
    LanguageModel(code: 'en', name: 'English'),
    LanguageModel(code: 'ar', name: 'عربي'),
  ];

  @override
  void initState() {
    super.initState();
    currentWorkerData = widget.workerData;
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final isEnabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = isEnabled;
      });
    }
  }

  Future _showLanguageDialog(bool isForNotification) async {
    final currentLanguage = isForNotification
        ? (currentWorkerData?.lanCode ?? 'en')
        : LocalStore.getUserlanguage();

    await showDialog<LanguageModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((language) {
              final isSelected = language.code == currentLanguage;
              return ListTile(
                title: Text(language.name),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  if (isForNotification) {
                    context.read<AccountBloc>().add(
                      UpdateWorkerNotificationLanguageEvent(
                        language.code.toLowerCase(),
                      ),
                    );
                  } else {
                    context.read<AccountBloc>().add(
                      ChangeLanguageEvent(language.code.toLowerCase()),
                    );
                  }

                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is UpdateWorkerNotificationLanguageSuccess) {
          if (currentWorkerData != null) {
            setState(() {
              currentWorkerData = currentWorkerData!.copyWith(
                lanCode: state.languageCode,
              );
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.notificationLanguageUpdated ??
                    'Notification language updated successfully',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 275,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 207,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 67,
                      child: ClipOval(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: currentWorkerData?.profileUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: currentWorkerData!.profileUrl!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                )
                              : Center(
                                  child: Text(
                                    currentWorkerData?.name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 60,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ).copyWith(top: 15),
              child: Column(
                children: [
                  Text(
                    currentWorkerData?.name ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentWorkerData?.email ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: const Color(0xff757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Version 1.0.7',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightGrey,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                if (currentWorkerData?.isAdmin != true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)?.account ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.lightGrey,
                      ),
                    ),
                  ),
                  if (currentWorkerData?.isAdmin != true)
                    ListTile(
                      onTap: () async {
                        final updatedUser = await Navigator.push<UserModel>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfile(workerData: currentWorkerData),
                          ),
                        );

                        if (updatedUser != null) {
                          setState(() {
                            currentWorkerData = updatedUser;
                          });
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context)?.profileManagement ?? '',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          color: AppColors.black1,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_sharp,
                        size: 15,
                      ),
                    ),
                ],
                ListTile(
                  onTap: () => _showLanguageDialog(false),
                  title: Text(
                    AppLocalizations.of(context)?.language ?? 'Language',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: AppColors.black1,
                    ),
                  ),

                  trailing: const Icon(Icons.language, size: 20),
                ),
                ListTile(
                  onTap: () => _showLanguageDialog(true),
                  title: Text(
                    AppLocalizations.of(context)?.notificationLanguage ??
                        'Language',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: AppColors.black1,
                    ),
                  ),
                  trailing: const Icon(Icons.language, size: 20),
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)?.bioMetricAuthentication ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: AppColors.black1,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 50,
                    height: 40,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Switch(
                        value: _isBiometricEnabled,
                        onChanged: _handleBiometricToggle,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  onTap: () => AccountActionDialogs.showLogoutConfirmation(
                    context,
                    onConfirm: () {
                      LocalStore.putlogoutStatus(true);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                  title: Text(
                    AppLocalizations.of(context)?.logout ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: AppColors.black1,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () =>
                      AccountActionDialogs.showDeleteAccountConfirmation(
                        context,
                        onConfirm: (password) =>
                            deleteAccount(context, password),
                      ),
                  title: Text(
                    AppLocalizations.of(context)?.deleteAccount ?? '',
                    style: GoogleFonts.dmSans(fontSize: 16, color: Colors.red),
                  ),
                  trailing: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate(context);
      if (authenticated && mounted) {
        setState(() => _isBiometricEnabled = true);
        BiometricService.setBiometricEnabled(true);
        log('Biometric authentication enabled');
      }
    } else {
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
      }
      BiometricService.setBiometricEnabled(false);
    }
  }

  Future<void> deleteAccount(BuildContext context, String userPassword) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: userPassword,
      );

      LocalStore.clearLogoutStatus();
      LocalStore.putRememberMe(false);
      LocalStore.clearRememberedCredentials();
      LocalStore.clearUID();

      await user.reauthenticateWithCredential(credential);

      await AppFirestore.usersCollectionRef.doc(user.uid).delete();

      await user.delete();

      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.accountDeleted ?? 'Account Deleted',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete account: ${e.toString()}")),
        );
      }
    }
  }
}
