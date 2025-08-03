import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/login_carousel.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/error_codes.dart' as local_auth_error;
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool rememberMe = false;
  bool isCheckUserEnableTwoStepVerification = false;
  String? customerLastUid;
  bool isUserLogout = false;

  @override
  void initState() {
    super.initState();
    customerLastUid = LocalStore.getUID();
    isCheckUserEnableTwoStepVerification = LocalStore.getBiometricAuthEnabled(
      customerLastUid ?? '',
    );
    isUserLogout = LocalStore.getLogoutStatus();
    if (LocalStore.getRememberMe()) {
      rememberMe = true;
      emailController.text = LocalStore.getRememberedEmail() ?? '';
      passwordController.text = LocalStore.getRememberedPassword() ?? '';
    } else {
      rememberMe = false;
      emailController.clear();
      passwordController.clear();
    }
    // if (kDebugMode) {
    // emailController.text = "adnanyousufpangat@gmail.com";
    // passwordController.text = "qwertyuiop";
    emailController.text = "admin@abogalambo.app";
    passwordController.text = "testPassword";
    // }
  }

  void _byPassUsingBioAuth(BuildContext context) async {
    final auth = LocalAuthentication();
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.biometricNotSupported ??
                  'Biometric authentication is not supported on this device.',
            ),
          ),
        );
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            AppLocalizations.of(context)?.pleaseAuthenticateToContinue ??
            'Please authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Home(byPassUid: customerLastUid),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.authenticationFailed ??
                  '❌ Authentication failed',
            ),
          ),
        );
      }
    } on PlatformException catch (exception) {
      String message = '';
      switch (exception.code) {
        case local_auth_error.notAvailable:
        case local_auth_error.passcodeNotSet:
        case local_auth_error.notEnrolled:
          message =
              AppLocalizations.of(context)?.biometricNotAvailable ??
              '❌ Biometric authentication is not available on this device.';
          break;
        case local_auth_error.lockedOut:
        case local_auth_error.permanentlyLockedOut:
          message =
              AppLocalizations.of(context)?.biometricTemporarilyLocked ??
              '🔒 Too many failed attempts. Biometric is temporarily locked.';
          break;
        default:
          if (exception.message?.toLowerCase().contains('canceled') == true) {
            return;
          }
          message =
              '❌ Biometric error: ${exception.message ?? 'Unknown error'}';
      }

      if (message.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.unexpectedErrorOccurred ??
                '❌ Unexpected error occurred',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: AppColors.primary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  // Text(
                  //   ref.watch(languageState).code.toUpperCase(),
                  //   style: GoogleFonts.dmSans(
                  //     color: Colors.white,
                  //     fontSize: 12,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
              (route) => false,
            );
          } else if (state is LoginFailure) {
            String errorMessage;
            switch (state.error) {
              case 'user-not-found':
                errorMessage = AppLocalizations.of(context)!.emailNotRegistered;
                break;
              case 'wrong-password':
                errorMessage = AppLocalizations.of(context)!.incorrectPassword;
                break;
              case 'invalid-email':
                errorMessage = AppLocalizations.of(context)!.invalidEmailFormat;
                break;
              case 'user-disabled':
                errorMessage = AppLocalizations.of(context)!.accountDisabled;
                break;
              case 'too-many-requests':
                errorMessage = AppLocalizations.of(context)!.tooManyRequests;
                break;
              case 'network-request-failed':
                errorMessage = AppLocalizations.of(context)!.networkError;
                break;
              case 'invalid-credential':
                errorMessage = AppLocalizations.of(context)!.invalidCredentials;
                break;
              default:
                errorMessage = AppLocalizations.of(context)!.loginError;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          if (state is LoginResetPasswordSuccess) {
            if (state.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.passwordResetEmailSent,
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.emailNotRegistered,
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else if (state is LoginResetPasswordFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
                top: safePadding.top + 30,
                bottom: safePadding.bottom + 16,
              ),
              children: [
                LoginCarouselWidget(),
                const SizedBox(height: 25),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterYourEmail;
                    }
                    // else if (!emailRegex.hasMatch(value)) {
                    //   return AppLocalizations.of(context)!.invalidEmailFormat;
                    // }

                    return null;
                  },
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterYourPassword;
                    }
                    if (value.length < 6) {
                      return AppLocalizations.of(
                        context,
                      )!.passwordMustBeAtleast6Characters;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: state is LoginRememberMeToggled
                              ? state.value
                              : rememberMe,
                          onChanged: (value) => context.read<LoginBloc>().add(
                            RememberMeToggled(
                              value ?? false,
                              email: emailController.text.trim().isNotEmpty
                                  ? emailController.text.trim()
                                  : null,
                              password:
                                  passwordController.text.trim().isNotEmpty
                                  ? passwordController.text.trim()
                                  : null,
                            ),
                          ),
                          activeColor: AppColors.secondary,
                          checkColor: Colors.white,
                        ),
                        Text(
                          AppLocalizations.of(context)!.rememberMe,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // if (isCheckUserEnableTwoStepVerification &&
                    //     customerLastUid != null) ...[

                    // ],
                    TextButton(
                      onPressed: () {
                        if (emailController.text.isNotEmpty) {
                          context.read<LoginBloc>().add(
                            ForrgotPasswordPressed(
                              email: emailController.text.trim(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.pleaseEnterYourEmail,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: state is LoginResetPasswordLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.forgotPassword,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),
                if (isCheckUserEnableTwoStepVerification &&
                    isUserLogout &&
                    customerLastUid != null)
                  GestureDetector(
                    onTap: () => _byPassUsingBioAuth(context),
                    child: Image.asset(
                      'assets/images/fingerPrint.png',
                      color: Colors.white,
                      width: 54,
                      height: 54,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Save remember me state before login
                          final currentRememberMe =
                              state is LoginRememberMeToggled
                              ? state.value
                              : rememberMe;

                          if (currentRememberMe) {
                            context.read<LoginBloc>().add(
                              RememberMeToggled(
                                true,
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              ),
                            );
                          }

                          context.read<LoginBloc>().add(
                            LoginButtonPressed(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: state is LoginLoading
                          ? Loader(size: 20, color: Colors.white)
                          : Text(
                              AppLocalizations.of(context)!.continueText,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(top: 10.0),
                //   child: SizedBox(
                //     width: double.maxFinite,
                //     height: 40,
                //     child:
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 50,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.register,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}
