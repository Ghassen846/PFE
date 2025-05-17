import express from 'express';
import multer from 'multer';
import { 
  createFoodItem, 
  getFoodItems, 
  getFoodItemById,
  updateFoodItem,
  deleteFoodItem,
  rateFood
} from '../controllers/foodController.js';
import { protect, admin } from '../middleware/auth.js';
import Food from '../models/Food.js';

const router = express.Router();

// Configure multer to save files to disk in 'uploads/foods' folder
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/foods/');
  },
  filename: function (req, file, cb) {
    // Use Date.now() to avoid name collisions
    cb(null, Date.now() + '_' + file.originalname);
  }
});
const upload = multer({ storage });

router.get('/', getFoodItems); // Get all food items (public access)
router.get('/get', getFoodItems); // Additional route to match frontend request (public access)
router.get('/:id', getFoodItemById); // Get food item by ID (public access)
router.post('/', protect, admin, upload.single('image'), createFoodItem); // Create a new food item with image (admin only)
router.put('/:id', protect, admin, upload.single('image'), updateFoodItem); // Update a food item with image (admin only)
router.delete('/:id', protect, admin, deleteFoodItem); // Delete a food item (admin only)
router.post('/:id/rate', protect, rateFood); // Rate a food item (authenticated users only)

// Upload food image
router.post('/upload-image/:id', protect, admin, upload.single('image'), async (req, res) => {
  try {
    const food = await Food.findById(req.params.id);
    if (!food) return res.status(404).json({ message: "Food not found" });

    food.imageUrl = `/uploads/foods/${req.file.filename}`;
    await food.save();

    res.json({ imageUrl: food.imageUrl });
  } catch (err) {
    res.status(500).json({ message: "Image upload failed", error: err.message });
  }
});

export default router;
