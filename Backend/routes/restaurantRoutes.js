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

router.get('/', getRestaurants); // Get all restaurants
router.get('/:id', getRestaurantById); // Get restaurant by ID
router.post('/', upload.single('image'), createRestaurant); // Create a new restaurant with image upload
router.put('/:id', upload.single('image'), updateRestaurant); // Update a restaurant with image upload
router.delete('/:id', deleteRestaurant); // Delete a restaurant
router.post('/:id/rate', rateRestaurant); // Rate a restaurant

export default router;
