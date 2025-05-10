import mongoose from 'mongoose';

const orderSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  restaurant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Restaurant',
    required: true
  },
  restaurantName: {
    type: String,
    default: 'Unknown Restaurant'
  },
  restaurantLocation: {
    latitude: {
      type: Number,
      default: null
    },
    longitude: {
      type: Number,
      default: null
    }
  },
  items: [
    {
      food: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Food',
        required: true
      },
      quantity: {
        type: Number,
        required: true,
        min: 1
      }
    }
  ],
  totalPrice: {
    type: Number, // Remove `required: true`
    min: 0
  },
  status: {
    type: String,
    enum: ['pending', 'livring', 'completed', 'cancelled'],
    default: 'pending'
  },
  phone: {
    type: String,
    required: true
  },
  latitude: {
    type: Number,
    required: true
  },
  longitude: {
    type: Number,
    required: true
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed'],
    default: 'pending'
  },
  serviceMethod: {
    type: String,
    enum: ['delivery'],
    default: 'delivery'
  },
  paymentMethod: {
    type: String,
    enum: ['credit-card', 'paypal'],
    default: 'credit-card'
  },
  cookingTime: {
    type: Number, // Time in minutes
    required: true
  },
  reference: {
    type: Number,
    required: true
  },
  livreur: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // Reference the User model
    required: false // Optional field, assigned by admin
  }
}, {
  timestamps: true
});

orderSchema.pre('save', async function (next) {
  try {
    const Food = mongoose.model('Food'); // Reference the Food model
    let total = 0;

    for (const item of this.items) {
      const food = await Food.findById(item.food);
      if (food) {
        total += food.price * item.quantity; // Calculate total price
      }
    }

    this.totalPrice = total; // Assign the calculated total to totalPrice
    next();
  } catch (error) {
    next(error);
  }
});

orderSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    // Replace user with name if populated
    if (ret.user && typeof ret.user === 'object' && ret.user.name) {
      ret.user = {
        _id: ret.user._id,
        name: ret.user.name,
        firstName: ret.user.firstName
      };
    }
    // Replace restaurant with name if populated
    if (ret.restaurant && typeof ret.restaurant === 'object' && ret.restaurant.name) {
      ret.restaurant = {
        _id: ret.restaurant._id,
        name: ret.restaurant.name
      };
    }
    // Replace livreur with name if populated
    if (ret.livreur && typeof ret.livreur === 'object' && (ret.livreur.name || ret.livreur.firstName)) {
      ret.livreur = {
        _id: ret.livreur._id,
        name: ret.livreur.name,
        firstName: ret.livreur.firstName
      };
    }
    // Replace items.food with name if populated
    if (Array.isArray(ret.items)) {
      ret.items = ret.items.map(item => {
        if (item.food && typeof item.food === 'object' && item.food.name) {
          return {
            ...item,
            food: {
              _id: item.food._id,
              name: item.food.name
            }
          };
        }
        return item;
      });
    }
    return ret;
  }
});

const Order = mongoose.model('Order', orderSchema);

export default Order;
