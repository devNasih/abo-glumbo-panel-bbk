import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/signup.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          if (state.isSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Signup(
                  email: emailController.text,
                  password: passwordController.text,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.registrationFailed ??
                      'Registration failed',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.register ?? 'Register'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: safePadding.bottom + 16,
            ),
            children: [
              TextFormWidget(
                controller: emailController,
                label: AppLocalizations.of(context)?.email ?? 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)?.pleaseEnterYourEmail ??
                        'Please enter your email';
                  }
                  final emailRegExp = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegExp.hasMatch(value)) {
                    return AppLocalizations.of(context)?.invalidEmailFormat ??
                        'Invalid email format';
                  }
                  return null;
                },
              ),
              TextFormWidget(
                controller: passwordController,
                label: AppLocalizations.of(context)?.password ?? 'Password',
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                obscureText: !isPasswordVisible,
                suffix: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.secondary,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                          context,
                        )?.pleaseEnterYourPassword ??
                        'Please enter your password';
                  } else if (value.length < 6) {
                    return AppLocalizations.of(
                          context,
                        )?.passwordMustBeAtleast6Characters ??
                        'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              TextFormWidget(
                controller: confirmPasswordController,
                label:
                    AppLocalizations.of(context)?.confirmPassword ??
                    'Confirm Password',
                keyboardType: TextInputType.visiblePassword,
                obscureText: !isConfirmPasswordVisible,
                suffix: IconButton(
                  icon: Icon(
                    isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.secondary,
                  ),
                  onPressed: () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                          context,
                        )?.pleaseConfirmYourPassword ??
                        'Please confirm your password';
                  } else if (value != passwordController.text) {
                    return AppLocalizations.of(context)?.passwordsDoNotMatch ??
                        'Passwords do not match';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 50,
                  child: BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is RegistrationLoading
                            ? () {}
                            : () {
                                if (_formKey.currentState?.validate() != true)
                                  return;
                                context.read<LoginBloc>().add(
                                  RegisterButtonPressed(
                                    email: emailController.text,
                                    password: passwordController.text,
                                    confirmPassword:
                                        confirmPasswordController.text,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: state is RegistrationLoading
                            ? Loader(size: 20, color: Colors.white)
                            : Text(
                                AppLocalizations.of(context)?.register ??
                                    'Register',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
