import mongoose from 'mongoose';

const restaurantSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  images: {
    type: [String], // Array of image URLs
    default: []
  },
  description: {
    type: String,
    required: true
  },
  address: {
    type: String,
    required: true
  },
  contact: {
    type: String,
    required: true
  },
  workingHours: {
    type: String,
    required: true
  },
  cuisine: {
    type: String,
    required: true
  },
  latitude: {
    type: Number,
    default: null,
    min: -90,
    max: 90
  },
  longitude: {
    type: Number,
    default: null,
    min: -180,
    max: 180
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  ratings: {
    type: [
      {
        clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        rating: { type: Number, min: 1, max: 5 }
      }
    ],
    default: []
  },
  imageUrl: String,
  openingHours: {
    open: String,
    close: String
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

const Restaurant = mongoose.model('Restaurant', restaurantSchema);

export default Restaurant;