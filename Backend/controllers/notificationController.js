import Notification from '../models/Notification.js';
import User from '../models/User.js';
import mongoose from 'mongoose';

// Get all notifications for the current user
export const getNotifications = async (req, res) => {
  try {
    const userId = req.user._id; // From auth middleware
    
    const notifications = await Notification.find({ recipient: userId })
      .sort({ createdAt: -1 }) // Sort by newest first
      .populate('sender', 'name email role');
    
    res.json(notifications);
  } catch (err) {
    console.error("Error fetching notifications:", err.message);
    res.status(500).json({ message: "Error fetching notifications" });
  }
};

// Get unread notifications for the current user
export const getUnreadNotifications = async (req, res) => {
  try {
    const userId = req.user._id; // From auth middleware
    
    const notifications = await Notification.find({ 
      recipient: userId,
      read: false
    })
    .sort({ createdAt: -1 }) // Sort by newest first
    .populate('sender', 'name email role');
    
    res.json(notifications);
  } catch (err) {
    console.error("Error fetching unread notifications:", err.message);
    res.status(500).json({ message: "Error fetching unread notifications" });
  }
};

// Mark a notification as read
export const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    
    // Validate notification ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid notification ID' });
    }
    
    // Find notification and ensure it belongs to the current user
    const notification = await Notification.findOne({ 
      _id: id,
      recipient: userId
    });
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    
    // Mark as read
    notification.read = true;
    await notification.save();
    
    res.json({ message: 'Notification marked as read', notification });
  } catch (err) {
    console.error("Error marking notification as read:", err.message);
    res.status(500).json({ message: "Error marking notification as read" });
  }
};

// Mark all notifications as read for the current user
export const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id;
    
    const result = await Notification.updateMany(
      { recipient: userId, read: false },
      { $set: { read: true } }
    );
    
    res.json({ 
      message: 'All notifications marked as read',
      count: result.modifiedCount
    });
  } catch (err) {
    console.error("Error marking all notifications as read:", err.message);
    res.status(500).json({ message: "Error marking all notifications as read" });
  }
};

// Create a new notification
export const createNotification = async (req, res) => {
  try {
    const { recipient, type, message, data } = req.body;
    const sender = req.user._id; // Current user is the sender
    
    // Validate required fields
    if (!recipient || !type || !message) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    // Validate recipient exists
    const recipientUser = await User.findById(recipient);
    if (!recipientUser) {
      return res.status(404).json({ message: 'Recipient user not found' });
    }
    
    // Create notification
    const notification = new Notification({
      recipient,
      sender,
      type,
      message,
      data: data || {}
    });
    
    await notification.save();
    
    res.status(201).json({ 
      message: 'Notification created successfully',
      notification
    });
  } catch (err) {
    console.error("Error creating notification:", err.message);
    res.status(500).json({ message: "Error creating notification" });
  }
};

// Delete a notification
export const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;
    
    // Validate notification ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid notification ID' });
    }
    
    // Find and delete notification (ensure it belongs to current user or user is admin)
    const notification = await Notification.findOneAndDelete({
      _id: id,
      $or: [
        { recipient: userId },
        { sender: userId }
      ]
    });
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found or you do not have permission to delete it' });
    }
    
    res.json({ message: 'Notification deleted successfully' });
  } catch (err) {
    console.error("Error deleting notification:", err.message);
    res.status(500).json({ message: "Error deleting notification" });
  }
};

// Create a system notification (for admin use)
export const createSystemNotification = async (req, res) => {
  try {
    const { recipient, message, data } = req.body;
    
    // Validate required fields
    if (!recipient || !message) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    // Validate recipient exists
    const recipientUser = await User.findById(recipient);
    if (!recipientUser) {
      return res.status(404).json({ message: 'Recipient user not found' });
    }
    
    // Create system notification
    const notification = new Notification({
      recipient,
      type: 'system_message',
      message,
      data: data || {}
    });
    
    await notification.save();
    
    res.status(201).json({ 
      message: 'System notification created successfully',
      notification
    });
  } catch (err) {
    console.error("Error creating system notification:", err.message);
    res.status(500).json({ message: "Error creating system notification" });
  }
};