import express from 'express';
import { 
  addPayment, 
  getPayments, 
  getPaymentById, 
  updatePayment, 
  deletePayment,
  getSavedCards,
  setDefaultCard
} from '../controllers/paymentController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

router.post('/', addPayment); // Add a new payment
router.post('/add', addPayment); // Alternative endpoint for adding a payment
router.get('/', getPayments); // Get all payments
router.get('/:id', getPaymentById); // Get payment by ID
router.put('/:id', updatePayment); // Update payment
router.delete('/:id', deletePayment); // Delete payment

// New endpoints for saved cards
router.get('/user/:userId/saved-cards', protect, getSavedCards); // Get saved cards for a user
router.put('/cards/:id/default', protect, setDefaultCard); // Set a card as default

export default router;