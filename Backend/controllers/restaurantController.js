import Restaurant from '../models/Restaurant.js';

// Get all restaurants
export const getRestaurants = async (req, res) => {
  try {
    const restaurants = await Restaurant.find();
    res.json(restaurants);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get restaurant by ID
export const getRestaurantById = async (req, res) => {
  try {
    const restaurant = await Restaurant.findById(req.params.id);
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }
    res.json(restaurant);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a new restaurant
export const createRestaurant = async (req, res) => {
  try {
    const restaurantData = { ...req.body };
    
    // Add image URL if file was uploaded
    if (req.file) {
      restaurantData.imageUrl = `/uploads/restaurants/${req.file.filename}`;
    }
    
    // Parse latitude and longitude if they're strings
    if (restaurantData.latitude) {
      restaurantData.latitude = parseFloat(restaurantData.latitude);
      
      // Make sure we don't save 0 as a default value when no real coordinates exist
      if (isNaN(restaurantData.latitude) || restaurantData.latitude === 0) {
        restaurantData.latitude = null;
      }
    }
    
    if (restaurantData.longitude) {
      restaurantData.longitude = parseFloat(restaurantData.longitude);
      
      // Make sure we don't save 0 as a default value when no real coordinates exist
      if (isNaN(restaurantData.longitude) || restaurantData.longitude === 0) {
        restaurantData.longitude = null;
      }
    }
    
    // Validate latitude and longitude
    if (restaurantData.latitude && (restaurantData.latitude < -90 || restaurantData.latitude > 90)) {
      return res.status(400).json({ message: 'Latitude must be between -90 and 90.' });
    }
    if (restaurantData.longitude && (restaurantData.longitude < -180 || restaurantData.longitude > 180)) {
      return res.status(400).json({ message: 'Longitude must be between -180 and 180.' });
    }
    
    // Set default Tunisia coordinates if both latitude and longitude are missing or invalid
    if (restaurantData.latitude === null || restaurantData.longitude === null) {
      console.log('Using default Tunisia coordinates for restaurant');
      restaurantData.latitude = 36.8065;
      restaurantData.longitude = 10.1815;
    }
    
    // Log the coordinates for debugging
    console.log(`Creating restaurant with coordinates: ${restaurantData.latitude}, ${restaurantData.longitude}`);
    
    const restaurant = new Restaurant(restaurantData);
    await restaurant.save();
    res.status(201).json(restaurant);
  } catch (err) {
    console.error('Error creating restaurant:', err);
    res.status(400).json({ message: err.message });
  }
};

// Update a restaurant
export const updateRestaurant = async (req, res) => {
  try {
    const restaurantData = { ...req.body };
    
    // Add image URL if file was uploaded
    if (req.file) {
      restaurantData.imageUrl = `/uploads/restaurants/${req.file.filename}`;
    }
    
    // Parse latitude and longitude if they're strings
    if (restaurantData.latitude) {
      restaurantData.latitude = parseFloat(restaurantData.latitude);
      
      // Make sure we don't save 0 as a default value when no real coordinates exist
      if (isNaN(restaurantData.latitude) || restaurantData.latitude === 0) {
        restaurantData.latitude = null;
      }
    }
    
    if (restaurantData.longitude) {
      restaurantData.longitude = parseFloat(restaurantData.longitude);
      
      // Make sure we don't save 0 as a default value when no real coordinates exist
      if (isNaN(restaurantData.longitude) || restaurantData.longitude === 0) {
        restaurantData.longitude = null;
      }
    }
    
    // Validate latitude and longitude
    if (restaurantData.latitude && (restaurantData.latitude < -90 || restaurantData.latitude > 90)) {
      return res.status(400).json({ message: 'Latitude must be between -90 and 90.' });
    }
    if (restaurantData.longitude && (restaurantData.longitude < -180 || restaurantData.longitude > 180)) {
      return res.status(400).json({ message: 'Longitude must be between -180 and 180.' });
    }
    
    // Set default Tunisia coordinates if both latitude and longitude are missing or invalid
    if (restaurantData.latitude === null || restaurantData.longitude === null) {
      console.log('Using default Tunisia coordinates for restaurant');
      restaurantData.latitude = 36.8065;
      restaurantData.longitude = 10.1815;
    }
    
    // Log the coordinates for debugging
    console.log(`Updating restaurant with coordinates: ${restaurantData.latitude}, ${restaurantData.longitude}`);
    
    const restaurant = await Restaurant.findByIdAndUpdate(
      req.params.id,
      restaurantData,
      { new: true, runValidators: true }
    );
    
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }
    
    res.status(200).json(restaurant);
  } catch (err) {
    console.error('Error updating restaurant:', err);
    res.status(400).json({ message: err.message });
  }
};

// Delete a restaurant
export const deleteRestaurant = async (req, res) => {
  try {
    const restaurant = await Restaurant.findByIdAndDelete(req.params.id);
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }
    res.json({ message: 'Restaurant deleted successfully', restaurant });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Rate a restaurant
export const rateRestaurant = async (req, res) => {
  try {
    const { id } = req.params; // Restaurant ID
    const { clientId, rating } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const restaurant = await Restaurant.findById(id);
    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurant not found' });
    }

    restaurant.ratings.push({ clientId, rating });
    await restaurant.save();

    res.status(200).json({ message: 'Restaurant rated successfully', restaurant });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
