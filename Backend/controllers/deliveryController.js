import mongoose from 'mongoose';
import Delivery from '../models/Delivery.js';
import Order from '../models/Order.js';
import User from '../models/User.js';

// Get all deliveries
export const getDeliveries = async (req, res) => {
  try {
    const deliveries = await Delivery.find()
      .populate({
        path: 'order',
        populate: [
          { path: 'user', select: 'username firstName name email phone' },
          { path: 'restaurant', select: 'name address cuisine' },
          { path: 'items.food', select: 'name price imageUrl' }
        ]
      })
      .populate('driver', 'firstName name email phone vehiculetype status')
      .populate('client', 'firstName name email phone');

    // Count deliveries per driver
    const deliveryCounts = {};
    deliveries.forEach(delivery => {
      const driverId = delivery.driver?._id?.toString();
      if (driverId) {
        deliveryCounts[driverId] = (deliveryCounts[driverId] || 0) + 1;
      }
    });

    // Attach count to each delivery
    const deliveriesWithCount = deliveries.map(delivery => ({
      ...delivery.toObject(),
      deliveriesCount: delivery.driver?._id ? deliveryCounts[delivery.driver._id.toString()] : 0
    }));

    res.json(deliveriesWithCount);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get delivery by ID
export const getDeliveryById = async (req, res) => {
  try {
    const delivery = await Delivery.findById(req.params.id);
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found' });
    }
    res.json(delivery);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a new delivery
export const createDelivery = async (req, res) => {
  try {
    const { orderId, livreurId } = req.body;

    // Validate order and livreur
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    const livreur = await User.findById(livreurId);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found or invalid role' });
    }

    // Create the delivery
    const delivery = new Delivery({
      order: orderId,
      driver: livreurId,
      client: order.user, // Add client reference
      status: 'pending',
    });

    await delivery.save();
    res.status(201).json(delivery);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Update delivery
export const updateDelivery = async (req, res) => {
  const { id } = req.params;
  const { order, driver, status, deliveredAt } = req.body;

  try {
    // Validate the delivery ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid delivery ID' });
    }

    // Validate the order ID if provided
    if (order && !mongoose.Types.ObjectId.isValid(order)) {
      return res.status(400).json({ message: 'Invalid order ID' });
    }

    // Validate the driver ID if provided
    if (driver && !mongoose.Types.ObjectId.isValid(driver)) {
      return res.status(400).json({ message: 'Invalid driver ID' });
    }

    // Update the delivery
    const updatedDelivery = await Delivery.findByIdAndUpdate(
      id,
      { order, driver, status, deliveredAt },
      { new: true, runValidators: true }
    );

    if (!updatedDelivery) {
      return res.status(404).json({ message: 'Delivery not found' });
    }

    res.json(updatedDelivery);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update delivery status
export const updateDeliveryStatus = async (req, res) => {
  try {
    const delivery = await Delivery.findById(req.params.id);
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found' });
    }
    delivery.status = req.body.status;
    // Set deliveredAt if status is 'delivered'
    if (req.body.status === 'delivered') {
      delivery.deliveredAt = new Date();
    }
    await delivery.save();
    res.json(delivery);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Delete delivery
export const deleteDelivery = async (req, res) => {
  try {
    const delivery = await Delivery.findByIdAndDelete(req.params.id);
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found' });
    }
    res.json({ message: 'Delivery deleted successfully', delivery });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Add maintenance to a delivery
export const addDeliveryMaintenance = async (req, res) => {
  try {
    const { id } = req.params;
    const { maintenance } = req.body;
    const delivery = await Delivery.findById(id);
    if (!delivery) return res.status(404).json({ message: 'Delivery not found' });
    if (!delivery.maintenanceHistory) delivery.maintenanceHistory = [];
    delivery.maintenanceHistory.push(maintenance);
    await delivery.save();
    res.json(delivery);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Get deliveries assigned to a specific livreur
export const getDeliveriesByLivreur = async (req, res) => {
  try {
    // Get livreur ID from query params, route params, or the authenticated user
    const livreurId = req.query.livreurId || req.params.livreurId || req.headers.userid || (req.user ? req.user._id : null);

    // Check if we have a valid livreurId to use
    if (!livreurId) {
      console.log('Missing livreur ID in request:', {
        query: req.query,
        params: req.params,
        headers: req.headers,
        user: req.user ? req.user._id : 'No authenticated user'
      });
      return res.status(400).json({ message: 'Livreur ID is required' });
    }

    // Log the livreurId we're using for debugging
    console.log(`Fetching deliveries for livreur ID: ${livreurId}`);

    // Find orders where this livreur is assigned
    const orders = await Order.find({ livreur: livreurId })
      .populate('user', 'username firstName name email phone')
      .populate('restaurant', 'name address cuisine latitude longitude')
      .populate('items.food', 'name price imageUrl');

    console.log(`Found ${orders.length} orders for livreurId: ${livreurId}`);
    
    res.json(orders);
  } catch (err) {
    console.error('Error in getDeliveriesByLivreur:', err);
    res.status(500).json({ message: err.message });
  }
};

// Update livreur's location
export const updateLivreurLocation = async (req, res) => {
  try {
    const { livreurId } = req.params;
    const { latitude, longitude, address } = req.body;
    
    // Validate input
    if (!livreurId || !mongoose.Types.ObjectId.isValid(livreurId)) {
      return res.status(400).json({ message: 'Valid livreur ID is required' });
    }
    
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }
    
    // Parse coordinates to ensure they're numbers
    const parsedLatitude = parseFloat(latitude);
    const parsedLongitude = parseFloat(longitude);
    
    if (isNaN(parsedLatitude) || isNaN(parsedLongitude)) {
      return res.status(400).json({ message: 'Latitude and longitude must be valid numbers' });
    }
    
    // Check if livreur exists
    const livreur = await User.findById(livreurId);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found or invalid role' });
    }
    
    console.log(`Updating location for livreur ${livreurId}: ${parsedLatitude}, ${parsedLongitude}`);
    
    // Find active deliveries for this livreur that have a valid order reference
    const activeDeliveries = await Delivery.find({
      driver: livreurId,
      status: { $in: ['pending', 'picked_up', 'delivering'] }
    });
    
    console.log(`Found ${activeDeliveries.length} active deliveries for livreur ${livreurId}`);
    
    // No active deliveries found, create a new one for location tracking only
    if (activeDeliveries.length === 0) {
      console.log('No active deliveries found, creating location-only entry');
      
      const newLocationTracking = new Delivery({
        driver: livreurId,
        order: undefined, // Explicitly undefined to prevent validation issues
        status: 'pending',
        currentLocation: {
          latitude: parsedLatitude,
          longitude: parsedLongitude,
          address: address || '',
          updatedAt: new Date()
        },
        locationHistory: [{
          latitude: parsedLatitude,
          longitude: parsedLongitude,
          timestamp: new Date()
        }]
      });
      
      try {
        await newLocationTracking.save();
        return res.status(201).json({ 
          message: 'Created new location tracking entry',
          delivery: newLocationTracking 
        });
      } catch (saveError) {
        console.error('Error saving new location tracking entry:', saveError);
        
        // If we still have an error, create a simplified tracking entry as a last resort
        const basicTracking = {
          driver: livreurId,
          status: 'pending',
          locationHistory: [{
            latitude: parsedLatitude,
            longitude: parsedLongitude,
            timestamp: new Date()
          }]
        };
        
        const simplifiedTracking = new Delivery(basicTracking);
        await simplifiedTracking.save();
        
        return res.status(201).json({
          message: 'Created simplified location tracking entry',
          delivery: simplifiedTracking
        });
      }
    }
    
    // Update all active deliveries with new location
    let successfulUpdates = 0;
    const errorMessages = [];
    
    for (const delivery of activeDeliveries) {
      try {
        // Update current location
        delivery.currentLocation = {
          latitude: parsedLatitude,
          longitude: parsedLongitude,
          address: address || delivery.currentLocation?.address || '',
          updatedAt: new Date()
        };
        
        // Add to location history
        if (!delivery.locationHistory) {
          delivery.locationHistory = [];
        }
        
        delivery.locationHistory.push({
          latitude: parsedLatitude,
          longitude: parsedLongitude,
          timestamp: new Date()
        });
        
        // Keep location history limited to last 100 points to prevent excessive data
        if (delivery.locationHistory.length > 100) {
          delivery.locationHistory = delivery.locationHistory.slice(-100);
        }
        
        await delivery.save();
        successfulUpdates++;
      } catch (error) {
        console.error(`Error updating delivery ${delivery._id}:`, error);
        errorMessages.push(`Delivery ${delivery._id}: ${error.message}`);
      }
    }
    
    // Return appropriate response based on update results
    if (successfulUpdates === activeDeliveries.length) {
      res.json({
        message: `Updated location for all ${successfulUpdates} active deliveries`,
        updatedCount: successfulUpdates
      });
    } else if (successfulUpdates > 0) {
      res.json({
        message: `Updated location for ${successfulUpdates} out of ${activeDeliveries.length} active deliveries`,
        updatedCount: successfulUpdates,
        errors: errorMessages
      });
    } else {
      // All updates failed, but we'll still return 200 with detailed errors
      res.json({
        message: `Failed to update any of the ${activeDeliveries.length} active deliveries`,
        updatedCount: 0,
        errors: errorMessages
      });
    }
    
  } catch (err) {
    console.error('Error updating livreur location:', err);
    res.status(500).json({ message: err.message });
  }
};

/**
 * Get optimized delivery route for a driver
 * @route   GET /api/route-optimization/optimized-route
 * @access  Private/Livreur
 */
export const getOptimizedRoute = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { startLatitude, startLongitude } = req.query;
    
    if (!startLatitude || !startLongitude) {
      return res.status(400).json({ 
        error: 'Starting coordinates (startLatitude and startLongitude) are required' 
      });
    }
    
    // Convert to numbers
    const startLat = parseFloat(startLatitude);
    const startLng = parseFloat(startLongitude);
    
    if (isNaN(startLat) || isNaN(startLng)) {
      return res.status(400).json({ 
        error: 'Coordinates must be valid numbers' 
      });
    }
    
    // Get all pending deliveries assigned to this driver
    const deliveries = await Delivery.find({
      driver: driverId,
      status: { $in: ['pending', 'picked_up'] }
    }).populate({
      path: 'order',
      populate: [
        { 
          path: 'restaurant',
          select: 'name address latitude longitude' 
        },
        { 
          path: 'user', 
          select: 'name address latitude longitude' 
        }
      ]
    });
    
    if (deliveries.length === 0) {
      return res.status(404).json({ 
        message: 'No active deliveries found to optimize' 
      });
    }
    
    // Create an array of delivery points (restaurants and customer addresses)
    const points = [];
    
    // Add driver's current location as starting point
    points.push({
      id: 'starting_point',
      latitude: startLat,
      longitude: startLng,
      type: 'current_location',
      name: 'Your Current Location'
    });
    
    // Process each delivery
    for (const delivery of deliveries) {
      // Skip deliveries with missing order data
      if (!delivery.order) continue;
      
      const order = delivery.order;
      const status = delivery.status;
      
      // For 'pending' deliveries, we need to go to the restaurant first, then to the customer
      if (status === 'pending') {
        // Add restaurant to route if it has valid coordinates
        if (order.restaurant && order.restaurant.latitude && order.restaurant.longitude) {
          points.push({
            id: `restaurant_${order._id}`,
            deliveryId: delivery._id,
            orderId: order._id,
            latitude: order.restaurant.latitude,
            longitude: order.restaurant.longitude,
            type: 'restaurant',
            name: order.restaurant.name || 'Restaurant',
            address: order.restaurant.address || 'No address available'
          });
        }
      }
      
      // For all deliveries, add the customer's location
      if (order.user && order.user.latitude && order.user.longitude) {
        points.push({
          id: `customer_${order._id}`,
          deliveryId: delivery._id,
          orderId: order._id,
          latitude: order.user.latitude,
          longitude: order.user.longitude,
          type: 'customer',
          name: order.user.name || 'Customer',
          address: order.user.address || 'No address available'
        });
      }
    }
    
    // Simple 'Nearest Neighbor' route optimization algorithm
    const optimizedRoute = nearestNeighborRouteOptimization(points);
    
    // Add estimated metrics to the response
    const routeMetrics = calculateRouteMetrics(optimizedRoute);
    
    res.json({
      message: `Optimized route with ${optimizedRoute.length} stops`,
      startingPoint: {
        latitude: startLat,
        longitude: startLng
      },
      optimizedRoute,
      metrics: routeMetrics
    });
    
  } catch (error) {
    console.error('Route optimization error:', error);
    res.status(500).json({ error: 'Failed to optimize delivery route' });
  }
};

/**
 * Update delivery location
 * @route   POST /api/route-optimization/update-location
 * @access  Private/Livreur
 */
export const updateDeliveryLocation = async (req, res) => {
  try {
    const driverId = req.user._id;
    const { deliveryId, latitude, longitude, status } = req.body;
    
    if (!deliveryId || !latitude || !longitude) {
      return res.status(400).json({ 
        error: 'DeliveryId, latitude, and longitude are required' 
      });
    }
    
    // Convert to numbers
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ 
        error: 'Latitude and longitude must be valid numbers' 
      });
    }
    
    // Find the delivery and verify it belongs to the driver
    const delivery = await Delivery.findById(deliveryId);
    
    if (!delivery) {
      return res.status(404).json({ error: 'Delivery not found' });
    }
    
    if (delivery.driver.toString() !== driverId.toString()) {
      return res.status(403).json({ 
        error: 'You can only update your own deliveries' 
      });
    }
    
    // Update the location and optionally the status
    delivery.currentLocation = {
      latitude: lat,
      longitude: lng,
      updatedAt: new Date()
    };
    
    // Add to location history
    if (!delivery.locationHistory) {
      delivery.locationHistory = [];
    }
    
    delivery.locationHistory.push({
      latitude: lat,
      longitude: lng,
      timestamp: new Date()
    });
    
    // Trim history to prevent excessive data
    if (delivery.locationHistory.length > 100) {
      delivery.locationHistory = delivery.locationHistory.slice(-100);
    }
    
    // Update status if provided and valid
    if (status && ['pending', 'picked_up', 'delivering', 'delivered', 'cancelled'].includes(status)) {
      delivery.status = status;
      
      // If status is 'delivered', update deliveredAt
      if (status === 'delivered') {
        delivery.deliveredAt = new Date();
      }
    }
    
    await delivery.save();
    
    res.json({
      message: 'Delivery location updated successfully',
      delivery: {
        _id: delivery._id,
        status: delivery.status,
        currentLocation: delivery.currentLocation
      }
    });
    
  } catch (error) {
    console.error('Update delivery location error:', error);
    res.status(500).json({ error: 'Failed to update delivery location' });
  }
};

// Get the latest location of all livreurs with active deliveries
export const getLivreurLocations = async (req, res) => {
  try {
    console.log('Fetching all livreur locations');
    
    // Find all active deliveries and populate the driver details
    const activeDeliveries = await Delivery.find({
      status: { $in: ['pending', 'picked_up', 'delivering'] }
    })
    .populate('driver', 'firstName name email phone vehiculetype status')
    .select('driver currentLocation status')
    .lean();
    
    if (!activeDeliveries || activeDeliveries.length === 0) {
      console.log('No active deliveries found');
      return res.json([]);
    }
    
    // Create a map to keep track of the latest location for each livreur
    const livreurLocationsMap = new Map();
    
    // Process each delivery to extract livreur location data
    activeDeliveries.forEach(delivery => {
      // Skip if no driver or no location
      if (!delivery.driver || !delivery.currentLocation) return;
      
      const livreurId = delivery.driver._id.toString();
      const currentLocation = delivery.currentLocation;
      
      // Skip if missing latitude or longitude
      if (!currentLocation.latitude || !currentLocation.longitude) return;
      
      // Check if we already have a location for this livreur and if this one is newer
      const existingLocation = livreurLocationsMap.get(livreurId);
      if (!existingLocation || 
          (currentLocation.updatedAt && existingLocation.updatedAt && 
           new Date(currentLocation.updatedAt) > new Date(existingLocation.updatedAt))) {
        
        // Store this as the latest location
        livreurLocationsMap.set(livreurId, {
          livreurId,
          name: `${delivery.driver.firstName || ''} ${delivery.driver.name || ''}`.trim(),
          status: delivery.status,
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          updatedAt: currentLocation.updatedAt || new Date()
        });
      }
    });
    
    // Convert map to array
    const livreurLocations = Array.from(livreurLocationsMap.values());
    
    console.log(`Found locations for ${livreurLocations.length} active livreurs`);
    
    res.json(livreurLocations);
  } catch (err) {
    console.error('Error in getLivreurLocations:', err);
    res.status(500).json({ message: err.message });
  }
};

// Helper function: Nearest Neighbor algorithm for route optimization
function nearestNeighborRouteOptimization(points) {
  if (points.length <= 1) return points;
  
  const optimizedRoute = [];
  const unvisited = [...points];
  
  // Start with the first point (driver's current location)
  let currentPoint = unvisited.shift();
  optimizedRoute.push(currentPoint);
  
  // While there are unvisited points
  while (unvisited.length > 0) {
    const currentIndex = optimizedRoute.length - 1;
    const current = optimizedRoute[currentIndex];
    
    // Find the nearest unvisited point
    let nearestIndex = 0;
    let minDistance = calculateDistance(
      current.latitude, 
      current.longitude, 
      unvisited[0].latitude, 
      unvisited[0].longitude
    );
    
    for (let i = 1; i < unvisited.length; i++) {
      const distance = calculateDistance(
        current.latitude, 
        current.longitude, 
        unvisited[i].latitude, 
        unvisited[i].longitude
      );
      
      if (distance < minDistance) {
        nearestIndex = i;
        minDistance = distance;
      }
    }
    
    // Add the nearest point to the route
    const nextPoint = unvisited.splice(nearestIndex, 1)[0];
    optimizedRoute.push(nextPoint);
  }
  
  return optimizedRoute;
}

// Helper function: Calculate distance between two points using Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
  // Earth's radius in kilometers
  const R = 6371;
  
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c;
  
  return distance; // Distance in kilometers
}

// Helper function: Calculate route metrics (total distance and estimated time)
function calculateRouteMetrics(route) {
  if (route.length <= 1) {
    return { 
      totalDistanceKm: 0, 
      estimatedTimeMinutes: 0,
      estimatedTimeText: '0 min'
    };
  }
  
  let totalDistance = 0;
  
  // Calculate total distance by summing distances between consecutive points
  for (let i = 0; i < route.length - 1; i++) {
    const currentPoint = route[i];
    const nextPoint = route[i + 1];
    
    const distance = calculateDistance(
      currentPoint.latitude, 
      currentPoint.longitude, 
      nextPoint.latitude, 
      nextPoint.longitude
    );
    
    totalDistance += distance;
  }
  
  // Average delivery speed in urban areas (km/h)
  const avgSpeedKmh = 25;
  
  // Calculate estimated time in minutes
  const estimatedTimeMinutes = Math.round((totalDistance / avgSpeedKmh) * 60);
  
  // Format estimated time text
  let estimatedTimeText;
  if (estimatedTimeMinutes < 60) {
    estimatedTimeText = `${estimatedTimeMinutes} min`;
  } else {
    const hours = Math.floor(estimatedTimeMinutes / 60);
    const minutes = estimatedTimeMinutes % 60;
    estimatedTimeText = `${hours} hr ${minutes > 0 ? `${minutes} min` : ''}`;
  }
  
  return {
    totalDistanceKm: Math.round(totalDistance * 10) / 10, // Round to 1 decimal place
    estimatedTimeMinutes,
    estimatedTimeText
  };
}
