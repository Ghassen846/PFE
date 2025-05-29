// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:first_app_new/services/server_config.dart'; // Add ServerConfig import

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String type;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('Parsing message: $json', name: 'ChatMessage');

      final id = json['_id'] ?? json['id'] ?? '';
      final senderId = json['senderId'] ?? '';
      final receiverId = json['receiverId'] ?? '';
      final content = json['content'] ?? '';
      final imageUrl = json['imageUrl'];
      final isRead = json['isRead'] ?? false;
      final type = json['type'] ?? 'text';

      // Handle various timestamp formats
      DateTime timestamp;
      try {
        if (json['timestamp'] is String) {
          timestamp = DateTime.parse(json['timestamp']);
        } else if (json['timestamp'] is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
        } else if (json['createdAt'] is String) {
          timestamp = DateTime.parse(json['createdAt']);
        } else {
          timestamp = DateTime.now();
        }
      } catch (e) {
        developer.log('Error parsing timestamp: $e', name: 'ChatMessage');
        timestamp = DateTime.now();
      } // Create a clean URL for images
      String? cleanImageUrl = imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (!imageUrl.startsWith('http')) {
          cleanImageUrl = '${ServerConfig.IMAGE_SERVER_BASE}/uploads/$imageUrl';
          developer.log('Fixed image URL: $cleanImageUrl', name: 'ChatMessage');
        }
      }

      return ChatMessage(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        imageUrl: cleanImageUrl,
        timestamp: timestamp,
        isRead: isRead,
        type: type,
      );
    } catch (e) {
      developer.log('Error parsing message: $e', name: 'ChatMessage');
      // Return a fallback message for display
      return ChatMessage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'error',
        receiverId: 'error',
        content: 'Error loading message',
        timestamp: DateTime.now(),
        isRead: false,
        type: 'text',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'type': type,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    timestamp,
    isRead,
    imageUrl,
    type,
  ];
}

enum MessageType { text, image, location }
