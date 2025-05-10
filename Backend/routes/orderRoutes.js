import express from 'express';
import { createOrder, getOrders, getOrderById, updateOrderStatus, assignLivreur, getOrdersByUserId, assignLivreurToOrder, updateOrder, deleteOrder } from '../controllers/orderController.js';
import { getDeliveriesByLivreur } from '../controllers/deliveryController.js';

const router = express.Router();

router.post('/add', createOrder); // Add a new order
router.get('/', getOrders); // Get all orders
router.get('/get', getOrders); // Get all orders (alternative endpoint)
router.get('/get/:id', getOrderById); // Get order by ID (alternative endpoint)
router.get('/livreur', getDeliveriesByLivreur); // Get deliveries by livreur
router.get('/:id', getOrderById); // Get order by ID
router.patch('/:id/status', updateOrderStatus); // Update order status
router.patch('/:id/assign-livreur', assignLivreur); // Updated to include delivery creation
router.get('/user/:userId', getOrdersByUserId); // Get orders by user ID
router.post('/assign-livreur', assignLivreurToOrder); // Assign livreur to an order and create delivery
router.put('/update/:id', updateOrder); // Update an order
router.delete('/delete/:id', deleteOrder); // Delete an order

export default router;
