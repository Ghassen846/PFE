import 'dart:io';
import 'package:flutter/material.dart';
import 'api_config.dart';

class ImageService {
  // Process any image URL to handle various formats
  static String _processImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    // Already a full URL with http
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    // For paths like /uploads/... or uploads/...
    if (imageUrl.contains('/uploads/') || imageUrl.startsWith('uploads/')) {
      return ApiConfig.getFullImageUrl(imageUrl);
    }

    // For just filenames, assume they're in the uploads directory
    if (!imageUrl.startsWith('/')) {
      return ApiConfig.getFullImageUrl('/uploads/' + imageUrl);
    }

    // Use ApiConfig to get full URL for any other relative paths
    return ApiConfig.getFullImageUrl(imageUrl);
  }

  // Gets the full image URL with the server base
  static String getFullImageUrl(String imagePath) {
    return _processImageUrl(imagePath);
  }

  static Widget buildAvatar({
    required String imageUrl,
    required double radius,
    required String category,
    bool isLocalFile = false,
  }) {
    Widget avatar;

    // Process the image URL if it's not a local file
    final processedUrl = isLocalFile ? imageUrl : _processImageUrl(imageUrl);

    if (processedUrl.isEmpty) {
      // Default avatar if no image is provided
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          category == 'user' ? Icons.person : Icons.image,
          size: radius,
          color: Colors.grey.shade600,
        ),
      );
    } else if (isLocalFile && File(imageUrl).existsSync()) {
      // Handle local file
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(imageUrl)),
        backgroundColor: Colors.grey.shade300,
      );
    } else if (processedUrl.startsWith('http')) {
      // Handle remote URL
      print('Loading network image: $processedUrl');
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(processedUrl),
        backgroundColor: Colors.grey.shade300,
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading image: $processedUrl - $exception');
          // We can't update avatar here directly due to how CircleAvatar works
        },
      );
    } else {
      // Fallback for invalid or unsupported image
      print('Unsupported image format: $processedUrl');
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          category == 'user' ? Icons.person : Icons.image,
          size: radius,
          color: Colors.grey.shade600,
        ),
      );
    }

    return ClipOval(child: avatar);
  }

  // Helper function is already defined above
  // Removed duplicate getFullImageUrl method
}
