// Helper method to determine file type
String getFileType(String url) {
  String extension = url.split('.').last.toLowerCase();
  if (['jpg', 'jpeg', 'png'].contains(extension)) {
    return 'image';
  } else if (extension == 'pdf') {
    return 'pdf';
  } else if (['doc', 'docx'].contains(extension)) {
    return 'document';
  }
  return 'unknown';
}

// Helper to get file name from URL
String getFileNameFromUrl(String url) {
  try {
    Uri uri = Uri.parse(url);
    String path = uri.pathSegments.last;
    return Uri.decodeComponent(path.split('?').first);
  } catch (e) {
    return 'file';
  }
}
