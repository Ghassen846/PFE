import express from 'express';
import multer from 'multer';
import {
  addMaintenance,
  addUser,
  deleteUser,
  getAllUsers,
  getCurrentUser,
  getProfile,
  getUserById,
  getUserProfile,
  getUsersByRole,
  loginUser,
  rateLivreur,
  registerUser,
  updateUser,
  updateVehicle
} from '../controllers/userController.js';
import { protect } from '../middleware/auth.js'; // <-- import auth middleware
import User from "../models/User.js"; // <-- add this import

const router = express.Router();

// Configure multer to save files to disk in 'uploads' folder
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    // Use Date.now() to avoid name collisions
    cb(null, Date.now() + '_' + file.originalname);
  }
});
const upload = multer({ storage });

// Route for client sign-up
router.post('/register', upload.single('profilePicture'), registerUser);

// Route for user login
router.post('/login', loginUser);

// Route for getting user profile by ID
router.get('/profile/:id', getUserProfile);

// Route for getting current user's profile (for navbar etc)
router.get('/profile', protect, getProfile);

// --- Add these routes for image upload/delete ---

// Upload profile image - with ID parameter
router.post(
  "/upload-image/:id",
  protect,
  upload.single("image"),
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);
      if (!user) return res.status(404).json({ message: "User not found" });
      user.image = req.file.filename;
      await user.save();
      res.json({ image: user.image });
    } catch (err) {
      res.status(500).json({ message: "Image upload failed" });
    }
  }
);

// Upload profile image - without ID parameter (uses authenticated user)
router.post(
  "/upload-image",
  protect,
  upload.single("image"),
  async (req, res) => {
    try {
      const user = await User.findById(req.user._id);
      if (!user) return res.status(404).json({ message: "User not found" });
      user.image = req.file.filename;
      await user.save();
      res.json({ image: user.image, imageUrl: req.file.filename });
    } catch (err) {
      res.status(500).json({ message: "Image upload failed" });
    }
  }
);

// Delete profile image
router.delete(
  "/delete-image/:id",
  protect,
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);
      if (!user) return res.status(404).json({ message: "User not found" });
      user.image = "";
      await user.save();
      res.json({ message: "Image deleted" });
    } catch (err) {
      res.status(500).json({ message: "Image delete failed" });
    }
  }
);

// Route for updating vehicle
router.put('/livreur/:id/vehicle', updateVehicle);

// Route for adding maintenance
router.post('/livreur/:id/maintenance', addMaintenance);

// CRUD Routes for User Management
// Get all users
router.get('/get', protect, getAllUsers);

// Get users by role
router.get('/role/:role', protect, getUsersByRole);

// Update user routes
router.put('/:id', protect, updateUser);
router.put('/update/:id', protect, updateUser); // Add this aliased route to match frontend

// Delete user
router.delete('/:id', protect, deleteUser);

// Add user (admin function)
router.post('/add', protect, addUser);

// Get user by ID
router.get('/get/:id', getUserById);

// Rate a livreur
router.post('/livreur/:id/rate', rateLivreur);

// Get current user
router.get('/me', protect, getCurrentUser);

export default router;
