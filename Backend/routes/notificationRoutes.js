import express from 'express';
import { 
  getNotifications,
  getUnreadNotifications,
  markAsRead,
  markAllAsRead,
  createNotification,
  deleteNotification,
  createSystemNotification
} from '../controllers/notificationController.js';
import { protect, admin } from '../middleware/auth.js';

const router = express.Router();

// Get all notifications for the current user
router.get('/', protect, getNotifications);

// Get all unread notifications for the current user
router.get('/unread', protect, getUnreadNotifications);

// Mark a notification as read
router.put('/:id/read', protect, markAsRead);

// Mark all notifications as read
router.put('/read-all', protect, markAllAsRead);

// Create a new notification (requires authentication)
router.post('/', protect, createNotification);

// Create a system notification (admin only)
router.post('/system', protect, admin, createSystemNotification);

// Delete a notification
router.delete('/:id', protect, deleteNotification);

export default router;