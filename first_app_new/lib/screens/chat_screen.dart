import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app_new/services/api_service.dart';
import 'package:first_app_new/models/chat_model/chat_message.dart';
import 'package:first_app_new/models/chat_model/chat_user.dart';
import 'package:first_app_new/customs/chat_bubble.dart';
import 'package:first_app_new/customs/user_avatar.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:developer' as developer;

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ChatScreen({super.key, this.userData});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  bool _isUploading = false;
  String? _userId;
  ChatUser? _adminUser;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Get user ID from SharedPreferences instead
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');

      if (_userId == null || _userId!.isEmpty) {
        developer.log(
          'No user ID found, redirecting to login',
          name: 'ChatScreen',
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      await _fetchAdminUser();

      // Don't require admin user - allow chat even if no admin is available
      if (_adminUser == null) {
        developer.log(
          'No admin user found, but continuing to show chat interface',
          name: 'ChatScreen',
        );
        // Create a dummy admin user for UI purposes
        _adminUser = ChatUser(
          id: 'admin',
          name: 'Admin (Not Available)',
          role: 'admin',
        );
      }

      await _fetchChatHistory();

      // Reduced frequency to improve performance - refresh every 2 minutes instead of 30 seconds
      _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        _fetchChatHistory();
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error initializing chat: $e', name: 'ChatScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: "Chat interface loaded with limited functionality",
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  Future<void> _fetchAdminUser() async {
    try {
      final response = await ApiService.get('chat/users');
      developer.log(
        'Raw response from chat/users: $response',
        name: 'ChatScreen',
      );

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching users: ${response['error']}',
          name: 'ChatScreen',
        );
        return;
      }

      List<dynamic> users = [];
      // Check for direct data array or nested arrays
      if (response.containsKey('data') && response['data'] is List) {
        users = response['data'] ?? [];
      } else if (response.containsKey('users') && response['users'] is List) {
        users = response['users'] ?? [];
      } else {
        developer.log(
          'Unexpected response format: $response',
          name: 'ChatScreen',
        );
      }

      developer.log('Parsed users: $users', name: 'ChatScreen');

      if (users.isNotEmpty) {
        final admin = users.firstWhere((user) {
          final role = user['role']?.toString().toLowerCase();
          return role == 'admin' || role == 'administrator';
        }, orElse: () => null);

        if (admin != null) {
          setState(() {
            _adminUser = ChatUser(
              id: admin['_id'] ?? admin['id'], // Handle both '_id' and 'id'
              name:
                  admin['name'] ??
                  admin['fullName'] ??
                  'Admin', // Fallback names
              avatar: admin['avatar'] ?? admin['image'], // Handle avatar/image
              role: 'admin',
            );
          });
          developer.log(
            'Admin user found: ${_adminUser!.toString()}',
            name: 'ChatScreen',
          );
        } else {
          developer.log(
            'No admin user found in users list',
            name: 'ChatScreen',
          );
        }
      } else {
        developer.log('No users found in response', name: 'ChatScreen');
      }
    } catch (e) {
      developer.log('Exception fetching admin user: $e', name: 'ChatScreen');
    }
  }

  Future<void> _fetchChatHistory() async {
    try {
      // If no admin user is available, try to fetch any chat history for this user
      final targetUserId = _adminUser?.id ?? 'admin'; // Fallback to 'admin' id

      developer.log(
        'Fetching chat history for $_userId with $targetUserId',
        name: 'ChatScreen',
      );

      final response = await ApiService.get(
        'chat/history/$_userId/$targetUserId',
      );
      developer.log('Raw chat history response: $response', name: 'ChatScreen');

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching chat history: ${response['error']}',
          name: 'ChatScreen',
        );
        return;
      }

      // Parse messages list from API response
      List<dynamic> messagesJson = [];
      if (response.containsKey('messages') && response['messages'] is List) {
        messagesJson = response['messages'];
      } else if (response.containsKey('data') && response['data'] is List) {
        messagesJson = response['data'];
      } else {
        developer.log(
          'Unexpected chat history format: $response',
          name: 'ChatScreen',
        );
      }

      if (messagesJson.isEmpty) {
        developer.log('No messages found in response', name: 'ChatScreen');
      }

      final List<ChatMessage> messages =
          messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

      developer.log(
        'Parsed ${messages.length} messages: ${messages.map((m) => '${m.id}: ${m.content}').join(', ')}',
        name: 'ChatScreen',
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });

        // Only mark messages as read if we have a valid admin user
        if (_adminUser != null) {
          for (final message in messages) {
            if (message.senderId == _adminUser!.id && !message.isRead) {
              await _markMessageAsRead(message.id);
            }
          }
        }

        _scrollToBottom();
      }
    } catch (e) {
      developer.log(
        'Exception fetching chat history: $e',
        name: 'ChatScreen',
        error: e,
      );
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    try {
      final response = await ApiService.put(
        'chat/read/$messageId',
        {}, // Empty body, adjust if your API requires data
      );
      if (response.containsKey('error')) {
        developer.log(
          'Error marking message as read: ${response['error']}',
          name: 'ChatScreen',
        );
      }
    } catch (e) {
      developer.log(
        'Exception marking message as read: $e',
        name: 'ChatScreen',
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // Add optimistic message immediately to UI
    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _userId!,
      receiverId: _adminUser?.id ?? 'admin',
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      type: 'text',
    );

    setState(() {
      _messages.add(optimisticMessage);
    });
    _scrollToBottom();

    try {
      // Use admin user ID if available, otherwise use 'admin' as fallback
      final receiverId = _adminUser?.id ?? 'admin';

      final response = await ApiService.post('chat/message', {
        'senderId': _userId,
        'receiverId': receiverId,
        'content': content,
      });
      if (response.containsKey('error')) {
        developer.log(
          'Error sending message: ${response['error']}',
          name: 'ChatScreen',
        );
        Fluttertoast.showToast(
          msg: "Failed to send message",
          backgroundColor: Colors.red,
        );
        // Remove optimistic message on error
        setState(() {
          _messages.remove(optimisticMessage);
        });
        return;
      }
      await _fetchChatHistory();
    } catch (e) {
      developer.log('Exception sending message: $e', name: 'ChatScreen');
      Fluttertoast.showToast(
        msg: "Failed to send message",
        backgroundColor: Colors.red,
      );
      // Remove optimistic message on error
      setState(() {
        _messages.remove(optimisticMessage);
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final imageUrl = await _uploadImage(File(image.path));

      if (imageUrl != null) {
        // Use admin user ID if available, otherwise use 'admin' as fallback
        final receiverId = _adminUser?.id ?? 'admin';

        // Add optimistic image message
        final optimisticMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: _userId!,
          receiverId: receiverId,
          content: 'Image',
          imageUrl: imageUrl,
          timestamp: DateTime.now(),
          isRead: false,
          type: 'image',
        );

        setState(() {
          _messages.add(optimisticMessage);
        });
        _scrollToBottom();

        final response = await ApiService.post('chat/message', {
          'senderId': _userId,
          'receiverId': receiverId,
          'content': 'Image',
          'imageUrl': imageUrl,
          'type': 'image',
        });
        if (response.containsKey('error')) {
          developer.log(
            'Error sending image message: ${response['error']}',
            name: 'ChatScreen',
          );
          Fluttertoast.showToast(
            msg: "Failed to send image",
            backgroundColor: Colors.red,
          );
          // Remove optimistic message on error
          setState(() {
            _messages.remove(optimisticMessage);
          });
          return;
        }
        await _fetchChatHistory();
      }
    } catch (e) {
      developer.log('Exception picking/sending image: $e', name: 'ChatScreen');
      Fluttertoast.showToast(
        msg: "Failed to send image",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      // First try to use ApiService to upload directly to our backend
      final response = await ApiService.uploadFile(
        'upload',
        imageFile,
        'image',
      );

      if (response.containsKey('error')) {
        developer.log(
          'Error uploading image: ${response['error']}',
          name: 'ChatScreen',
        );

        // Try Cloudinary as fallback if API upload fails
        try {
          final cloudinary = CloudinaryPublic('your-cloud-name', 'ml_default');
          final cloudinaryResponse = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              imageFile.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'chat_images',
            ),
          );
          return cloudinaryResponse.secureUrl;
        } catch (cloudinaryError) {
          developer.log(
            'Cloudinary upload also failed: $cloudinaryError',
            name: 'ChatScreen',
          );
          throw Exception('All upload methods failed');
        }
      }

      // Construct the full URL for the uploaded image
      final filename = response['filename'];
      if (filename != null && filename.isNotEmpty) {
        // Use the complete URL including hostname
        final imageUrl = 'http://192.168.100.198:3000/uploads/$filename';
        developer.log('Image URL: $imageUrl', name: 'ChatScreen');
        return imageUrl;
      }

      return null;
    } catch (e) {
      developer.log('Error uploading image: $e', name: 'ChatScreen');
      Fluttertoast.showToast(
        msg: "Failed to upload image",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Debug the message list
    developer.log(
      'Building chat with ${_messages.length} messages',
      name: 'ChatScreen',
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(user: _adminUser!, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _adminUser!.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchChatHistory();
              Fluttertoast.showToast(
                msg: "Refreshing messages...",
                backgroundColor: Colors.green,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
          ),
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.grey[200],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading image...'),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: _sendTextMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with ${_adminUser!.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchChatHistory,
            child: const Text('Refresh Messages'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _userId;

        // Debug output to console for message rendering
        developer.log(
          'Rendering message[$index]: id=${message.id}, content=${message.content}, type=${message.type}, senderId=${message.senderId}, isMe=$isMe',
          name: 'ChatScreen',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ChatBubble(message: message, isMe: isMe),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
