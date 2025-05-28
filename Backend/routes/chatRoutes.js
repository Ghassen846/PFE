import express from 'express';
import mongoose from 'mongoose';
import ChatMessage from '../models/ChatMessage.js';
import ChatConversation from '../models/ChatConversation.js';
import User from '../models/User.js';
import { protect } from '../middleware/auth.js';  // Import authentication middleware

const router = express.Router();

// Apply authentication middleware to all chat routes
router.use(protect);

// Get chat history between two users
router.get('/history/:senderId/:receiverId', async (req, res) => {
  try {
    const { senderId, receiverId } = req.params;
    const { user } = req;  // Get authenticated user from request
    
    // Validate ObjectIds
    if (!mongoose.Types.ObjectId.isValid(senderId) || !mongoose.Types.ObjectId.isValid(receiverId)) {
      return res.status(400).json({ error: 'Invalid user IDs' });
    }
    
    // Ensure user is authorized to access this chat history
    if (user._id.toString() !== senderId && user._id.toString() !== receiverId && user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to access this chat history' });
    }
    
    // Get messages between these two users
    const messages = await ChatMessage.find({
      $or: [
        { sender: senderId, receiver: receiverId },
        { sender: receiverId, receiver: senderId }
      ]
    })
    .sort({ createdAt: 1 })
    .lean();
    
    // Format messages to match the expected client format
    const formattedMessages = messages.map(msg => ({
      id: msg._id.toString(),
      senderId: msg.sender.toString(),
      receiverId: msg.receiver.toString(),
      content: msg.message,
      timestamp: msg.createdAt.toISOString(),
      isRead: msg.isRead,
      imageUrl: msg.imageUrl,
      type: msg.imageUrl && msg.imageUrl.length > 0 ? 'image' : 'text'
    }));
    
    res.json(formattedMessages);
  } catch (err) {
    console.error('Error getting chat history:', err);
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
});

// Get conversations for a user
router.get('/conversations/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { user } = req;  // Get authenticated user from request
    
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }
    
    // Ensure user is authorized to access these conversations
    if (user._id.toString() !== userId && user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to access these conversations' });
    }
    
    // Get all conversations for this user
    const conversations = await ChatConversation.find({
      participants: userId
    })
    .populate('lastMessage')
    .populate('participants', 'name role avatar')
    .sort({ lastMessageTimestamp: -1 })
    .lean();
    
    // Format conversations to match the expected client format
    const formattedConversations = await Promise.all(conversations.map(async (conv) => {
      // Filter conversations based on roles
      const otherParticipant = conv.participants.find(p => p._id.toString() !== userId);
      
      // Only allow conversations between livreurs and admins
      const currentUserRole = conv.participants.find(p => p._id.toString() === userId).role;
      const otherUserRole = otherParticipant.role;
      
      if ((currentUserRole === 'livreur' && otherUserRole !== 'admin') ||
          (currentUserRole === 'admin' && otherUserRole !== 'livreur')) {
        return null;  // Skip this conversation
      }
      
      // Get the most recent messages for this conversation
      const messages = await ChatMessage.find({
        $or: [
          { sender: conv.participants[0]._id, receiver: conv.participants[1]._id },
          { sender: conv.participants[1]._id, receiver: conv.participants[0]._id }
        ]
      })
      .sort({ createdAt: -1 })
      .limit(20)
      .lean();
      
      // Format messages
      const formattedMessages = messages.map(msg => ({
        id: msg._id.toString(),
        senderId: msg.sender.toString(),
        receiverId: msg.receiver.toString(),
        content: msg.message,
        timestamp: msg.createdAt.toISOString(),
        isRead: msg.isRead,
        imageUrl: msg.imageUrl,
        type: msg.imageUrl && msg.imageUrl.length > 0 ? 'image' : 'text'
      }));
      
      return {
        id: conv._id.toString(),
        participants: conv.participants.map(p => p._id.toString()),
        messages: formattedMessages.reverse(), // Oldest first for client display
        lastMessageTimestamp: conv.lastMessageTimestamp.toISOString(),
        hasUnreadMessages: conv.unreadCount > 0,
        otherUserName: otherParticipant ? otherParticipant.name : 'Unknown User',
        otherUserAvatar: otherParticipant ? otherParticipant.avatar : null,
        otherUserRole: otherParticipant ? otherParticipant.role : 'unknown'
      };
    }));
    
    // Filter out null conversations (those that didn't match our role criteria)
    const validConversations = formattedConversations.filter(conv => conv !== null);
    
    res.json(validConversations);
  } catch (err) {
    console.error('Error getting conversations:', err);
    res.status(500).json({ error: 'Failed to fetch conversations' });
  }
});

// Get all available users for chat
router.get('/users', async (req, res) => {
  try {
    const { user } = req;  // Get authenticated user from request
    
    let query = {};
    
    // Filter users based on role
    if (user.role === 'admin') {
      query.role = 'livreur';  // Admins can only chat with livreurs
    } else if (user.role === 'livreur') {
      query.role = 'admin';  // Livreurs can only chat with admins
    } else {
      return res.status(403).json({ error: 'You are not authorized to use chat' });
    }
    
    // Get filtered users
    const users = await User.find(query, 'name role avatar')
      .lean();
    
    // Format users to match the expected client format
    const formattedUsers = users.map(user => ({
      id: user._id.toString(),
      name: user.name,
      role: user.role || 'user',
      avatar: user.avatar
    }));
    
    res.json(formattedUsers);
  } catch (err) {
    console.error('Error getting users:', err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Create a new message
router.post('/message', async (req, res) => {
  try {
    const { senderId, receiverId, content, imageUrl } = req.body;
    const { user } = req;  // Get authenticated user from request
    
    // Validate required fields
    if (!senderId || !receiverId || !content) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Validate ObjectIds
    if (!mongoose.Types.ObjectId.isValid(senderId) || !mongoose.Types.ObjectId.isValid(receiverId)) {
      return res.status(400).json({ error: 'Invalid user IDs' });
    }
    
    // Ensure user is authorized to send this message
    if (user._id.toString() !== senderId) {
      return res.status(403).json({ error: 'Not authorized to send messages on behalf of other users' });
    }
    
    // Get both users to validate roles
    const [sender, receiver] = await Promise.all([
      User.findById(senderId, 'role').lean(),
      User.findById(receiverId, 'role').lean()
    ]);
    
    if (!sender || !receiver) {
      return res.status(404).json({ error: 'One or both users not found' });
    }
    
    // Only allow messaging between livreurs and admins
    if ((sender.role === 'livreur' && receiver.role !== 'admin') ||
        (sender.role === 'admin' && receiver.role !== 'livreur')) {
      return res.status(403).json({ error: 'Messaging is only allowed between livreurs and admins' });
    }
    
    // Create new message
    const newMessage = new ChatMessage({
      sender: senderId,
      receiver: receiverId,
      message: content,
      imageUrl: imageUrl || '',
      isRead: false,
      createdAt: new Date()
    });
    
    await newMessage.save();
    
    // Get or create conversation
    const participants = [senderId, receiverId].sort();
    let conversation = await ChatConversation.findOne({
      participants: { $all: participants }
    });
    
    if (!conversation) {
      conversation = new ChatConversation({
        participants,
        lastMessage: newMessage._id,
        lastMessageTimestamp: newMessage.createdAt,
        unreadCount: 1
      });
    } else {
      conversation.lastMessage = newMessage._id;
      conversation.lastMessageTimestamp = newMessage.createdAt;
      conversation.unreadCount += 1;
    }
    
    await conversation.save();
    
    // Format the message for client response
    const formattedMessage = {
      id: newMessage._id.toString(),
      senderId: newMessage.sender.toString(),
      receiverId: newMessage.receiver.toString(),
      content: newMessage.message,
      timestamp: newMessage.createdAt.toISOString(),
      isRead: newMessage.isRead,
      imageUrl: newMessage.imageUrl,
      type: newMessage.imageUrl && newMessage.imageUrl.length > 0 ? 'image' : 'text'
    };
    
    res.status(201).json(formattedMessage);
  } catch (err) {
    console.error('Error creating message:', err);
    res.status(500).json({ error: 'Failed to create message' });
  }
});

// Mark message as read
router.put('/read/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    const { user } = req;  // Get authenticated user from request
    
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(messageId)) {
      return res.status(400).json({ error: 'Invalid message ID' });
    }
    
    // Find the message
    const message = await ChatMessage.findById(messageId);
    
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }
    
    // Ensure user is the intended receiver of this message
    if (message.receiver.toString() !== user._id.toString() && user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to mark this message as read' });
    }
    
    message.isRead = true;
    await message.save();
    
    // Update conversation unread count
    const conversation = await ChatConversation.findOne({
      participants: { $all: [message.sender, message.receiver] }
    });
    
    if (conversation) {
      // Only decrement if greater than 0
      if (conversation.unreadCount > 0) {
        conversation.unreadCount -= 1;
        await conversation.save();
      }
    }
    
    res.json({ success: true, id: messageId });
  } catch (err) {
    console.error('Error marking message as read:', err);
    res.status(500).json({ error: 'Failed to mark message as read' });
  }
});

// Get chat history for admin (all conversations)
router.get('/history/admin', async (req, res) => {
  try {
    const { user } = req;  // Get authenticated user from request
    
    // Ensure user is an admin
    if (user.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can access admin chat history' });
    }
    
    // Check if optional query parameters are provided
    const { limit = 50, offset = 0, userId } = req.query;
    
    // Create base query to only get messages between admins and livreurs
    let query = {};
    
    // If userId is provided, filter conversations involving that user
    if (userId && mongoose.Types.ObjectId.isValid(userId)) {
      const targetUser = await User.findById(userId, 'role').lean();
      if (!targetUser) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      // Only allow filtering by livreur users
      if (targetUser.role !== 'livreur') {
        return res.status(400).json({ error: 'Can only filter messages by livreur users' });
      }
      
      query = {
        $or: [
          { sender: userId, receiver: user._id },
          { sender: user._id, receiver: userId }
        ]
      };
    } else {
      // Get all conversations between admins and livreurs
      query = {
        $or: [
          { sender: user._id },
          { receiver: user._id }
        ]
      };
    }
    
    // Get messages with pagination
    const messages = await ChatMessage.find(query)
      .sort({ createdAt: -1 })
      .skip(parseInt(offset))
      .limit(parseInt(limit))
      .populate('sender', 'name username role')
      .populate('receiver', 'name username role')
      .lean();
    
    // Filter messages to only show admin-livreur communications
    const validMessages = messages.filter(msg => {
      return (msg.sender.role === 'admin' && msg.receiver.role === 'livreur') ||
             (msg.sender.role === 'livreur' && msg.receiver.role === 'admin');
    });
    
    // Format messages to match the expected client format
    const formattedMessages = validMessages.map(msg => ({
      id: msg._id.toString(),
      senderId: msg.sender._id.toString(),
      receiverId: msg.receiver._id.toString(),
      senderName: msg.sender.name,
      receiverName: msg.receiver.name,
      senderRole: msg.sender.role,
      receiverRole: msg.receiver.role,
      content: msg.message,
      timestamp: msg.createdAt.toISOString(),
      isRead: msg.isRead,
      imageUrl: msg.imageUrl,
      type: msg.imageUrl && msg.imageUrl.length > 0 ? 'image' : 'text'
    }));
    
    // Get total count for pagination
    const totalCount = await ChatMessage.countDocuments(query);
    
    res.json({
      messages: formattedMessages,
      pagination: {
        total: totalCount,
        offset: parseInt(offset),
        limit: parseInt(limit)
      }
    });
  } catch (err) {
    console.error('Error getting admin chat history:', err);
    res.status(500).json({ error: 'Failed to fetch admin chat history' });
  }
});

// Get online status of users
router.get('/online-status', async (req, res) => {
  try {
    // Check if userIds query parameter is provided
    const { userIds } = req.query;
    
    if (!userIds) {
      return res.status(400).json({ error: 'userIds parameter is required' });
    }
    
    // Parse the userIds array from the query string
    let userIdArray;
    try {
      userIdArray = JSON.parse(userIds);
      
      // Validate that all IDs are valid ObjectIds
      const validIds = userIdArray.filter(id => mongoose.Types.ObjectId.isValid(id));
      if (validIds.length !== userIdArray.length) {
        return res.status(400).json({ error: 'Invalid user IDs provided' });
      }
    } catch (err) {
      return res.status(400).json({ error: 'Invalid userIds format. Expected JSON array' });
    }
    
    // Get online status for the specified users
    const users = await User.find(
      { _id: { $in: userIdArray } },
      'isOnline lastActive'
    ).lean();
    
    // Format the response
    const onlineStatus = {};
    users.forEach(user => {
      onlineStatus[user._id.toString()] = {
        isOnline: user.isOnline,
        lastActive: user.lastActive
      };
    });
    
    res.json(onlineStatus);
  } catch (err) {
    console.error('Error getting online status:', err);
    res.status(500).json({ error: 'Failed to fetch online status' });
  }
});

// Get unread messages count
router.get('/unread', async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: 'Valid userId parameter is required' });
    }
    
    // Count all unread messages where user is the receiver
    const unreadCount = await ChatMessage.countDocuments({
      receiver: userId,
      isRead: false
    });
      // Get unread counts grouped by sender
    const unreadBySender = await ChatMessage.aggregate([
      {
        $match: {
          receiver: new mongoose.Types.ObjectId(userId),
          isRead: false
        }
      },
      {
        $group: {
          _id: '$sender',
          count: { $sum: 1 },
          lastMessage: { $last: '$message' },
          lastTimestamp: { $last: '$createdAt' }
        }
      }
    ]);
    
    // Get sender information for the response
    const senderIds = unreadBySender.map(item => item._id);
    const senders = await User.find(
      { _id: { $in: senderIds } },
      'name username role'
    ).lean();
    
    // Create a map of sender details
    const senderMap = {};
    senders.forEach(sender => {
      senderMap[sender._id.toString()] = {
        name: sender.name,
        username: sender.username,
        role: sender.role
      };
    });
    
    // Format the unread messages by sender
    const unreadMessages = unreadBySender.map(item => ({
      senderId: item._id.toString(),
      count: item.count,
      lastMessage: item.lastMessage,
      lastTimestamp: item.lastTimestamp,
      sender: senderMap[item._id.toString()] || { name: 'Unknown User' }
    }));
    
    res.json({
      totalUnread: unreadCount,
      unreadBySender: unreadMessages
    });
  } catch (err) {
    console.error('Error getting unread messages:', err);
    res.status(500).json({ error: 'Failed to fetch unread messages' });
  }
});

export default router;
