import express from 'express';
import multer from 'multer';
import {
  createRestaurant,
  deleteRestaurant,
  getRestaurantById,
  getRestaurants,
  rateRestaurant,
  updateRestaurant
} from '../controllers/restaurantController.js';
import { protect, admin } from '../middleware/auth.js';

const router = express.Router();

// Configure multer for restaurant image uploads
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    cb(null, 'uploads/restaurants/');
  },
  filename: function(req, file, cb) {
    cb(null, Date.now() + '_' + file.originalname);
  }
});

const upload = multer({ storage });

router.get('/', getRestaurants); // Get all restaurants (public access)
router.get('/:id', getRestaurantById); // Get restaurant by ID (public access)
router.post('/', protect, admin, upload.single('image'), createRestaurant); // Create a new restaurant with image upload (admin only)
router.put('/:id', protect, admin, upload.single('image'), updateRestaurant); // Update a restaurant with image upload (admin only)
router.delete('/:id', protect, admin, deleteRestaurant); // Delete a restaurant (admin only)
router.post('/:id/rate', protect, rateRestaurant); // Rate a restaurant (authenticated users)

export default router;
