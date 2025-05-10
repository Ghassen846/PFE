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

router.get('/', getFoodItems); // Get all food items
router.get('/get', getFoodItems); // Additional route to match frontend request
router.get('/:id', getFoodItemById); // Get food item by ID
router.post('/', upload.single('image'), createFoodItem); // Create a new food item with image
router.put('/:id', upload.single('image'), updateFoodItem); // Update a food item with image
router.delete('/:id', deleteFoodItem); // Delete a food item
router.post('/:id/rate', rateFood); // Rate a food item

// Upload food image
router.post('/upload-image/:id', upload.single('image'), async (req, res) => {
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
