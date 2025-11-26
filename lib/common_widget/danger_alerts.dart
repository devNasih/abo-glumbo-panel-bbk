import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AccountActionDialogs {
  // Logout confirmation dialog
  static Future<void> showLogoutConfirmation(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          actionsAlignment: MainAxisAlignment.start,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.blue[600], size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.logout ?? 'Logout',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)?.logoutConfirmation ??
                'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          actions: [
            eButton(
              onPressed: () => Navigator.of(context).pop(),
              text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
              context: context,
              textColor: Colors.black,
              backgroundColor: Colors.white,
            ),
            eButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              text: AppLocalizations.of(context)?.logout ?? 'Logout',
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );
  }

  // Delete account confirmation dialog with password
  static Future<void> showDeleteAccountConfirmation(
    BuildContext context, {
    required Function(String password) onConfirm,
  }) {
    bool isPasswordVisible = false;
    final passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          key: UniqueKey(), // Add unique key to prevent conflicts
          builder: (context, setState) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.start,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.confirmDeletion ??
                          'Confirm Deletion',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.deleteAccountWarning ??
                            'This action will permanently delete your account and cannot be undone.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)?.password ??
                              'Password',
                          hintText:
                              AppLocalizations.of(
                                context,
                              )?.enterPasswordToConfirm ??
                              'Enter your password to confirm',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red[400]!),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              actions: [
                eButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Future.microtask(() => passwordController.clear());
                  },
                  text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  context: context,
                ),
                eButton(
                  onPressed: () {
                    final password = passwordController.text.trim();
                    if (password.isNotEmpty) {
                      final passwordValue = password;
                      Navigator.of(context).pop();
                      Future.microtask(() {
                        passwordController.clear();
                        onConfirm(passwordValue);
                      });
                    } else {
                      // Show error if password is empty
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                                  context,
                                )?.pleaseEnterYourPassword ??
                                'Please enter your password',
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },

                  text:
                      AppLocalizations.of(context)?.deleteAccount ??
                      'Delete Account',
                  backgroundColor: Colors.red[600],
                  textColor: Colors.white,
                  context: context,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
