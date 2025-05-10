import mongoose from 'mongoose';

const payementSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  cardName: { type: String, required: true },
  cardNumber: { type: String, required: true },
  expiry: { type: String, required: true },
  cvc: { type: String, required: true },
  amount: { type: Number, required: true },
  status: { type: String, enum: ['pending', 'paid', 'failed'], default: 'paid' },
  createdAt: { type: Date, default: Date.now },
  saveCard: { type: Boolean, default: false }, // Flag to indicate if card should be saved
  isDefault: { type: Boolean, default: false } // Flag to indicate if this is the default card
});

// Create a virtual property to mask the card number
payementSchema.virtual('maskedCardNumber').get(function() {
  if (!this.cardNumber) return '';
  const lastFour = this.cardNumber.slice(-4);
  return `**** **** **** ${lastFour}`;
});

const Payement = mongoose.model('Payement', payementSchema);

export default Payement;
