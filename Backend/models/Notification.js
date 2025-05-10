import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  type: {
    type: String,
    enum: ['delivery_assigned', 'order_status_changed', 'system_message', 'welcome', 'order_delivered'],
    required: true
  },
  message: {
    type: String,
    required: true
  },
  read: {
    type: Boolean,
    default: false
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  }
}, {
  timestamps: true
});

// Index for faster queries
notificationSchema.index({ recipient: 1, read: 1, createdAt: -1 });

// Static method to create a new notification
notificationSchema.statics.createNotification = async function(data) {
  try {
    const notification = new this(data);
    await notification.save();
    return notification;
  } catch (error) {
    throw new Error(`Error creating notification: ${error.message}`);
  }
};

// Method to mark notification as read
notificationSchema.methods.markAsRead = async function() {
  this.read = true;
  await this.save();
  return this;
};

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;