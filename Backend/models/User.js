import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    unique: true,
    trim: true,
    required: [true, 'Username is required'],
  },
  firstName: {
    type: String,
    trim: true,
    required: [true, 'First name is required'],
  },
  name: {
    type: String,
    trim: true,
    required: [true, 'Last name is required'],
  },
  email: {
    type: String,
    unique: true,
    trim: true,
    lowercase: true,
    required: [true, 'Email is required'],
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
  },
  image: {
    type: String,
    default: '', // URL of profile image
  },
  verified: {
    type: Boolean,
    default: false,
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    validate: {
      validator: function (v) {
        // Align with frontend's Tunisian phone regex: (+216) or starts with 2,4,5,9 followed by 7 digits
        return /^(\+216)?[2459][0-9]{7}$/.test(v);
      },
      message: props => `${props.value} is not a valid Tunisian phone number!`,
    },
  },
  location: {
    latitude: {
      type: Number,
      default: 0,
    },
    longitude: {
      type: Number,
      default: 0,
    },
  },
  role: {
    type: String,
    enum: ['client', 'livreur', 'admin'],
    default: 'livreur',
  },
  vehiculetype: {
    type: String,
    required: function () {
      return this.role === 'livreur';
    },
  },
  vehicleDocuments: {
    type: [String], // Array of document URLs
    default: [],
  },
  status: {
    type: String,
    enum: ['available', 'unavailable'],
    default: 'unavailable',
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  lastActive: {
    type: Date,
    default: Date.now,
  },
  ratings: {
    type: [
      {
        clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        rating: { type: Number, min: 1, max: 5 },
      },
    ],
    default: [],
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
    fuelType: String,
  },
  livreurStats: {
    deliveriesCompleted: { type: Number, default: 0 },
    deliveriesThisMonth: { type: Number, default: 0 },
    averageTime: String,
    monthlyEarnings: String,
    successRate: String,
    rating: { type: Number, default: 0 },
  },
}, {
  timestamps: true,
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Method to compare password
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Indexes for efficient queries
userSchema.index({ username: 1 });
userSchema.index({ email: 1 });

const User = mongoose.model('User', userSchema);

export default User;