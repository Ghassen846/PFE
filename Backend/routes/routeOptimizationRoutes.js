import express from 'express';
import { 
  getOptimizedRoute, 
  updateDeliveryLocation 
} from '../controllers/deliveryController.js';
import { protect, livreur } from '../middleware/auth.js';

const router = express.Router();

// Get optimized delivery route for a delivery driver
router.get('/optimized-route', protect, livreur, getOptimizedRoute);

// Update delivery location (for tracking)
router.post('/update-location', protect, livreur, updateDeliveryLocation);

export default router;