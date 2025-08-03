
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TextFormWidget extends StatelessWidget {
  const TextFormWidget({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onTap,
    this.readOnly,
    this.obscureText = false,
    this.suffix,
    this.isPhoneNumber = false,
    this.maxLength,
  });
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String?>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final GestureTapCallback? onTap;
  final bool? readOnly;
  final bool obscureText;
  final Widget? suffix;
  final bool isPhoneNumber;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 16),
        ),
        const SizedBox(height: 5),
        TextFormField(
          obscureText: obscureText,
          inputFormatters: maxLength != null
              ? [LengthLimitingTextInputFormatter(maxLength)]
              : null,
          decoration: InputDecoration(
            suffixIcon: suffix,
            border: InputBorder.none,
            constraints: const BoxConstraints(minHeight: 62),
            fillColor: readOnly == true ? AppColors.black2 : null,
            filled: readOnly,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.secondary),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            counterText: isPhoneNumber ? '' : null,
          ),
          style: GoogleFonts.dmSans(fontSize: 16, color: Colors.black),
          controller: controller,
          keyboardType: isPhoneNumber ? TextInputType.number : keyboardType,
          textInputAction: textInputAction,
          validator: isPhoneNumber
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.phoneNumberRequired;
                  }
                  final saudiRegex = RegExp(r'^(?:\+966|00966|0)?5[0-9]{8}$');

                  if (!saudiRegex.hasMatch(value)) {
                    return AppLocalizations.of(context)!.phoneNumberInvalid;
                  }
                  return validator?.call(value);
                }
              : validator,
          onTap: onTap,
          readOnly: readOnly ?? onTap != null,
        )
      ],
    );
  }
}
