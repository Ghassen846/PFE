import express from 'express';
import { 
  createFeedback, 
  getFeedbackByOrder, 
  getFeedbackByDelivery, 
  getFeedbackByRestaurant,
  getUserFeedback
} from '../controllers/feedbackController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// Create new feedback
router.post('/', protect, createFeedback);

// Get feedback for a specific order
router.get('/order/:orderId', protect, getFeedbackByOrder);

// Get all feedback for a delivery
router.get('/delivery/:deliveryId', protect, getFeedbackByDelivery);

// Get all feedback for a restaurant
router.get('/restaurant/:restaurantId', protect, getFeedbackByRestaurant);

// Get all feedback submitted by current user
router.get('/my-feedback', protect, getUserFeedback);

export default router;