import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import rateLimit from 'express-rate-limit';
import fs from 'fs';
import { LRUCache } from 'lru-cache';
import morgan from 'morgan';
import multer from 'multer'; // Add multer for file uploads
import fetch from 'node-fetch'; // Add this at the top
import path from 'path';
import { Server } from 'socket.io'; // Add this for WebSocket support

import connectDB from './config/database.js';
import cartRoutes from "./routes/cartRoutes.js";
import deliveryRoutes from './routes/deliveryRoutes.js';
import foodRoutes from './routes/foodRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import orderRoutes from './routes/orderRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import restaurantRoutes from './routes/restaurantRoutes.js';
import settingsRoutes from './routes/settingsRoutes.js';
import userRoutes from './routes/userRoutes.js';
import analyticsRoutes from './routes/analyticsRoutes.js';
import feedbackRoutes from './routes/feedbackRoutes.js';
import routeOptimizationRoutes from './routes/routeOptimizationRoutes.js';

dotenv.config();

// Set up API rate limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: "Too many requests from this IP, please try again after 15 minutes"
});

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded data
const upload = multer(); // Initialize multer for parsing multipart/form-data

// Apply rate limiting to all API routes
app.use('/api/', apiLimiter);

// Ensure uploads directories exist
const uploadsDir = path.join(process.cwd(), 'uploads');
const foodsUploadsDir = path.join(uploadsDir, 'foods');
const restaurantsUploadsDir = path.join(uploadsDir, 'restaurants');

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}
if (!fs.existsSync(foodsUploadsDir)) {
  fs.mkdirSync(foodsUploadsDir);
}
if (!fs.existsSync(restaurantsUploadsDir)) {
  fs.mkdirSync(restaurantsUploadsDir);
}

// Serve static files from the uploads directory
app.use('/uploads', express.static(uploadsDir));

// Connect to MongoDB
connectDB(process.env.MONGO_URI); // Use environment variable instead of hardcoded string

// Routes
app.use('/api/user', userRoutes);
app.use("/api/cart", cartRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/foods', foodRoutes);
app.use('/api/deliveries', deliveryRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/route-optimization', routeOptimizationRoutes);
// Removed geocodeRoutes import as the file has been deleted

// Optimized cache with LRU policy
const geocodingCache = new LRUCache({
  max: 1000,  // Maximum number of items to store
  ttl: 1000 * 60 * 60 * 24, // Time to live: 24 hours
  updateAgeOnGet: true, // Update item age on access
  allowStale: false // Don't return stale items
});

let lastGeocodingRequest = 0; // Timestamp of last request to respect rate limits

// Helper function to return a default address for Tunisia
function getDefaultAddressForTunisia() {
  console.log('Using default address for Tunisia');
  return 'Tunisia, Tunis';
}

// Utility function for reverse geocoding using OpenStreetMap Nominatim
async function reverseGeocode(lat, lon) {
  try {
    // Validate coordinates
    if (!lat || !lon || isNaN(parseFloat(lat)) || isNaN(parseFloat(lon))) {
      console.error('Invalid coordinates for geocoding', { lat, lon });
      return getDefaultAddressForTunisia();
    }
    
    // Validate coordinate ranges
    const parsedLat = parseFloat(lat);
    const parsedLon = parseFloat(lon);
    
    if (parsedLat < -90 || parsedLat > 90 || parsedLon < -180 || parsedLon > 180) {
      console.error('Coordinates out of valid range', { lat: parsedLat, lon: parsedLon });
      return getDefaultAddressForTunisia();
    }
    
    // Round coordinates to 5 decimal places for effective caching (about 1m precision)
    const roundedLat = parseFloat(lat).toFixed(5);
    const roundedLon = parseFloat(lon).toFixed(5);
    const cacheKey = `${roundedLat}-${roundedLon}`;

    // Check if we have this location cached
    if (geocodingCache.has(cacheKey)) {
      console.log(`Using cached address for ${cacheKey}`);
      return geocodingCache.get(cacheKey);
    }
    
    // Add rate limiting - one request per second max for Nominatim
    const now = Date.now();
    const timeSinceLastRequest = now - lastGeocodingRequest;
    if (timeSinceLastRequest < 1000) {
      const delay = 1000 - timeSinceLastRequest;
      console.log(`Rate limiting: Waiting ${delay}ms before geocoding request`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    lastGeocodingRequest = Date.now();
    
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=18&addressdetails=1`;
    const controller = new AbortController();
    // Set timeout to prevent long-hanging requests
    const timeoutId = setTimeout(() => controller.abort(), 5000); // 5-second timeout
    
    console.log(`Making geocoding request for ${roundedLat}, ${roundedLon}`);
    
    const response = await fetch(url, {
      headers: { 
        'User-Agent': 'pfe-update-backend/1.0', // Unique user agent as required by Nominatim
        'Accept-Language': 'en-US,en;q=0.9'
      },
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    
    if (!response.ok) {
      console.error(`Reverse geocoding error: ${response.status} ${response.statusText}`);
      return null;
    }
    
    const data = await response.json();
    
    // Extract address with fallbacks for different formats
    let address = data.display_name;
    
    if (!address && data.address) {
      // Build address from components if available
      const components = [];
      const addr = data.address;
      
      if (addr.road) components.push(addr.road);
      if (addr.house_number) components.push(addr.house_number);
      if (addr.suburb) components.push(addr.suburb);
      if (addr.city || addr.town || addr.village) components.push(addr.city || addr.town || addr.village);
      if (addr.state || addr.county) components.push(addr.state || addr.county);
      if (addr.country) components.push(addr.country);
      
      if (components.length > 0) {
        address = components.join(', ');
      }
    }
    
    // If still no address, create a simple coordinates-based one
    if (!address) {
      address = `Location at ${roundedLat}, ${roundedLon}`;
    }
    
    // Cache the result for future use
    geocodingCache.set(cacheKey, address);
    
    return address;
  } catch (err) {
    console.error('Reverse geocoding failed:', err.message);
    // Return a default message if we hit a timeout or other fetch error
    if (err.name === 'AbortError') {
      console.error('Geocoding request timed out');
    }
    return null;
  }
}

// Geocoding utility service
app.get('/api/geocode/reverse', async (req, res) => {
  try {
    const { lat, lon, latitude, longitude } = req.query;
    
    // Use either lat/lon or latitude/longitude parameter set
    const latValue = latitude || lat;
    const lonValue = longitude || lon;
    
    console.log(`Geocode request received for coordinates: ${latValue}, ${lonValue}`);
    
    // More detailed validation
    if (!latValue || !lonValue) {
      console.warn('Geocode request missing coordinates');
      return res.status(400).json({ error: 'Latitude and longitude are required parameters' });
    }
    
    // Parse and validate the coordinates
    const parsedLat = parseFloat(latValue);
    const parsedLon = parseFloat(lonValue);
    
    if (isNaN(parsedLat) || isNaN(parsedLon)) {
      console.warn(`Invalid coordinates format: lat=${lat}, lon=${lon}`);
      return res.status(400).json({ error: 'Latitude and longitude must be valid numbers' });
    }
    
    if (parsedLat < -90 || parsedLat > 90) {
      console.warn(`Latitude out of range: ${parsedLat}`);
      return res.status(400).json({ error: 'Latitude must be between -90 and 90' });
    }
    
    if (parsedLon < -180 || parsedLon > 180) {
      console.warn(`Longitude out of range: ${parsedLon}`);
      return res.status(400).json({ error: 'Longitude must be between -180 and 180' });
    }

    // Check request cache headers and send 304 Not Modified if client has fresh data
    const roundedLat = parsedLat.toFixed(5);
    const roundedLon = parsedLon.toFixed(5);
    const cacheKey = `${roundedLat}-${roundedLon}`;
    
    // If the cache already has this entry, set a long cache time
    if (geocodingCache.has(cacheKey)) {
      console.log(`Using cached address for ${cacheKey}`);
      res.set('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
    } else {
      res.set('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour for new entries
    }
    
    const address = await reverseGeocode(parsedLat, parsedLon);
    if (address) {
      console.log(`Successfully geocoded ${roundedLat}, ${roundedLon} to "${address}"`);
      return res.json({ address });
    } else {
      console.warn(`Failed to geocode coordinates: ${roundedLat}, ${roundedLon}`);
      // Return a default address for Tunisia instead of an error
      return res.json({ address: 'Tunisia, Tunis' });
    }
  } catch (error) {
    console.error('Geocoding error:', error);
    res.status(500).json({ error: 'Failed to perform geocoding lookup' });
  }
});

// Route for OpenStreetMap redirects with proper headers
app.get('/api/geocode/map-redirect', (req, res) => {
  const { lat, lon, zoom = 15 } = req.query;
  if (!lat || !lon) {
    return res.status(400).send('Latitude and longitude are required parameters');
  }
  
  // Redirect to OpenStreetMap with proper referrer
  res.redirect(`https://www.openstreetmap.org/?mlat=${lat}&mlon=${lon}#map=${zoom}/${lat}/${lon}`);
});

// Route for embedded maps with proper headers and referrer
app.get('/api/geocode/embed', (req, res) => {
  const { bbox, marker, zoom = 15 } = req.query;
  
  if ((!bbox && !marker) || (marker && marker.split(',').length !== 2)) {
    return res.status(400).send('Invalid map parameters');
  }
  
  // Build the OpenStreetMap embed URL with all the parameters
  let embedUrl = `https://www.openstreetmap.org/export/embed.html?`;
  
  if (bbox) {
    embedUrl += `bbox=${bbox}&`;
  }
  if (marker) {
    embedUrl += `marker=${marker}&`;
  }
  
  embedUrl += 'layer=mapnik';
  
  // Set proper referrer and cache headers
  res.set({
    'Content-Type': 'text/html',
    'Cache-Control': 'public, max-age=86400'
  });
  
  // Create an HTML page that embeds the map with the proper referrer
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Map</title>
      <style>
        body, html, iframe { margin: 0; padding: 0; height: 100%; width: 100%; border: none; }
      </style>
    </head>
    <body>
      <iframe src="${embedUrl}" width="100%" height="100%" frameborder="0" allowfullscreen></iframe>
    </body>
    </html>
  `;
  
  res.send(html);
});

// Route for displaying routes between points
app.get('/api/geocode/route', (req, res) => {
  const { from, to, mode = 'car' } = req.query;
  
  if (!from || !to) {
    return res.status(400).send('From and to coordinates are required');
  }
  
  // Determine which OSRM engine to use based on mode
  let engine = 'fossgis_osrm_car';
  if (mode === 'bike' || mode === 'bicycle') {
    engine = 'fossgis_osrm_bike';
  } else if (mode === 'foot' || mode === 'walking') {
    engine = 'fossgis_osrm_foot';
  }
  
  // Create the OpenStreetMap directions URL
  const routeUrl = `https://www.openstreetmap.org/directions?engine=${engine}&route=${from}%3B${to}&layer=mapnik`;
  
  // Set proper referrer and cache headers
  res.set({
    'Content-Type': 'text/html',
    'Cache-Control': 'public, max-age=3600'
  });
  
  // Create an HTML page that embeds the directions with the proper referrer
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Route</title>
      <style>
        body, html, iframe { margin: 0; padding: 0; height: 100%; width: 100%; border: none; }
      </style>
    </head>
    <body>
      <iframe src="${routeUrl}" width="100%" height="100%" frameborder="0" allowfullscreen></iframe>
    </body>
    </html>
  `;
  
  res.send(html);
});

// Restaurant location endpoint
app.get('/api/geocode/restaurant-locations', async (req, res) => {
  try {
    // Import Restaurant model dynamically
    const Restaurant = (await import('./models/Restaurant.js')).default;
    
    const { search, lat, lon, radius } = req.query;
    
    // Build query based on parameters
    const query = { isActive: true };
    
    // Filter by search term if provided
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { cuisine: { $regex: search, $options: 'i' } },
        { address: { $regex: search, $options: 'i' } }
      ];
    }
    
    // Get all restaurants matching the query
    const restaurants = await Restaurant.find(query).lean();
    
    // Filter by location and add distance if lat/lon/radius provided
    let filteredRestaurants = restaurants;
    
    if (lat && lon && radius) {
      const userLat = parseFloat(lat);
      const userLon = parseFloat(lon);
      const maxRadius = parseFloat(radius);
      
      // Earth radius in km
      const R = 6371;
      
      // Filter and calculate distance
      filteredRestaurants = restaurants
        .filter(restaurant => {
          // Skip restaurants without coordinates
          if (!restaurant.latitude || !restaurant.longitude) return false;
          
          // Calculate distance using Haversine formula
          const dLat = (restaurant.latitude - userLat) * Math.PI / 180;
          const dLon = (restaurant.longitude - userLon) * Math.PI / 180;
          const a = 
            Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(userLat * Math.PI / 180) * Math.cos(restaurant.latitude * Math.PI / 180) * 
            Math.sin(dLon/2) * Math.sin(dLon/2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
          const distance = R * c;
          
          // Add distance to restaurant object
          restaurant.distance = parseFloat(distance.toFixed(2));
          
          // Include only if within radius
          return distance <= maxRadius;
        })
        .sort((a, b) => a.distance - b.distance);
    }
    
    // For any restaurant without a valid address, try to get one
    const enrichedRestaurants = await Promise.all(filteredRestaurants.map(async restaurant => {
      // If the restaurant has coordinates but no address, try to get the address
      if (restaurant.latitude && restaurant.longitude && (!restaurant.address || restaurant.address === 'Unknown Address')) {
        const address = await reverseGeocode(restaurant.latitude, restaurant.longitude);
        if (address) {
          restaurant.address = address;
          
          // Optionally update the address in the database (uncomment if needed)
          // await Restaurant.findByIdAndUpdate(restaurant._id, { address });
        }
      }
      return restaurant;
    }));
    
    res.json(enrichedRestaurants);
  } catch (error) {
    console.error('Error fetching restaurant locations:', error);
    res.status(500).json({ error: 'Failed to fetch restaurant locations' });
  }
});

// All routes have been moved to their respective route files

// Error handling middleware
const errorHandler = (err, req, res, next) => {
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  console.error(`Error: ${err.message}`);
  res.status(statusCode).json({
    error: err.message,
    stack: process.env.NODE_ENV === 'production' ? null : err.stack
  });
};

// Start server
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// WebSocket setup
const io = new Server(server, {
  cors: {
    origin: '*', // Allow all origins (adjust as needed)
  },
});

// Online users tracking
const onlineUsers = new Map();

// Socket.io event handlers
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  // Handle user login
  socket.on('user_connected', async (userId) => {
    if (userId) {
      console.log(`User ${userId} is now online`);
      onlineUsers.set(userId, socket.id);

      // Broadcast to all clients that this user is online
      io.emit('user_status_change', { userId, status: 'online' });

      // Update the list of online users for the newly connected client
      const onlineUserIds = Array.from(onlineUsers.keys());
      socket.emit('online_users', onlineUserIds);
    }
  });

  // Handle user logout or disconnect
  const handleDisconnect = async (userId) => {
    if (userId) {
      console.log(`User ${userId} is now offline`);
      onlineUsers.delete(userId);

      // Broadcast to all clients that this user is offline
      io.emit('user_status_change', { userId, status: 'offline' });
    }
  };

  socket.on('user_disconnected', (userId) => {
    handleDisconnect(userId);
  });

  socket.on('disconnect', () => {
    console.log('A user disconnected:', socket.id);

    // Find the userId associated with this socket
    for (const [userId, socketId] of onlineUsers.entries()) {
      if (socketId === socket.id) {
        handleDisconnect(userId);
        break;
      }
    }
  });
});

// Apply error handling middleware
app.use(errorHandler);
