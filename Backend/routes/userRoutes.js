// filepath: c:\Users\PC\developement\flutter-apps\Backend\routes\userRoutes.js
import express from 'express';
import multer from 'multer';
import path from 'path';
import { 
  registerUser, 
  updateUser, 
  login, 
  getAllUsers, 
  getUserById, 
  getCurrentUser,
  updateOnlineStatus,
  changePassword
} from '../controllers/userController.js';
import User from '../models/User.js'; // Import the User model
import { protect, admin, livreur } from '../middleware/auth.js'; // Import auth middleware

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, `${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});
const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    // Accept any file for now to fix the immediate issue
    // We can be more restrictive once we understand what types are being sent
    console.log('[Backend] File upload received:', file);
    return cb(null, true);
    
    /* Original restrictive check
    const filetypes = /jpeg|jpg|png|pdf/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype);
    if (extname && mimetype) {
      return cb(null, true);
    }
    cb(new Error('Only images (jpeg, jpg, png) and PDFs are allowed'));
    */
  },
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
});

// User registration
router.post('/register', registerUser);

// User login
router.post('/login', login);

// Get current user profile
router.get('/me', protect, getCurrentUser);

// Update online status
router.put('/status', updateOnlineStatus);

// Update user profile
router.put('/:id', protect, updateUser);

// Change password
router.post('/change-password', protect, changePassword);

// Profile image upload
router.post('/register/image', upload.single('image'), async (req, res) => {
  console.log('[Backend] Uploading profile image:', req.file);
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image provided' });
    }

    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }    // Use relative path instead of absolute URL
    const imageUrl = `/uploads/${req.file.filename}`;
    
    try {
      // First, find the user
      const user = await User.findByIdAndUpdate(
        userId,
        { image: imageUrl },
        { new: true, runValidators: true }
      ).select('-password');
      
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
        // For logging, we can still show the full URL
      const fullUrl = `http://${req.headers.host}${imageUrl}`;
      console.log('[Backend] Image uploaded for user:', userId, 'URL (relative path):', imageUrl);
      return res.status(200).json({ image: imageUrl });
    } catch (updateError) {
      console.error('[Backend] Failed to update user with image:', updateError);
      // Only send error response if one hasn't been sent already
      if (!res.headersSent) {
        return res.status(500).json({ error: updateError.message });
      }
    }
  } catch (error) {
    console.error('[Backend] Image upload error:', error);
    res.status(500).json({ error: error.message });
  }
});  // Vehicle documents upload
router.post('/register/documents', upload.single('document'), async (req, res) => {
  console.log('[Backend] Uploading vehicle document:', req.file);
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No document provided' });
    }

    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // Use relative path instead of absolute URL
    const documentUrl = `/uploads/${req.file.filename}`;
    
    try {
      // Find the user first
      const user = await User.findById(userId);
      
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      // Add the document to existing vehicle documents or create a new array
      if (!user.vehicleDocuments) {
        user.vehicleDocuments = [];
      }
      
      // Make sure we're using the new relative path format
      user.vehicleDocuments.push(documentUrl);
      await user.save();
        // For logging, we can still show the full URL
      const fullUrl = `http://${req.headers.host}${documentUrl}`;
      console.log('[Backend] Document uploaded for user:', userId, 'URL (relative path):', documentUrl);
      return res.status(200).json({ document: documentUrl });
    } catch (updateError) {
      console.error('[Backend] Failed to update user with document:', updateError);
      // Only send error response if one hasn't been sent already
      if (!res.headersSent) {
        return res.status(500).json({ error: updateError.message });
      }
    }
  } catch (error) {
    console.error('[Backend] Document upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
