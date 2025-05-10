import express from 'express';
import { getSettings, updateSettings } from '../controllers/settingsController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// Both routes need the protect middleware to identify the current user
router.get('/', protect, getSettings);
router.post('/', protect, updateSettings);

export default router;