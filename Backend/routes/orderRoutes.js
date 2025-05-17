import express from 'express';
import { createOrder, getOrders, getOrderById, updateOrderStatus, assignLivreur, getOrdersByUserId, assignLivreurToOrder, updateOrder, deleteOrder, cancelOrderByClient, getOrdersByLivreur } from '../controllers/orderController.js';
import { getDeliveriesByLivreur } from '../controllers/deliveryController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

router.post('/add', protect, createOrder); // Add a new order
router.get('/', protect, getOrders); // Get all orders
router.get('/get', protect, getOrders); // Get all orders (alternative endpoint)
router.get('/get/:id', protect, getOrderById); // Get order by ID (alternative endpoint)
router.get('/livreur', protect, getOrdersByLivreur); // Get orders assigned to a livreur
router.get('/delivery/current', protect, getOrdersByLivreur); // Get current orders for delivery person (alias for getOrdersByLivreur)
router.get('/:id', protect, getOrderById); // Get order by ID
router.patch('/:id/status', protect, updateOrderStatus); // Update order status
router.patch('/:id/assign-livreur', protect, assignLivreur); // Updated to include delivery creation
router.get('/user/:userId', protect, getOrdersByUserId); // Get orders by user ID
router.post('/assign-livreur', protect, assignLivreurToOrder); // Assign livreur to an order and create delivery
router.put('/update/:id', protect, updateOrder); // Update an order
router.delete('/delete/:id', protect, deleteOrder); // Delete an order
router.patch('/cancel/:id', protect, cancelOrderByClient); // Client cancels their order (protected)

router.get('/user', protect, async (req, res) => {
  try {
    const userId = req.user._id;
    console.log(`Fetching orders for user: ${userId}`);
    
    // Import models
    const { default: Order } = await import('../models/Order.js');
    
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
      const { default: Delivery } = await import('../models/Delivery.js');
      const orderIds = orders.map(order => order._id);
      
      if (orderIds.length > 0) {
        // Only query if we have orders
        const deliveries = await Delivery.find({ order: { $in: orderIds } })
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
    
    // Send the response 
    console.log(`Found ${orders.length} orders for user ${userId}`);
    res.json(ordersData);
  } catch (err) {
    console.error('Error fetching orders by user ID:', err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
