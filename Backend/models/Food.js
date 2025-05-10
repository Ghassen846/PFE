import mongoose from 'mongoose';

const foodSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: String,
  category: {
    type: String,
    required: true,
    default: 'Other'
  },
  calories: {
    type: Number,
    default: 0
  },
  ingredients: {
    type: [String],
    default: []
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  restaurant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Restaurant',
    required: true
  },
  restaurantDetails: {
    name: { type: String, required: true },
    address: { type: String, required: true },
    contact: { type: String, required: true }
  },
  imageUrl: String,
  isAvailable: {
    type: Boolean,
    default: true
  },
  ratings: {
    type: [
      {
        clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        rating: { type: Number, min: 1, max: 5 }
      }
    ],
    default: []
  }
}, {
  timestamps: true
});

const Food = mongoose.model('Food', foodSchema);

export default Food;
