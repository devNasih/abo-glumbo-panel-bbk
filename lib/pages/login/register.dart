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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  bool otpSent = false;
  String? verificationId;
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        // ✅ FIXED: Correct flow order
        if (state is RegisterSuccess) {
          if (state.isSuccess) {
            // Phone available, NOW send OTP
            context.read<LoginBloc>().add(
              SendOTPPressed(
                context: context,
                phoneNumber: phoneController.text.trim(),
              ),
            );
          } else {
            // Phone already registered
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.phoneAlreadyRegistered ??
                      'Phone number already registered as technician',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (state is OTPSentSuccess) {
          setState(() {
            otpSent = true;
            verificationId = state.verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.otpSentSuccessfully ??
                    'OTP sent to ${phoneController.text}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is OTPVerifiedForRegistration) {
          // OTP verified, navigate to signup with UID
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Signup(uid: state.uid)),
          );
        } else if (state is OTPSentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );

          // Reset OTP state on failure
          setState(() {
            otpSent = false;
            verificationId = null;
            otpController.clear();
          });
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
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                              context,
                            )?.registerAsTechinicianInfo ??
                            'Register your phone number to create a technician account',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Phone Number Field
              TextFormWidget(
                controller: phoneController,
                label:
                    AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !otpSent,
                hintText: '+966 5XX XXX XXX',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                          context,
                        )?.pleaseEnterPhoneNumber ??
                        'Please enter your phone number';
                  }
                  if (!value.startsWith('+')) {
                    return AppLocalizations.of(
                          context,
                        )?.phoneNumberMustIncludeCountryCode ??
                        'Phone must start with + and country code';
                  }
                  if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
                    return AppLocalizations.of(
                          context,
                        )?.invalidPhoneNumberLength ??
                        'Phone number is too short';
                  }
                  return null;
                },
              ),

              // OTP Field (shown after OTP is sent)
              if (otpSent) ...[
                const SizedBox(height: 16),
                TextFormWidget(
                  controller: otpController,
                  label: AppLocalizations.of(context)?.otpCode ?? 'OTP Code',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.pleaseEnterOTP ??
                          'Please enter OTP';
                    }
                    if (value.length != 6) {
                      return AppLocalizations.of(context)?.otpMustBe6Digits ??
                          'OTP must be 6 digits';
                    }
                    return null;
                  },
                ),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.didNotReceiveOTP ??
                          "Didn't receive code?",
                      style: GoogleFonts.dmSans(fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          otpSent = false;
                          verificationId = null;
                          otpController.clear();
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context)?.resendOTP ?? 'Resend',
                        style: GoogleFonts.dmSans(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 50,
                  child: BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed:
                            state is RegistrationLoading ||
                                state is LoginLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() != true) {
                                  return;
                                }

                                // ✅ FIXED: Correct flow order
                                if (!otpSent) {
                                  // Step 1: Check if phone is available
                                  context.read<LoginBloc>().add(
                                    RegisterButtonPressed(
                                      phoneNumber: phoneController.text.trim(),
                                    ),
                                  );
                                } else {
                                  // Step 2: Verify OTP
                                  context.read<LoginBloc>().add(
                                    VerifyOTPForRegistration(
                                      verificationId: verificationId!,
                                      smsCode: otpController.text.trim(),
                                      phoneNumber: phoneController.text.trim(),
                                      context: context,
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
                        child:
                            state is RegistrationLoading ||
                                state is LoginLoading
                            ? Loader(size: 20, color: Colors.white)
                            : Text(
                                otpSent
                                    ? (AppLocalizations.of(
                                            context,
                                          )?.continueText ??
                                          'Continue')
                                    : (AppLocalizations.of(context)?.sendOTP ??
                                          'Send OTP'),
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
