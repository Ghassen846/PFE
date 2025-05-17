import 'server_config.dart';

class ApiConfig {
  // Base URL for API - uses the ServerConfig class
  static String get baseUrl => ServerConfig.IMAGE_SERVER_BASE;

  // Helper method to get the uploads directory
  static String uploadsUrl() {
    return '$baseUrl/uploads';
  }

  // Convert relative paths to absolute URLs
  static String getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // If it's already a full URL, return as-is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    // Handle paths that start with /uploads/
    else if (imagePath.startsWith('/uploads/')) {
      return '$baseUrl$imagePath';
    }
    // Handle paths that start with uploads/ without a leading slash
    else if (imagePath.startsWith('uploads/')) {
      return '$baseUrl/$imagePath';
    }
    // If it's just a filename, assume it's in uploads folder
    else {
      return '$baseUrl/uploads/$imagePath';
    }
  }

  // Check if a path is a relative path that needs to be converted
  static bool isRelativePath(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }
}
