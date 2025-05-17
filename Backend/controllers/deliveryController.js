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
    const livreurMap = new Map(); // Use Map to track unique livreurs
    
    deliveries.forEach(delivery => {
      const driverId = delivery.driver?._id?.toString();
      if (driverId) {
        // Count deliveries per driver
        deliveryCounts[driverId] = (deliveryCounts[driverId] || 0) + 1;
        
        // Track unique drivers with their data
        if (!livreurMap.has(driverId)) {
          livreurMap.set(driverId, delivery.driver);
        }
      }
    });
    
    // Create a unique list of drivers with their delivery counts
    const uniqueLivreurs = Array.from(livreurMap.entries()).map(([driverId, driver]) => ({
      _id: driver._id,
      firstName: driver.firstName,
      name: driver.name,
      email: driver.email,
      phone: driver.phone,
      vehiculetype: driver.vehiculetype,
      status: driver.status,
      deliveriesCount: deliveryCounts[driverId] || 0
    }));

    // If livreurs are specifically requested, return only unique livreurs
    if (req.query.livreurs === 'true') {
      return res.json(uniqueLivreurs);
    }

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
    const order = await Order.findById(orderId).populate('restaurant', 'name latitude longitude');
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    const livreur = await User.findById(livreurId);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found or invalid role' });
    }

    // Get restaurant details from the populated order
    const restaurantName = order.restaurant?.name || '';
    const restaurantLatitude = order.restaurant?.latitude || null;
    const restaurantLongitude = order.restaurant?.longitude || null;

    // Create the delivery with flat restaurant fields
    const delivery = new Delivery({
      order: orderId,
      driver: livreurId,
      client: order.user, // Add client reference
      status: 'pending',
      restaurantName,
      restaurantLatitude,
      restaurantLongitude
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

    // If order is being updated, fetch restaurant details to update flat fields
    let restaurantData = {};
    if (order) {
      const newOrder = await Order.findById(order).populate('restaurant', 'name latitude longitude');
      if (newOrder && newOrder.restaurant) {
        restaurantData = {
          restaurantName: newOrder.restaurant.name || '',
          restaurantLatitude: newOrder.restaurant.latitude || null,
          restaurantLongitude: newOrder.restaurant.longitude || null
        };
      }
    }

    // Update the delivery with restaurant data if order changed
    const updatedDelivery = await Delivery.findByIdAndUpdate(
      id,
      { 
        order, 
        driver, 
        status, 
        deliveredAt,
        ...restaurantData // Add restaurant flat fields if order was updated
      },
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
    
    // If needed, ensure restaurant data is up to date
    if (delivery.order && (!delivery.restaurantName || !delivery.restaurantLatitude || !delivery.restaurantLongitude)) {
      const order = await Order.findById(delivery.order).populate('restaurant', 'name latitude longitude');
      if (order && order.restaurant) {
        delivery.restaurantName = order.restaurant.name || '';
        delivery.restaurantLatitude = order.restaurant.latitude || null;
        delivery.restaurantLongitude = order.restaurant.longitude || null;
      }
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
    
    // Find deliveries where this livreur is the driver
    const deliveries = await Delivery.find({ driver: livreurId })
      .populate({
        path: 'order',
        populate: [
          { path: 'user', select: 'username firstName name email phone' },
          { path: 'restaurant', select: 'name address cuisine latitude longitude' },
          { path: 'items.food', select: 'name price imageUrl' }
        ]
      })
      .populate('client', 'username firstName name email phone')
      .select('-locationHistory');  // Exclude location history to reduce payload size

    // If no deliveries found, return empty array instead of error
    if (!deliveries || deliveries.length === 0) {
      console.log(`No deliveries found for livreurId: ${livreurId}`);
      return res.json([]);
    }

    // Transform the deliveries into the format expected by the frontend
    const formattedDeliveries = deliveries.map(delivery => {
      const deliveryObj = delivery.toObject();
      const order = deliveryObj.order || {};
      const user = order.user || {};
      const restaurant = order.restaurant || {};
      
      // Format the date and time
      const createdAt = delivery.createdAt ? new Date(delivery.createdAt) : new Date();
      const date = createdAt.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
      const time = createdAt.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
      
      // Build a properly formatted delivery object
      return {
        id: deliveryObj._id,
        date: date,
        time: time,
        customer: `${user.firstName || ''} ${user.name || ''}`.trim() || user.username || 'Unknown',
        address: order.deliveryAddress || restaurant.address || 'N/A',
        amount: order.totalPrice || 0,
        status: deliveryObj.status || 'pending',
        rating: deliveryObj.rating || null,
        restaurantName: restaurant.name || 'N/A',
        order: {
          id: order._id,
          reference: order.reference,
          items: order.items || []
        }
      };
    });

    console.log(`Found ${formattedDeliveries.length} deliveries for livreurId: ${livreurId}`);
    
    res.json(formattedDeliveries);
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
      return res.status(404).json({ message: 'Livreur not found' });
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
        // Check if delivery.order is set and valid
        if (delivery.order) {
          const orderExists = await mongoose.model('Order').findById(delivery.order);
          if (!orderExists) {
            console.warn(`Skipping delivery ${delivery._id}: order reference ${delivery.order} does not exist.`);
            errorMessages.push(`Delivery ${delivery._id}: order reference does not exist.`);
            continue; // Skip this delivery
          }
        }
        // Update current location
        delivery.currentLocation = {
          latitude: parsedLatitude,
          longitude: parsedLongitude,
          address: address || (delivery.currentLocation && delivery.currentLocation.address) || '',
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
    } else {      // All updates failed, but we'll still return 200 with detailed errors
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

// Get livreur's current location
export const getLivreurLocation = async (req, res) => {
  try {
    const { livreurId } = req.params;
    
    // Validate livreur ID
    if (!livreurId || !mongoose.Types.ObjectId.isValid(livreurId)) {
      return res.status(400).json({ message: 'Valid livreur ID is required' });
    }
    
    // Check if livreur exists
    const livreur = await User.findById(livreurId);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found' });
    }
    
    // Find the most recent delivery with location data for this livreur
    const recentDelivery = await Delivery.findOne(
      { 
        driver: livreurId,
        currentLocation: { $exists: true }
      },
      { 
        'currentLocation': 1,
        'locationHistory': { $slice: -1 } // Get only the most recent location history entry
      }
    ).sort({ 'currentLocation.updatedAt': -1 });
    
    if (!recentDelivery || !recentDelivery.currentLocation) {
      return res.status(404).json({ message: 'No location data found for this livreur' });
    }
    
    // Return the current location
    return res.json({
      livreurId,
      latitude: recentDelivery.currentLocation.latitude,
      longitude: recentDelivery.currentLocation.longitude,
      address: recentDelivery.currentLocation.address || '',
      updatedAt: recentDelivery.currentLocation.updatedAt,
      timestamp: new Date()
    });
    
  } catch (err) {
    console.error('Error getting livreur location:', err);
    res.status(500).json({ message: err.message });
  }
};

// Get all livreur locations for active deliveries
export const getAllLivreurLocations = async (req, res) => {
  try {
    // Find all active deliveries with location data
    const activeDeliveries = await Delivery.find(
      { 
        currentLocation: { $exists: true },
        status: { $in: ['pending', 'picked_up', 'delivering'] }
      },
      { 
        driver: 1,
        currentLocation: 1
      }
    ).populate('driver', 'firstName name username phone email');
    
    if (!activeDeliveries || activeDeliveries.length === 0) {
      return res.json([]);
    }
    
    // Group by driver ID to get the most recent location for each driver
    const locationMap = new Map();
    
    activeDeliveries.forEach(delivery => {
      if (!delivery.driver || !delivery.currentLocation) return;
      
      const driverId = delivery.driver._id.toString();
      const existingLocation = locationMap.get(driverId);
      
      // Only keep the most recently updated location for each driver
      if (!existingLocation || 
          (delivery.currentLocation.updatedAt > existingLocation.updatedAt)) {
        locationMap.set(driverId, {
          livreurId: driverId,
          name: `${delivery.driver.firstName || ''} ${delivery.driver.name || ''}`.trim() || delivery.driver.username,
          latitude: delivery.currentLocation.latitude,
          longitude: delivery.currentLocation.longitude,
          address: delivery.currentLocation.address || '',
          updatedAt: delivery.currentLocation.updatedAt
        });
      }
    });
    
    // Convert map to array for response
    const locations = Array.from(locationMap.values());
    
    return res.json(locations);
    
  } catch (err) {
    console.error('Error getting all livreur locations:', err);
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

// Get delivery stats for a specific user/driver
export const getDeliveryStats = async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId) {
      console.error('Missing userId parameter');
      return res.status(400).json({ message: 'User ID is required' });
    }

    console.log(`[Backend] Getting delivery stats for user: ${userId}`);
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get completed deliveries
    const completedDeliveries = await Delivery.countDocuments({
      driver: userId,
      status: 'delivered'
    });

    // Get pending deliveries
    const pendingDeliveries = await Delivery.countDocuments({
      driver: userId,
      status: { $in: ['assigned', 'picked', 'in_progress'] }
    });

    // Get total collected amount (from completed deliveries)
    const collectedResult = await Delivery.aggregate([
      {
        $match: {
          driver: new mongoose.Types.ObjectId(userId),
          status: 'delivered',
          paymentStatus: 'paid'
        }
      },
      {
        $lookup: {
          from: 'orders',
          localField: 'order',
          foreignField: '_id',
          as: 'orderDetails'
        }
      },
      {
        $unwind: '$orderDetails'
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$orderDetails.total' }
        }
      }
    ]);

    // Get driver earnings
    const earningsResult = await Delivery.aggregate([
      {
        $match: {
          driver: new mongoose.Types.ObjectId(userId),
          status: 'delivered'
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$driverEarnings' }
        }
      }
    ]);

    // Format the response
    const stats = {
      completed: completedDeliveries,
      pending: pendingDeliveries,
      collected: collectedResult.length > 0 ? collectedResult[0].total : 0,
      earnings: earningsResult.length > 0 ? earningsResult[0].total : 0
    };

    console.log(`[Backend] Delivery stats for user ${userId}:`, stats);
    res.status(200).json(stats);
  } catch (error) {
    console.error('Error fetching delivery stats:', error);
    res.status(500).json({ message: 'Error fetching delivery stats', error: error.message });
  }
};

// Get deliveries for a specific client
export const getDeliveriesByClient = async (req, res) => {
  try {
    const clientId = req.params.clientId || req.query.clientId || req.headers.userid || (req.user ? req.user._id : null);

    // Check if we have a valid clientId to use
    if (!clientId) {
      return res.status(400).json({ message: 'Client ID is required' });
    }

    // Find deliveries where the client is the user
    const deliveries = await Delivery.find({ client: clientId })
      .populate({
        path: 'order',
        populate: [
          { path: 'user', select: 'username firstName name email phone' },
          { path: 'restaurant', select: 'name address cuisine latitude longitude' },
          { path: 'items.food', select: 'name price imageUrl' }
        ]
      })
      .populate('driver', 'firstName name email phone vehiculetype status')
      .sort({ createdAt: -1 });

    // If no deliveries found, return empty array
    if (!deliveries || deliveries.length === 0) {
      return res.json([]);
    }

    res.json(deliveries);
  } catch (err) {
    console.error('Error in getDeliveriesByClient:', err);
    res.status(500).json({ message: err.message });
  }
};

// Rate a delivery
export const rateDelivery = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating } = req.body;

    // Validate rating
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be a number between 1 and 5' });
    }

    // Find and update the delivery
    const delivery = await Delivery.findById(id);
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery not found' });
    }

    // Check if the delivery status is 'delivered'
    if (delivery.status !== 'delivered') {
      return res.status(400).json({ message: 'Only delivered orders can be rated' });
    }

    // Update the rating
    delivery.rating = rating;
    await delivery.save();

    res.json({ success: true, message: 'Rating added successfully', delivery });
  } catch (err) {
    console.error('Error in rateDelivery:', err);
    res.status(500).json({ message: err.message });
  }
};

// Get deliveries by status
export const getDeliveriesByStatus = async (req, res) => {
  try {
    const { userId, status } = req.query;
    console.log(`Fetching deliveries for userId: ${userId}, statuses: ${status}`);
    
    if (!userId) {
      return res.status(400).json({ message: 'UserId parameter is required' });
    }
    
    const statuses = status ? status.split(',') : ['pending', 'picked_up', 'delivering'];
    
    // Use the already imported model from the top of the file
    const deliveries = await Delivery.find({
      driver: userId,
      status: { $in: statuses }
    })
    .populate({
      path: 'order',
      populate: [
        { path: 'user', select: 'username firstName name email phone' },
        { path: 'restaurant', select: 'name address cuisine latitude longitude' },
        { path: 'items.food', select: 'name price imageUrl' }
      ]
    })
    .populate('client', 'username firstName name email phone');
    
    console.log(`Found ${deliveries.length} deliveries for userId: ${userId}`);
    
    res.status(200).json({ deliveries });
  } catch (error) {
    console.error('Error fetching deliveries:', error);
    res.status(500).json({ error: error.message });
  }
};

// Get collected amount deliveries for a driver
export const getCollectedDeliveries = async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({ message: 'UserId parameter is required' });
    }
    
    console.log(`Fetching collected deliveries for userId: ${userId}`);
    
    // Get delivered orders by this driver
    const deliveries = await Delivery.find({
      driver: userId,
      status: 'delivered'
    })
    .populate({
      path: 'order',
      populate: [
        { path: 'user', select: 'username firstName name email phone' },
        { path: 'restaurant', select: 'name address cuisine' },
        { path: 'items.food', select: 'name price imageUrl' }
      ]
    })
    .sort({ deliveredAt: -1 });
    
    res.json({ deliveries });
  } catch (err) {
    console.error('Error getting collected deliveries:', err);
    res.status(500).json({ message: err.message });
  }
};

// Get earnings for a driver
export const getEarningsDeliveries = async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({ message: 'UserId parameter is required' });
    }
    
    console.log(`Fetching earnings deliveries for userId: ${userId}`);
    
    // Get completed deliveries with earnings for this driver
    const deliveries = await Delivery.find({
      driver: userId,
      status: 'delivered'
    })
    .populate({
      path: 'order',
      select: 'totalPrice items user restaurant',
      populate: [
        { path: 'user', select: 'username firstName name email phone' },
        { path: 'restaurant', select: 'name address cuisine' },
        { path: 'items.food', select: 'name price' }
      ]
    })
    .sort({ deliveredAt: -1 });
    
    // Enhance deliveries with commission calculations
    const enhancedDeliveries = deliveries.map(delivery => {
      const deliveryObject = delivery.toObject();
      // Add commission rate (can be customized later in settings)
      deliveryObject.commissionRate = 0.15; // 15% commission by default
      return deliveryObject;
    });
    
    res.json({ deliveries: enhancedDeliveries });
  } catch (err) {
    console.error('Error getting earnings deliveries:', err);
    res.status(500).json({ message: err.message });
  }
};

// Get mock delivery orders for testing
export const getMockDeliveryOrders = async (req, res) => {
  try {
    console.log('Returning mock delivery orders for testing');
    
    const mockDeliveries = [
      {
        _id: '65a93cf137a1ef7a07353111',
        order: {
          _id: 'ORD123456',
          totalPrice: 45.99,
          user: {
            name: 'John Smith',
            phone: '+1 (555) 123-4567'
          },
          restaurant: {
            name: 'Pizza Palace',
            address: '123 Restaurant St, City'
          },
          items: [
            {
              food: { name: 'Large Pizza', price: 25.99 },
              quantity: 1
            },
            {
              food: { name: 'Garlic Bread', price: 5.99 },
              quantity: 2
            }
          ]
        },
        validationCode: '1234',
        status: 'delivered',
        createdAt: '2025-05-14T12:00:00Z',
        deliveredAt: '2025-05-14T12:30:00Z',
        commissionRate: 0.15
      },
      {
        _id: '65a93cf137a1ef7a07353222',
        order: {
          _id: 'ORD789012',
          totalPrice: 32.50,
          user: {
            name: 'Jane Doe',
            phone: '+1 (555) 987-6543'
          },
          restaurant: {
            name: 'Burger Joint',
            address: '456 Burger Ave, City'
          },
          items: [
            {
              food: { name: 'Cheese Burger', price: 12.99 },
              quantity: 2
            },
            {
              food: { name: 'Fries', price: 6.50 },
              quantity: 1
            }
          ]
        },
        validationCode: '5678',
        status: 'in_progress',
        createdAt: '2025-05-14T14:00:00Z',
        commissionRate: 0.15
      },
      {
        _id: '65a93cf137a1ef7a07353333',
        order: {
          _id: 'ORD345678',
          totalPrice: 28.75,
          user: {
            name: 'Mike Johnson',
            phone: '+1 (555) 456-7890'
          },
          restaurant: {
            name: 'Sushi Express',
            address: '789 Sushi Blvd, City'
          },
          items: [
            {
              food: { name: 'California Roll', price: 14.99 },
              quantity: 1
            },
            {
              food: { name: 'Miso Soup', price: 3.99 },
              quantity: 2
            }
          ]
        },
        validationCode: '9012',
        status: 'pending',
        createdAt: '2025-05-14T09:00:00Z',
        commissionRate: 0.15
      }
    ];
    
    res.json({ deliveries: mockDeliveries });
  } catch (err) {
    console.error('Error in getMockDeliveryOrders:', err);
    res.status(500).json({ message: err.message });
  }
};

// Comment: The original implementation of getDeliveryStats is already defined above at line ~907
