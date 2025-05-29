import 'package:flutter/material.dart';
import 'package:first_app_new/models/chat_model/chat_message.dart';
import 'dart:developer' as developer;

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    developer.log(
      'Building bubble: content=${message.content}, type=${message.type}, imageUrl=${message.imageUrl}',
      name: 'ChatBubble',
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding:
            message.type == 'image'
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[400] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildMessageContent(context),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    try {
      if (message.type == 'image' &&
          message.imageUrl != null &&
          message.imageUrl!.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return Container(
                    height: 150,
                    width: 200,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  developer.log(
                    'Error loading image: $error, URL: ${message.imageUrl}',
                    name: 'ChatBubble',
                    error: error,
                    stackTrace: stackTrace,
                  );

                  return Container(
                    height: 100,
                    width: 150,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.red[400],
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image failed to load',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 6.0),
              child: Text(
                'Image',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      } else {
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
      }
    } catch (e) {
      developer.log('Error rendering message content: $e', name: 'ChatBubble');

      // Fallback content if message rendering fails
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error displaying message',
          style: TextStyle(color: Colors.red[800]),
        ),
      );
    }
  }
}
