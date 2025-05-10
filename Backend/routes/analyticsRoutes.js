import express from 'express';
import { getAnalytics, getDeliveryAnalytics } from '../controllers/analyticsController.js';
import { protect, admin } from '../middleware/auth.js';

const router = express.Router();

// Get general analytics (admin only)
router.get('/', protect, admin, getAnalytics);

// Get delivery-specific analytics (admin only)
router.get('/delivery', protect, admin, getDeliveryAnalytics);

export default router;