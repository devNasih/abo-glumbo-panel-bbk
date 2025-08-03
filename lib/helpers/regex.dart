class Regex {
  static final arabicFullRegex = RegExp(r'''^[\u0600-\u06FF
       \u0750-\u077F
       \u08A0-\u08FF
       \uFB50-\uFDFF
       \uFE70-\uFEFF
       \u0660-\u0669
       \u06F0-\u06F9
       \u200C-\u200F
       \s\n\r\d
       \.\,\!\?\،\؛\؟\:\-\(\)\[\]\"\'\u061F]+$''', multiLine: true);
  static final urlRegex = RegExp(
    r'^(https?:\/\/)?'
    r'([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}'
    r'(\/[^\s]*)?$',
  );
}
