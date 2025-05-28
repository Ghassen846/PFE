import 'dart:convert';
import 'package:http/http.dart' as http;
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
      } else if (response is Map) {
        // If the response is a map but doesn't have 'users' key,
        // try to extract the user data from the response directly
        final users = <Map<String, dynamic>>[];
        response.forEach((key, value) {
          if (value is Map<String, dynamic> && value.containsKey('name')) {
            users.add(value);
          }
        });
        return users;
      }

      return [];
    } catch (e) {
      developer.log('Exception fetching chat users: $e', name: 'ChatService');
      return [];
    }
  }
}
