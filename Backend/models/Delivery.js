import mongoose from 'mongoose';

const deliverySchema = new mongoose.Schema({
  order: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    required: false, // Make the order field optional
    validate: {
      validator: async function(value) {
        // Skip validation if null or undefined
        if (!value) return true;
        
        // Only validate if there's an actual value
        try {
          const Order = mongoose.model('Order');
          const orderExists = await Order.findById(value);
          return !!orderExists;
        } catch (err) {
          console.error('Order validation error:', err);
          return false;
        }
      },
      message: 'Order must reference a valid Order document.'
    }
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // Reference the User model
    required: true,
    validate: {
      validator: async function (value) {
        const user = await mongoose.model('User').findById(value);
        return user && user.role === 'livreur'; // Ensure the user exists and has the role 'livreur'
      },
      message: 'Driver must be a user with the role "livreur".'
    }
  },
  client: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false // Not required for backward compatibility
  },
  status: {
    type: String,
    enum: ['pending', 'picked_up', 'delivering', 'delivered', 'cancelled'],
    default: 'pending'
  },
  // Add current location tracking
  currentLocation: {
    latitude: {
      type: Number,
      default: null
    },
    longitude: {
      type: Number,
      default: null
    },
    address: {
      type: String,
      default: ''
    },
    updatedAt: {
      type: Date,
      default: Date.now
    }
  },
  // Add location history for tracking movement
  locationHistory: [{
    latitude: Number,
    longitude: Number,
    timestamp: {
      type: Date,
      default: Date.now
    }
  }],
  deliveredAt: Date,
  maintenanceHistory: [{
    date: Date,
    type: String,
    cost: String,
    mileage: String
  }]
}, {
  timestamps: true
});

const Delivery = mongoose.model('Delivery', deliverySchema);

export default Delivery;
