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
  restaurantLatitude: {
    type: Number,
    default: 36.8065
  },
  restaurantLongitude: {
    type: Number,
    default: 10.1815
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
    type: Number,
    min: 0
  },
  subtotal: {
    type: Number,
    min: 0
  },
  deliveryFee: {
    type: Number,
    default: 3,
    min: 0
  },
  status: {
    type: String,
    enum: ['pending', 'livring', 'completed', 'cancelled'],
    default: 'pending'
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
  reference: {
    type: Number,
    required: true,
    unique: true
  },
  phone: {
    type: String,
    required: true
  },
  latitude: {
    type: Number,
    required: true,
    validate: {
      validator: function(v) {
        return v >= -90 && v <= 90;
      },
      message: props => `${props.value} is not a valid latitude! Must be between -90 and 90.`
    }
  },
  longitude: {
    type: Number,
    required: true,
    validate: {
      validator: function(v) {
        return v >= -180 && v <= 180;
      },
      message: props => `${props.value} is not a valid longitude! Must be between -180 and 180.`
    }
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

orderSchema.post('save', async function (doc, next) {
  try {
    if (doc.livreur && this.isModified('livreur')) {
      const Delivery = mongoose.model('Delivery');
      const existingDelivery = await Delivery.findOne({ order: doc._id });
      
      if (!existingDelivery) {
        const delivery = new Delivery({
          order: doc._id,
          driver: doc.livreur,
          client: doc.user,
          status: 'pending',
          currentLocation: {
            latitude: doc.latitude,
            longitude: doc.longitude,
            address: 'Order location'
          }
        });
        await delivery.save();
        console.log(`Created delivery for order ${doc._id}`);
      }
    }
    next();
  } catch (error) {
    console.error('Error creating delivery:', error);
    next(error);
  }
});

const Order = mongoose.model('Order', orderSchema);

export default Order;
