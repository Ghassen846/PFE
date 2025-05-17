import express from 'express';
import {
  addDeliveryMaintenance,
  createDelivery,
  deleteDelivery,
  getDeliveries,
  getDeliveriesByLivreur,
  getDeliveriesByClient,
  getDeliveryById,
  updateDelivery,
  updateDeliveryStatus,
  updateLivreurLocation,
  getLivreurLocation,
  getAllLivreurLocations,
  rateDelivery,
  getDeliveriesByStatus, // New controller
  getCollectedDeliveries, // New controller
  getEarningsDeliveries, // New controller
  getMockDeliveryOrders, // New controller for testing
  getDeliveryStats // Stats controller for mobile app
} from '../controllers/deliveryController.js';

import { protect, admin, livreur } from '../middleware/auth.js';
import Delivery from '../models/Delivery.js';

const router = express.Router();

// Add these new routes for flutter mobile app
router.get('/by-status', protect, getDeliveriesByStatus); // Get deliveries filtered by status
router.get('/list', protect, getDeliveriesByStatus); // Alias for /by-status to match Flutter app's endpoint
router.get('/collected', protect, getCollectedDeliveries); // Get completed deliveries with payment collected
router.get('/payments', protect, getCollectedDeliveries); // Alias for /collected to match Flutter app's endpoint
router.get('/earnings', protect, getEarningsDeliveries); // Get earnings information
router.get('/mock-delivery-orders', getMockDeliveryOrders); // Get mock data for testing (no protection for testing)
router.get('/stats', getDeliveryStats); // Get delivery stats for a driver (no protection as it's used in the server.js direct route)

router.post('/', protect, createDelivery); // Create a new delivery
router.get('/', protect, getDeliveries); // Get all deliveries with driver populated and deliveriesCount
router.get('/livreur/:livreurId', protect, getDeliveriesByLivreur); // Get deliveries for a specific livreur
router.get('/livreur', protect, getDeliveriesByLivreur); // Optionally support /livreur?livreurId=...
router.get('/locations', protect, getAllLivreurLocations); // Get all livreur locations
router.get('/livreur/:livreurId/location', protect, getLivreurLocation); // Get specific livreur's location
router.get('/:id', protect, getDeliveryById); // Get delivery by ID
router.put('/:id', protect, updateDelivery); // Update delivery
router.patch('/:id/status', protect, updateDeliveryStatus); // Update delivery status
router.patch('/location/:livreurId', protect, updateLivreurLocation); // Update livreur's location
router.delete('/:id', protect, deleteDelivery); // Delete delivery
router.post('/:id/maintenance', protect, addDeliveryMaintenance); // Add maintenance to a delivery
router.get('/client/:clientId', protect, getDeliveriesByClient); // Get deliveries for a specific client
router.post('/:id/rate', protect, rateDelivery); // Rate a delivery

// Add a new route to get delivery counts for all livreurs
router.get('/counts', async (req, res) => {
  try {
    // Aggregate to count deliveries by livreur
    const deliveryCounts = await Delivery.aggregate([
      { $group: { _id: "$driver", count: { $sum: 1 } } }
    ]);
    
    // Convert to a more convenient format for the frontend
    const result = {};
    deliveryCounts.forEach(item => {
      if (item._id) { // Ensure driver ID exists
        result[item._id.toString()] = item.count;
      }
    });
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching delivery counts:', error);
    res.status(500).json({ message: 'Error fetching delivery counts', error: error.message });
  }
});

export default router;
