class SanitizeNumberHelper {
  static String sanitizePhoneNumber(String input) {
    if (input.isEmpty) {
      return "";
    }
    if (input.startsWith("+966")) {
      String countryCode = "+966";
      String numberPart = input.substring(4);
      String sanitizedNumberPart = sanitizeNumberPart(numberPart);
      String result = countryCode + sanitizedNumberPart;
      return result;
    }
    String sanitizedNumberPart = sanitizeNumberPart(input);
    return sanitizedNumberPart;
  }

  static String sanitizeNumberPart(String input) {
    String result = input.replaceAll(RegExp(r'\s'), '');
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const asciiDigits = '0123456789';
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], asciiDigits[i]);
    }
    return result;
  }

  static String formatToE164(String phoneNumber) {
    String sanitized = phoneNumber;
    if (sanitized.startsWith('+966')) {
      return sanitized;
    }
    while (sanitized.startsWith('0')) {
      sanitized = sanitized.substring(1);
    }
    String e164Number = '+966$sanitized';
    return e164Number;
  }
}
