import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app_new/models/chat_model/chat_user.dart';
import 'package:first_app_new/models/chat_model/chat_message.dart';

void main() {
  test('Chat models initialization test', () async {
    // Set up shared preferences mock
    SharedPreferences.setMockInitialValues({
      'user_id': 'test_user_id',
      'token': 'test_token',
      'username': 'testuser',
    });

    // Test creating a chat user
    final chatUser = ChatUser(
      id: 'test_recipient_id',
      name: 'Test User',
      role: 'admin',
      isOnline: true,
    );

    expect(chatUser.id, equals('test_recipient_id'));
    expect(chatUser.isOnline, isTrue); // Test creating a chat message
    final chatMessage = ChatMessage(
      id: '1',
      senderId: 'test_user_id',
      receiverId: 'test_recipient_id',
      content: 'Hello, this is a test message',
      timestamp: DateTime.now(),
      isRead: false,
      type: 'text',
    );

    expect(chatMessage.content, equals('Hello, this is a test message'));
    expect(chatMessage.isRead, isFalse);

    // Test MongoDB format parsing
    final mongoDbMessage = ChatMessage.fromJson({
      '_id': '682e924c002e6d0e6c0361c1',
      'sender': '6819f2d047146d3fb1e0dc9a',
      'receiver': '6815c24f788938e9b9c1a1ef',
      'message': 'MongoDB test message',
      'isRead': true,
      'createdAt': {'\$date': '2023-05-22T02:56:12.991Z'},
    });

    expect(mongoDbMessage.id, equals('682e924c002e6d0e6c0361c1'));
    expect(mongoDbMessage.senderId, equals('6819f2d047146d3fb1e0dc9a'));
    expect(mongoDbMessage.receiverId, equals('6815c24f788938e9b9c1a1ef'));
    expect(mongoDbMessage.content, equals('MongoDB test message'));
    expect(mongoDbMessage.isRead, isTrue);
  });
}
