import express from 'express';
const router = express.Router();

// Simple health check endpoint
router.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Server is running', timestamp: new Date().toISOString() });
});

export default router;
