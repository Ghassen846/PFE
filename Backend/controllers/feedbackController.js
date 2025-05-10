import Feedback from '../models/Feedback.js';
import Order from '../models/Order.js';
import Delivery from '../models/Delivery.js';
import Restaurant from '../models/Restaurant.js';
import mongoose from 'mongoose';

/**
 * Create a new feedback for an order
 * @route   POST /api/feedback
 * @access  Private
 */
export const createFeedback = async (req, res) => {
  try {
    const { orderId, rating, comment, type = 'delivery' } = req.body;
    
    if (!orderId || !rating) {
      return res.status(400).json({ error: 'OrderId and rating are required' });
    }
    
    // Validate rating
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }
    
    // Check if order exists and belongs to the user
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    if (order.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'You can only provide feedback for your own orders' });
    }
    
    // Check if feedback already exists for this order and type
    const existingFeedback = await Feedback.findOne({ order: orderId, type });
    if (existingFeedback) {
      return res.status(400).json({ error: 'You have already provided feedback for this order' });
    }
    
    // Prepare feedback data
    const feedbackData = {
      order: orderId,
      user: req.user._id,
      rating,
      comment,
      type
    };
    
    // Get related entities based on type
    if (type === 'delivery') {
      const delivery = await Delivery.findOne({ order: orderId });
      if (delivery) {
        feedbackData.delivery = delivery._id;
      }
    } else if (type === 'restaurant') {
      feedbackData.restaurant = order.restaurant;
    }
    
    // Create feedback
    const feedback = await Feedback.create(feedbackData);
    
    // Update ratings in the corresponding entity
    if (type === 'delivery' && feedbackData.delivery) {
      await updateDeliveryRating(feedbackData.delivery);
    } else if (type === 'restaurant' && feedbackData.restaurant) {
      await updateRestaurantRating(feedbackData.restaurant);
    }
    
    res.status(201).json(feedback);
  } catch (error) {
    console.error('Error creating feedback:', error);
    res.status(500).json({ error: 'Failed to create feedback' });
  }
};

/**
 * Get feedback for a specific order
 * @route   GET /api/feedback/order/:orderId
 * @access  Private
 */
export const getFeedbackByOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    
    // Check if order exists and belongs to the user
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    // Admin or restaurant can see all feedback, users can only see their own
    if (req.user.role !== 'admin' && req.user.role !== 'restaurant' && 
        order.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'You can only view feedback for your own orders' });
    }
    
    const feedback = await Feedback.find({ order: orderId })
      .populate('user', 'name avatar')
      .populate('delivery', 'driver')
      .populate('restaurant', 'name')
      .sort('-createdAt');
    
    res.json(feedback);
  } catch (error) {
    console.error('Error fetching order feedback:', error);
    res.status(500).json({ error: 'Failed to fetch feedback' });
  }
};

/**
 * Get all feedback for a delivery
 * @route   GET /api/feedback/delivery/:deliveryId
 * @access  Private
 */
export const getFeedbackByDelivery = async (req, res) => {
  try {
    const { deliveryId } = req.params;
    
    // Delivery personnel can only see their own feedback
    if (req.user.role === 'livreur') {
      const delivery = await Delivery.findById(deliveryId);
      if (!delivery || delivery.driver.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'You can only view feedback for your own deliveries' });
      }
    }
    
    const feedback = await Feedback.find({ 
      delivery: deliveryId,
      type: 'delivery'
    })
      .populate('user', 'name avatar')
      .populate('order', 'orderNumber')
      .sort('-createdAt');
    
    res.json(feedback);
  } catch (error) {
    console.error('Error fetching delivery feedback:', error);
    res.status(500).json({ error: 'Failed to fetch feedback' });
  }
};

/**
 * Get all feedback for a restaurant
 * @route   GET /api/feedback/restaurant/:restaurantId
 * @access  Private
 */
export const getFeedbackByRestaurant = async (req, res) => {
  try {
    const { restaurantId } = req.params;
    
    // Restaurant can only see their own feedback
    if (req.user.role === 'restaurant' && req.user.restaurant && 
        req.user.restaurant.toString() !== restaurantId) {
      return res.status(403).json({ error: 'You can only view feedback for your own restaurant' });
    }
    
    const feedback = await Feedback.find({ 
      restaurant: restaurantId,
      type: 'restaurant'
    })
      .populate('user', 'name avatar')
      .populate('order', 'orderNumber')
      .sort('-createdAt');
    
    res.json(feedback);
  } catch (error) {
    console.error('Error fetching restaurant feedback:', error);
    res.status(500).json({ error: 'Failed to fetch feedback' });
  }
};

/**
 * Get all feedback submitted by current user
 * @route   GET /api/feedback/my-feedback
 * @access  Private
 */
export const getUserFeedback = async (req, res) => {
  try {
    const feedback = await Feedback.find({ user: req.user._id })
      .populate('order', 'orderNumber totalPrice createdAt')
      .populate('delivery', 'driver status')
      .populate('restaurant', 'name image')
      .sort('-createdAt');
    
    res.json(feedback);
  } catch (error) {
    console.error('Error fetching user feedback:', error);
    res.status(500).json({ error: 'Failed to fetch feedback' });
  }
};

/**
 * Helper function to update delivery driver rating
 */
const updateDeliveryRating = async (deliveryId) => {
  const feedbacks = await Feedback.find({ delivery: deliveryId, type: 'delivery' });
  
  if (feedbacks.length === 0) return;
  
  const totalRating = feedbacks.reduce((sum, item) => sum + item.rating, 0);
  const averageRating = totalRating / feedbacks.length;
  
  const delivery = await Delivery.findById(deliveryId);
  if (!delivery) return;
  
  // Update driver's rating
  await Delivery.findByIdAndUpdate(deliveryId, { rating: averageRating });
  
  // We could also update the driver's overall rating in the User model if needed
};

/**
 * Helper function to update restaurant rating
 */
const updateRestaurantRating = async (restaurantId) => {
  const feedbacks = await Feedback.find({ restaurant: restaurantId, type: 'restaurant' });
  
  if (feedbacks.length === 0) return;
  
  const totalRating = feedbacks.reduce((sum, item) => sum + item.rating, 0);
  const averageRating = totalRating / feedbacks.length;
  
  // Update restaurant's rating
  await Restaurant.findByIdAndUpdate(restaurantId, { rating: averageRating });
};