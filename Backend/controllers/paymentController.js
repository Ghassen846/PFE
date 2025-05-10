import Payement from '../models/Payement.js';

// Add payment
export const addPayment = async (req, res) => {
  try {
    const { user, order, cardName, cardNumber, expiry, cvc, amount, status, saveCard } = req.body;
    if (!user || !order || !cardName || !cardNumber || !expiry || !cvc || !amount) {
      return res.status(400).json({ message: 'Missing required payment fields' });
    }
    
    // Check if this should be set as default card
    let isDefault = false;
    if (saveCard) {
      // If this is the first saved card for the user, set it as default
      const existingSavedCards = await Payement.countDocuments({ 
        user, 
        saveCard: true 
      });
      isDefault = existingSavedCards === 0;
    }
    
    const payement = new Payement({
      user,
      order,
      cardName,
      cardNumber,
      expiry,
      cvc,
      amount,
      status: status || 'paid',
      saveCard: saveCard || false,
      isDefault
    });
    
    await payement.save();
    res.status(201).json(payement);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get all payments
export const getPayments = async (req, res) => {
  try {
    const payments = await Payement.find()
      .populate('user', 'firstName name email')
      .populate('order');
    res.json(payments);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get payment by ID
export const getPaymentById = async (req, res) => {
  try {
    const payment = await Payement.findById(req.params.id)
      .populate('user', 'firstName name email')
      .populate('order');
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    res.json(payment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update payment
export const updatePayment = async (req, res) => {
  try {
    const payment = await Payement.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    res.json(payment);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Delete payment
export const deletePayment = async (req, res) => {
  try {
    const payment = await Payement.findByIdAndDelete(req.params.id);
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }
    res.json({ message: 'Payment deleted successfully', payment });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get saved cards for a user
export const getSavedCards = async (req, res) => {
  try {
    const userId = req.params.userId;
    const savedCards = await Payement.find({ 
      user: userId, 
      saveCard: true 
    }).select('cardName expiry isDefault maskedCardNumber createdAt');
    
    res.json(savedCards);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Set a card as default
export const setDefaultCard = async (req, res) => {
  try {
    const cardId = req.params.id;
    const userId = req.body.userId;
    
    // First, unset any existing default cards
    await Payement.updateMany(
      { user: userId, isDefault: true },
      { isDefault: false }
    );
    
    // Then set the specified card as default
    const card = await Payement.findOneAndUpdate(
      { _id: cardId, user: userId },
      { isDefault: true },
      { new: true }
    );
    
    if (!card) {
      return res.status(404).json({ message: 'Card not found' });
    }
    
    res.json(card);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};