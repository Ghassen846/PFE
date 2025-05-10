import express from 'express';
import {
  addDeliveryMaintenance,
  createDelivery,
  deleteDelivery,
  getDeliveries,
  getDeliveriesByLivreur,
  getDeliveryById,
  getLivreurLocations,
  updateDelivery,
  updateDeliveryStatus,
  updateLivreurLocation
} from '../controllers/deliveryController.js';

const router = express.Router();

router.post('/', createDelivery); // Create a new delivery
router.get('/', getDeliveries); // Get all deliveries with driver populated and deliveriesCount
router.get('/locations', getLivreurLocations); // Get all livreur locations
router.get('/livreur/:livreurId', getDeliveriesByLivreur); // Get deliveries for a specific livreur
router.get('/livreur', getDeliveriesByLivreur); // Optionally support /livreur?livreurId=...
router.get('/:id', getDeliveryById); // Get delivery by ID
router.put('/:id', updateDelivery); // Update delivery
router.patch('/:id/status', updateDeliveryStatus); // Update delivery status
router.patch('/location/:livreurId', updateLivreurLocation); // Update livreur's location
router.delete('/:id', deleteDelivery); // Delete delivery
router.post('/:id/maintenance', addDeliveryMaintenance); // Add maintenance to a delivery

export default router;
