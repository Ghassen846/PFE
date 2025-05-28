import mongoose from 'mongoose';

const chatConversationSchema = new mongoose.Schema({
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }],
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ChatMessage'
  },
  lastMessageTimestamp: {
    type: Date,
    default: Date.now
  },
  unreadCount: {
    type: Number,
    default: 0
  }
});

// Add index for faster queries
// Remove this line to avoid duplicate index with the unique compound index below
// chatConversationSchema.index({ participants: 1 }); 
chatConversationSchema.index({ lastMessageTimestamp: -1 });

// Create a unique compound index for participants to ensure
// there's only one conversation between the same two users
chatConversationSchema.index({ participants: 1 }, { unique: true });

const ChatConversation = mongoose.model('ChatConversation', chatConversationSchema);

export default ChatConversation;
