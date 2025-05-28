# Chat Functionality Documentation

## Overview
The chat functionality allows real-time messaging between admin users and delivery personnel. It uses WebSockets to provide instant message delivery and features like online status indicators, read receipts, and image sharing.

## Features
- Real-time messaging using WebSockets
- User online status indicators
- Read receipts
- Image sharing
- Chat history persistence
- Conversation list view
- User-to-user direct messaging

## Technical Implementation

### Models
- **ChatMessage**: Represents a single message with properties for sender, receiver, content, timestamps, etc.
- **ChatConversation**: Represents a conversation between two users, containing messages and metadata.
- **ChatUser**: Represents a user in the chat system with properties like online status, name, etc.

### MongoDB Schema
- **ChatMessage**: MongoDB collection for storing messages
  ```json
  {
    "_id": { "$oid": "682e924c002e6d0e6c0361c1" },
    "sender": { "$oid": "6819f2d047146d3fb1e0dc9a" },
    "receiver": { "$oid": "6815c24f788938e9b9c1a1ef" },
    "message": "Hello there",
    "imageUrl": "",
    "isRead": true,
    "createdAt": { "$date": "2025-05-22T02:56:12.991Z" },
    "__v": 0
  }
  ```
- **ChatConversation**: MongoDB collection for storing conversations
  ```json
  {
    "_id": { "$oid": "682e924c002e6d0e6c0361c2" },
    "participants": [
      { "$oid": "6819f2d047146d3fb1e0dc9a" },
      { "$oid": "6815c24f788938e9b9c1a1ef" }
    ],
    "lastMessage": { "$oid": "682e924c002e6d0e6c0361c1" },
    "lastMessageTimestamp": { "$date": "2025-05-22T02:56:12.991Z" },
    "unreadCount": 0,
    "__v": 0
  }
  ```

### Services
- **ChatService**: Singleton service that manages WebSocket connections, message sending/receiving, and connection state.

### UI Components
- **ChatContactsScreen**: Shows a list of conversations and available users.
- **ChatScreen**: Shows the messages in a conversation and allows sending new messages.
- **ChatBubble**: Renders a single message in the chat interface.
- **UserAvatar**: Displays user avatar with online status indicator.
- **ChatButton**: A reusable button to start a chat with a specific user.

## Backend Integration
The chat functionality integrates with the Node.js backend using Socket.io. The backend handles:
- User presence management (online/offline status)
- Message routing between users
- Message storage and retrieval in MongoDB
- Image uploads

## How to Use
1. **Start a Chat**: Use the ChatButton component in various screens (order details, profile) or access via bottom navigation bar
2. **Send Messages**: Type in the text field and press send
3. **Send Images**: Tap the image icon to select and send an image
4. **View Status**: Green dot indicates online users

## Integration Points
- Bottom navigation bar (Chat tab)
- Order detail screen (Chat button)
- Profile screens (Chat button)
