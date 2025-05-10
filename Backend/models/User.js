import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    unique: true,
    trim: true
  },
  firstName: {
    type: String,
    trim: true
  },
  name: {
    type: String,
    trim: true
  },
  email: {
    type: String,
    unique: true,
    trim: true,
    lowercase: true
  },
  password: {
    type: String,
  },
  image: {
    type: String,
    default: ''
  },
  verified: {
    type: Boolean,
    default: false
  },
  phone: {
    type: String, // Use String to handle phone numbers with country codes
    required: [true, 'Phone number is required'], // Ensure phone is required
    validate: {
      validator: function (v) {
        // Validate phone number format (e.g., international format with +)
        return /^(\+?\d{1,3})?[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}$/.test(v);
      },
      message: props => `${props.value} is not a valid phone number!`
    }
  },
  location: {
    latitude: {
      type: Number,
      required: [false, 'Latitude is required'],
      default: 0
    },
    longitude: {
      type: Number,
      required: [false, 'Longitude is required'],
      default: 0
    },
  },
  role: {
    type: String,
    enum: ['client', 'livreur', 'admin'],
    default: 'client' // Default role is client
  },
  vehiculetype: {
    type: String,
    required: function () {
      return this.role === 'livreur'; // Required only for livreur
    }
  },
  vehiculedocuments: {
    type: [String], // Array of strings for document URLs or names
    // required: function () {
    //   return this.role === 'livreur'; // Commented out to avoid registration errors
    // }
  },
  status: {
    type: String,
    enum: ['available', 'unavailable'], // Example statuses
    required: function () {
      return this.role === 'livreur'; // Required only for livreur
    }
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
  vehicle: {
    make: String,
    model: String,
    year: String,
    licensePlate: String,
    color: String,
    insuranceExpiry: Date,
    lastMaintenance: Date,
    nextMaintenance: Date,
    mileage: String,
    fuelType: String
  },
  livreurStats: {
    deliveriesCompleted: { type: Number, default: 0 },
    deliveriesThisMonth: { type: Number, default: 0 },
    averageTime: String,
    monthlyEarnings: String,
    successRate: String,
    rating: { type: Number, default: 0 }
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10); // Hash the password
  next();
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

const User = mongoose.model('User', userSchema);

export default User;