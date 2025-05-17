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
      .populate('livreur', 'name firstName phone')
      .populate('restaurant', 'name locationName address cuisine')
      .populate('items.food', 'name price imageUrl');
      
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Convert order to plain object
    const orderData = order.toObject();
    
    try {
      // Try to get delivery in a separate try-catch to prevent overall failure
      const delivery = await mongoose.model('Delivery').findOne({ order: order._id })
        .populate('driver', 'name firstName phone');
        
      // Attach delivery to order if found
      if (delivery) {
        orderData.delivery = delivery.toObject();
      }
    } catch (deliveryError) {
      // Log delivery fetch error but continue
      console.error('Error fetching delivery:', deliveryError);
    }
    
    res.json(orderData);
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

    // Fetch restaurant info for name and coordinates
    const Restaurant = mongoose.model('Restaurant');
    const restaurantDoc = await Restaurant.findById(restaurant);
    let restaurantName = undefined;
    let restaurantLatitude = undefined;
    let restaurantLongitude = undefined;
    if (restaurantDoc) {
      restaurantName = restaurantDoc.name;
      restaurantLatitude = restaurantDoc.latitude;
      restaurantLongitude = restaurantDoc.longitude;
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
      serviceMethod,
      restaurantName,
      restaurantLatitude,
      restaurantLongitude
    });

    await order.save();
    res.status(201).json(order);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Update order status
export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { livreur, status } = req.body; // Allow updating livreur and status
    
    // Validate the order ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }
    
    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Handle different status update scenarios
    if (status === 'livring' && order.status === 'pending_livreur_acceptance') {
      // Livreur accepted the order - update delivery status too
      await Delivery.findOneAndUpdate(
        { order: id },
        { status: 'picked_up' },
        { new: true }
      );
      
      // Notify admin about acceptance
      try {
        const io = req.app.get('socketio');
        if (io) {
          io.to('admin').emit('order_accepted', { 
            orderId: id, 
            message: `Order #${id} has been accepted by the livreur` 
          });
        }
      } catch (socketError) {
        console.error('Socket notification error:', socketError);
      }
    } 
    else if (status === 'pending' && order.status === 'pending_livreur_acceptance') {
      // Livreur rejected the order - reset livreur assignment
      const previousLivreur = order.livreur;
      order.livreur = null; // Remove livreur assignment
      
      // Delete the associated delivery
      await Delivery.findOneAndDelete({ order: id });
      
      // Notify admin about rejection
      try {
        const io = req.app.get('socketio');
        if (io) {
          io.to('admin').emit('order_rejected', { 
            orderId: id, 
            previousLivreur,
            message: `Order #${id} has been rejected by the livreur` 
          });
        }
      } catch (socketError) {
        console.error('Socket notification error:', socketError);
      }
    }
    
    // Update order with new status and livreur (if provided)
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
    const { orderId, livreurId } = req.body;
    
    const Order = (await import('../models/Order.js')).default;
    const User = (await import('../models/User.js')).default;
    const Delivery = (await import('../models/Delivery.js')).default;
    
    // Validate livreur
    const livreur = await User.findById(livreurId);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(400).json({ error: 'Invalid livreur' });
    }
    
    // Update order
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    order.livreur = livreurId;
    order.status = 'livring'; // Or 'assigned' if adding to Delivery model
    await order.save();
    
    // Create or update Delivery document
    let delivery = await Delivery.findOne({ order: orderId });
    if (!delivery) {
      delivery = new Delivery({
        order: orderId,
        driver: livreurId,
        client: order.user,
        status: 'pending', // Or 'assigned' if added
        currentLocation: {
          latitude: order.latitude,
          longitude: order.longitude,
          address: 'Starting location'
        }
      });
      await delivery.save();
    }
    
    res.status(200).json({ message: 'Livreur assigned and delivery created', order, delivery });
  } catch (error) {
    console.error('Error assigning livreur:', error);
    res.status(500).json({ error: error.message });
  }
};

// Get orders by user ID
export const getOrdersByUserId = async (req, res) => {
  try {
    const { userId } = req.params;
    
    // First fetch orders with basic population
    const orders = await Order.find({ user: userId })
      .populate('user', 'name email')
      .populate('livreur', 'name firstName phone')
      .populate('restaurant', 'name locationName cuisine latitude longitude avgCookingTime')
      .populate('items.food', 'name price imageUrl');
    
    // Convert orders to plain objects
    const ordersData = orders.map(order => order.toObject());
    
    try {
      // Try to get deliveries in a separate try-catch to prevent overall failure
      const orderIds = orders.map(order => order._id);
      
      if (orderIds.length > 0) {
        // Only query if we have orders
        const deliveries = await mongoose.model('Delivery').find({ order: { $in: orderIds } })
          .populate('driver', 'name firstName phone');
          
        // Attach deliveries to orders
        for (const delivery of deliveries) {
          if (delivery.order) {
            const orderId = delivery.order.toString();
            const orderIndex = ordersData.findIndex(o => o._id.toString() === orderId);
            
            if (orderIndex !== -1) {
              ordersData[orderIndex].delivery = delivery.toObject();
            }
          }
        }
      }
    } catch (deliveryError) {
      // Log delivery fetch error but continue
      console.error('Error fetching deliveries:', deliveryError);
    }
    
    res.json(ordersData);
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
    await order.save();    // Create delivery
    const delivery = new Delivery({
      order: orderId,
      driver: livreurId,
      client: order.user, // Add client reference
      status: 'pending',
      deliveredAt: null,
      restaurantName: order.restaurantName,
      restaurantLatitude: order.restaurantLatitude,
      restaurantLongitude: order.restaurantLongitude,
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
    const { livreur, ...orderData } = req.body;

    // Validate the order ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    // Prepare the update data
    const updateData = {
      ...orderData,
      ...(livreur && { livreur }), // Include livreur if provided
    };

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

// Cancel order by client
export const cancelOrderByClient = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user ? req.user._id : null;
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    const order = await Order.findById(id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    if (String(order.user) !== String(userId)) {
      return res.status(403).json({ message: 'You can only cancel your own orders' });
    }
    if (['cancelled', 'delivered', 'completed'].includes(order.status)) {
      return res.status(400).json({ message: 'Order cannot be cancelled' });
    }
    order.status = 'cancelled';
    await order.save();
    return res.json({ message: 'Order cancelled successfully', order });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// Get orders assigned to a specific livreur
export const getOrdersByLivreur = async (req, res) => {
  try {
    // Get livreur ID from query, headers, params, or authenticated user
    const livreurId = req.query.userId || req.query.livreurId || req.headers.userid || req.params.livreurId || (req.user ? req.user._id : null);
    
    console.log(`Fetching orders for livreur: ${livreurId}`);
    console.log(`Request params:`, req.params);
    console.log(`Request query:`, req.query);
    console.log(`Request headers:`, req.headers);
    
    if (!livreurId) {
      return res.status(400).json({ message: 'Livreur ID is required' });
    }
    
    // Find orders assigned to this livreur
    const orders = await Order.find({ livreur: livreurId })
      .populate('user', 'name firstName email phone')
      .populate('restaurant', 'name address cuisine latitude longitude avgCookingTime')
      .populate('items.food', 'name price imageUrl');
    
    console.log(`Found ${orders.length} orders for livreur ${livreurId}`);
    
    // Transform orders into the format expected by the Flutter app
    const formattedOrders = orders.map(order => {
      const formattedOrder = {
        _id: order._id.toString(),
        orderId: order._id.toString(),
        order: order.reference || 'Order', // Use reference or default
        validationCode: order.validationCode || '0000',
        customerName: order.user ? `${order.user.firstName || ''} ${order.user.name || ''}`.trim() : 'Unknown Customer',
        status: order.status || 'pending',
        pickupLocation: order.restaurant ? order.restaurant.name || 'Unknown Location' : 'Unknown Location',
        customerPhone: order.user ? order.user.phone || 'No Phone' : 'No Phone',
        deliveryAddress: order.deliveryAddress || 'No Address',
        deliveryDate: order.updatedAt ? new Date(order.updatedAt).toISOString() : new Date().toISOString(),
        deliveryMan: 'Current Driver',
        createdAt: order.createdAt ? new Date(order.createdAt).toISOString() : new Date().toISOString(),
        updatedAt: order.updatedAt ? new Date(order.updatedAt).toISOString() : new Date().toISOString(),
        orderRef: order.reference || `ORD-${Math.floor(Math.random() * 10000)}`
      };
      return formattedOrder;
    });
    
    // Format the response to match the Flutter app's expectations
    // If this is the /delivery/current endpoint (check by path)
    if (req.originalUrl.includes('/delivery/current')) {
      return res.json({ orders: formattedOrders });
    }
    
    return res.json(formattedOrders);
  } catch (err) {
    console.error('Error in getOrdersByLivreur:', err);
    return res.status(500).json({ message: err.message });
  }
};
