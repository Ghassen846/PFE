import Order from '../models/Order.js';
import Food from '../models/Food.js';
import Delivery from '../models/Delivery.js'; // Import the Delivery model
import mongoose from 'mongoose';
import User from '../models/User.js';

// Get all orders
export const getOrders = async (req, res) => {
  try {
    const orders = await Order.find()
      .populate('user', 'username firstName name email phone') // Add more fields as needed
      .populate('restaurant', 'name address cuisine')
      .populate('items.food', 'name price imageUrl');

    if (!orders || orders.length === 0) {
      console.error("No orders found.");
      return res.status(404).json({ message: "No orders found" });
    }

    res.json(orders);
  } catch (err) {
    console.error("Error fetching orders:", err.message);
    res.status(500).json({ message: "Error fetching orders" });
  }
};

// Get order by ID
export const getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('user', 'username firstName name email phone')
      .populate('restaurant', 'name address cuisine')
      .populate('items.food', 'name price imageUrl');
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    res.json(order);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

/**
 * Create a new order and calculate total price.
 * @param {Request} req
 * @param {Response} res
 */
export const createOrder = async (req, res) => {
  try {
    const { 
      user, 
      restaurant, 
      items, 
      phone, 
      latitude, 
      longitude, 
      cookingTime, 
      reference,
      paymentMethod,
      serviceMethod 
    } = req.body;

    // Validate required fields
    if (!user || !restaurant || !items || !phone || latitude === undefined || longitude === undefined || !cookingTime || !reference) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Create new order
    const order = new Order({
      user,
      restaurant,
      items,
      phone,
      latitude,
      longitude,
      cookingTime,
      reference,
      paymentMethod,
      serviceMethod
    });

    // Fetch and add restaurant details
    try {
      const Restaurant = (await import('../models/Restaurant.js')).default;
      const restaurantDoc = await Restaurant.findById(restaurant);
      if (restaurantDoc) {
        order.restaurantName = restaurantDoc.name;
        order.restaurantLocation = {
          latitude: restaurantDoc.latitude || null,
          longitude: restaurantDoc.longitude || null
        };
        console.log(`Adding restaurant coordinates: ${restaurantDoc.latitude}, ${restaurantDoc.longitude}`);
      }
    } catch (restaurantError) {
      console.error('Error fetching restaurant details:', restaurantError);
    }

    // Check if restaurant location exists
    if (!order.restaurantLocation) {
      order.restaurantLocation = {
        latitude: 36.8065, // Default to Tunisia
        longitude: 10.1815
      };
    }
    
    // Validate restaurant coordinates - ensure they are numeric and reasonable
    const validLat = typeof order.restaurantLocation.latitude === 'number' && 
      !isNaN(order.restaurantLocation.latitude) &&
      order.restaurantLocation.latitude >= -90 && 
      order.restaurantLocation.latitude <= 90;
      
    const validLng = typeof order.restaurantLocation.longitude === 'number' && 
      !isNaN(order.restaurantLocation.longitude) &&
      order.restaurantLocation.longitude >= -180 && 
      order.restaurantLocation.longitude <= 180;
    
    // If either coordinate is invalid, use defaults
    if (!validLat || !validLng) {
      console.warn('Invalid restaurant coordinates, using default location');
      order.restaurantLocation = {
        latitude: 36.8065, // Default to Tunisia
        longitude: 10.1815
      };
    }

    await order.save();
    res.status(201).json(order);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Update order status
export const updateOrderStatus = async (req, res) => {
  try {
    const { livreur, status } = req.body; // Allow updating livreur and status
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    if (livreur) {
      order.livreur = livreur; // Assign livreur to the order
    }
    if (status) {
      order.status = status; // Update order status
    }
    await order.save();
    res.json(order);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Assign livreur to an order
export const assignLivreur = async (req, res) => {
  try {
    const { id } = req.params; // Order ID
    const { livreur } = req.body; // Livreur ID

    // Validate IDs
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(livreur)) {
      return res.status(400).json({ message: 'Invalid order or livreur ID' });
    }

    // Check livreur existence and role
    const livreurUser = await User.findById(livreur);
    if (!livreurUser || livreurUser.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found or invalid role' });
    }

    // Find the order
    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Prevent duplicate delivery
    const existingDelivery = await Delivery.findOne({ order: id });
    if (existingDelivery) {
      return res.status(409).json({ message: 'Delivery already exists for this order' });
    }

    // Assign the livreur to the order
    order.livreur = livreur;
    await order.save();

    // Create a new delivery entry
    const delivery = new Delivery({
      order: id,
      driver: livreur,
      client: order.user,
      status: 'pending',
    });
    await delivery.save();

    res.status(200).json({ message: 'Livreur assigned successfully and delivery created', order, delivery });
  } catch (err) {
    res.status(500).json({ message: 'Error assigning livreur', error: err.message });
  }
};

// Get orders by user ID
export const getOrdersByUserId = async (req, res) => {
  try {
    const { userId } = req.params;
    const orders = await Order.find({ user: userId })
      .populate('user', 'name email')
      .populate('restaurant', 'name location')
      .populate('items.food', 'name price');
    res.json(orders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Assign livreur to an order and save to delivery collection
export const assignLivreurToOrder = async (req, res) => {
  try {
    const { orderId, livreurId } = req.body;

    // Validate IDs
    if (!orderId || !livreurId) {
      return res.status(400).json({ message: 'orderId and livreurId are required' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    const livreur = await User.findById(livreurId);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found or invalid role' });
    }

    // Assign livreur to order and update status
    order.livreur = livreurId;
    order.status = 'livring';
    await order.save();

    // Create delivery
    const delivery = new Delivery({
      order: orderId,
      driver: livreurId,
      client: order.user, // Add client reference
      status: 'pending',
      deliveredAt: null,
    });
    await delivery.save();

    res.status(200).json({ message: 'Livreur assigned, order updated, and delivery created successfully', order, delivery });
  } catch (err) {
    res.status(500).json({ message: 'Error assigning livreur', error: err.message });
  }
};

// Update an order
export const updateOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const { livreur, restaurant, ...orderData } = req.body;

    // Validate the order ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    // Prepare the update data
    const updateData = {
      ...orderData,
      ...(livreur && { livreur }), // Include livreur if provided
    };

    // If restaurant is updated, fetch the restaurant details
    if (restaurant && mongoose.Types.ObjectId.isValid(restaurant)) {
      try {
        const Restaurant = (await import('../models/Restaurant.js')).default;
        const restaurantDoc = await Restaurant.findById(restaurant);
        if (restaurantDoc) {
          updateData.restaurantName = restaurantDoc.name;
          updateData.restaurantLocation = {
            latitude: restaurantDoc.latitude || null,
            longitude: restaurantDoc.longitude || null
          };
          updateData.restaurant = restaurant;
          console.log(`Updating restaurant details: ${restaurantDoc.name}, coords: ${restaurantDoc.latitude}, ${restaurantDoc.longitude}`);
        }
      } catch (restaurantError) {
        console.error('Error fetching updated restaurant details:', restaurantError);
      }
    }

    // Check if restaurant location exists
    if (!updateData.restaurantLocation) {
      updateData.restaurantLocation = {
        latitude: 36.8065, // Default to Tunisia
        longitude: 10.1815
      };
    }
    
    // Validate restaurant coordinates - ensure they are numeric and reasonable
    const validLat = typeof updateData.restaurantLocation.latitude === 'number' && 
      !isNaN(updateData.restaurantLocation.latitude) &&
      updateData.restaurantLocation.latitude >= -90 && 
      updateData.restaurantLocation.latitude <= 90;
      
    const validLng = typeof updateData.restaurantLocation.longitude === 'number' && 
      !isNaN(updateData.restaurantLocation.longitude) &&
      updateData.restaurantLocation.longitude >= -180 && 
      updateData.restaurantLocation.longitude <= 180;
    
    // If either coordinate is invalid, use defaults
    if (!validLat || !validLng) {
      console.warn('Invalid restaurant coordinates in update, using default location');
      updateData.restaurantLocation = {
        latitude: 36.8065, // Default to Tunisia
        longitude: 10.1815
      };
    }

    // Update the order
    const order = await Order.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Delete an order
export const deleteOrder = async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.json({ message: 'Order deleted successfully', order });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
