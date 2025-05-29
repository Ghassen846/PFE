import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Add this import for mime type detection
import 'package:first_app_new/services/api_service.dart';
import 'dart:developer' as developer;

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<Map<String, dynamic>> fetchOnlineStatus(List<String> userIds) async {
    try {
      final response = await ApiService.get(
        'chat/online-status',
        queryParams: {'userIds': jsonEncode(userIds)},
      );
      if (response.containsKey('error')) {
        developer.log(
          'Error fetching online status: ${response['error']}',
          name: 'ChatService',
        );
        return {};
      }
      return response;
    } catch (e) {
      developer.log(
        'Exception fetching online status: $e',
        name: 'ChatService',
      );
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchUnreadMessages(String userId) async {
    try {
      final response = await ApiService.get(
        'chat/unread',
        queryParams: {'userId': userId},
      );
      if (response.containsKey('error')) {
        developer.log(
          'Error fetching unread messages: ${response['error']}',
          name: 'ChatService',
        );
        return {'totalUnread': 0, 'unreadBySender': []};
      }
      return response;
    } catch (e) {
      developer.log(
        'Exception fetching unread messages: $e',
        name: 'ChatService',
      );
      return {'totalUnread': 0, 'unreadBySender': []};
    }
  }

  Future getChatUsers() async {
    try {
      final response = await ApiService.get('chat/users');
      if (response.containsKey('error')) {
        developer.log(
          'Error fetching chat users: ${response['error']}',
          name: 'ChatService',
        );
        return [];
      }

      // Handle different response formats
      if (response is List) {
        return response;
      } else if (response.containsKey('users') && response['users'] is List) {
        return response['users'];
      } else // If the response is a map but doesn't have 'users' key,
        // try to extract the user data from the response directly
        final users = <Map<String, dynamic>>[];
      response.forEach((key, value) {
        if (value is Map<String, dynamic> && value.containsKey('name')) {
          users.add(value);
        }
      });
      return users;

      return [];
    } catch (e) {
      developer.log('Exception fetching chat users: $e', name: 'ChatService');
      return [];
    }
  }

  // Improved image upload method with better mime type handling
  Future<String?> uploadChatImage(File imageFile) async {
    try {
      developer.log(
        'Uploading chat image: ${imageFile.path}',
        name: 'ChatService',
      );

      // Get the file name from the path
      final String fileName = imageFile.path.split('/').last;

      // Try to detect the mime type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      developer.log('Detected mime type: $mimeType', name: 'ChatService');

      // Upload the file using the new method signature
      final response = await ApiService.uploadFile2(
        // Use uploadFile2 instead
        'upload',
        imageFile.path,
        fieldName: 'image',
        fileName: fileName,
        mimeType: mimeType,
        queryParams: {'type': 'chat'},
      );

      if (response == null || response.containsKey('error')) {
        developer.log(
          'Error uploading image: ${response?['error'] ?? "Unknown error"}',
          name: 'ChatService',
        );
        return null;
      }

      developer.log(
        'Image uploaded successfully: ${response['imageUrl']}',
        name: 'ChatService',
      );
      return response['imageUrl'] as String?;
    } catch (e) {
      developer.log('Exception uploading chat image: $e', name: 'ChatService');
      return null;
    }
  }

  // Add method to send a message with an image
  Future<Map<String, dynamic>?> sendMessageWithImage(
    String senderId,
    String receiverId,
    String? content,
    String imageUrl,
  ) async {
    try {
      final Map<String, dynamic> messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'imageUrl': imageUrl,
      };

      // Add content if provided
      if (content != null && content.isNotEmpty) {
        messageData['content'] = content;
      }

      final response = await ApiService.post('chat/message', messageData);

      if (response.containsKey('error')) {
        developer.log(
          'Error sending message with image: ${response['error']}',
          name: 'ChatService',
        );
        return null;
      }

      return response;
    } catch (e) {
      developer.log(
        'Exception sending message with image: $e',
        name: 'ChatService',
      );
      return null;
    }
  }
}
