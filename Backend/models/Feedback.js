import mongoose from 'mongoose';

const feedbackSchema = mongoose.Schema(
  {
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: true
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    delivery: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Delivery'
    },
    restaurant: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Restaurant'
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    comment: {
      type: String,
      trim: true
    },
    type: {
      type: String,
      enum: ['restaurant', 'delivery', 'food'],
      default: 'delivery'
    }
  },
  {
    timestamps: true
  }
);

// Prevent duplicate feedback for the same order and type
feedbackSchema.index({ order: 1, type: 1 }, { unique: true });

const Feedback = mongoose.model('Feedback', feedbackSchema);

export default Feedback;