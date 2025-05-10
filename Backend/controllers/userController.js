import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import fetch from 'node-fetch';
import Delivery from '../models/Delivery.js';
import User from '../models/User.js';

// Get all users
export const getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select('-password');

    // Add address field using reverse geocoding if available
    const reverseGeocode = async (lat, lon) => {
      try {
        const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`;
        const response = await fetch(url, {
          headers: { 'User-Agent': 'pfe-update-backend/1.0' }
        });
        if (!response.ok) return null;
        const data = await response.json();
        return data.display_name || null;
      } catch (err) {
        return null;
      }
    };

    // Add address information if location data is available
    const usersWithAddress = await Promise.all(users.map(async user => {
      let address = null;
      if (user.location && user.location.latitude && user.location.longitude) {
        address = await reverseGeocode(user.location.latitude, user.location.longitude);
      }
      return { ...user.toObject(), address };
    }));

    res.json(usersWithAddress);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ message: err.message });
  }
};

// Get users by role
export const getUsersByRole = async (req, res) => {
  try {
    const { role } = req.params;
    const users = await User.find({ role }).select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update user
export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Don't allow password updates through this route
    if (updates.password) {
      delete updates.password;
    }

    // Check if updating a livreur profile
    const isLivreur = await User.findById(id).select('role');
    
    // Format updates for mongoose 
    const formattedUpdates = { ...updates };
    
    // Format location if provided
    if (updates.location) {
      formattedUpdates.location = {
        latitude: parseFloat(updates.location.latitude) || 0,
        longitude: parseFloat(updates.location.longitude) || 0
      };
    }
    
    // Handle vehicle updates
    if (updates.vehicle) {
      formattedUpdates.vehicle = updates.vehicle;
    }

    // Get the updated user with proper population and handle image formatting
    const user = await User.findByIdAndUpdate(
      id, 
      formattedUpdates, 
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Format image URL
    let image = user.image;
    if (image && !/^https?:\/\//.test(image)) {
      image = `http://localhost:5000/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }
    
    // Calculate and add livreur stats if needed
    let livreurStats = null;
    if (user.role === 'livreur') {
      livreurStats = await calculateLivreurStats(user._id);
    }
    
    // Create a proper response object
    const userObj = user.toObject();
    delete userObj.password;
    
    // Return a well-formatted response
    res.json({ 
      message: 'User updated successfully',
      user: {
        ...userObj,
        image,
        livreurStats: user.role === 'livreur' ? livreurStats : undefined
      }
    });
  } catch (err) {
    console.error('Error updating user:', err);
    res.status(500).json({ message: err.message });
  }
};

// Delete user
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndDelete(id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

export const registerUser = async (req, res) => {
  try {
    console.log('Register request body:', req.body);
    console.log('Register request file:', req.file);

    if (!req.body) {
      console.error('No request body received');
      return res.status(400).json({ message: 'Request body is missing' });
    }

    // Parse fields from req.body (handle both JSON and multipart/form-data)
    let {
      username,
      firstName,
      name,
      email,
      password,
      phone,
      location,
      role,
      vehiculetype, // <-- add this
      status        // <-- add this
    } = req.body;

    // Default role to 'client' if not provided
    if (!role) {
      role = 'client';
    }

    // Parse location if sent as fields
    if (
      (!location || typeof location !== 'object') &&
      (req.body['location[latitude]'] !== undefined || req.body['location[longitude]'] !== undefined)
    ) {
      location = {
        latitude: parseFloat(req.body['location[latitude]']) || 0,
        longitude: parseFloat(req.body['location[longitude]']) || 0,
      };
      console.log('Parsed location from fields:', location);
    }

    // Ensure vehiculetype and status are extracted for livreur
    if (role === 'livreur') {
      vehiculetype = req.body.vehiculetype || vehiculetype;
      status = req.body.status || status;
      if (!vehiculetype || !status) {
        return res.status(400).json({ message: 'vehiculetype and status are required for livreur' });
      }
    }

    if (!phone) {
      console.error('Phone number is missing');
      return res.status(400).json({ message: 'Phone number is required' });
    }

    if (!/^(\+216)?[2459][0-9]{7}$/.test(phone)) {
      console.error('Invalid Tunisian phone number:', phone);
      return res.status(400).json({ message: 'Invalid Tunisian phone number format' });
    }

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      console.error('User already exists:', email);
      return res.status(400).json({ message: 'User already exists' });
    }

    // Create a new user
    const user = new User({
      username,
      firstName,
      name,
      email,
      password,
      phone,
      location: {
        latitude: location?.latitude || 0,
        longitude: location?.longitude || 0,
      },
      role,
      vehiculetype: role === 'livreur' ? vehiculetype : undefined,
      status: role === 'livreur' ? status : undefined,
      image: req.file ? req.file.filename : '', // <-- store the saved filename
    });

    // Save the user to the database
    await user.save();

    console.log('User registered successfully:', user._id);

    res.status(201).json({ message: 'User registered successfully', user });
  } catch (err) {
    console.error('Error registering user:', err.message, err);
    res.status(500).json({ message: 'Error registering user', error: err.message });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Generate a token and respond with user details
    res.json({
      _id: user._id,
      username: user.username,
      firstName: user.firstName,
      name: user.name,
      email: user.email,
      role: user.role,
      token: generateToken(user._id),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

export const getProfile = async (req, res) => {
  try {
    // Debug log to check if the middleware sets req.user
    console.log("getProfile: req.user =", req.user);
    const user = await User.findById(req.user._id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    let image = user.image;
    if (image && !/^https?:\/\//.test(image)) {
      image = `http://localhost:5000/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }
    res.json({ ...user.toObject(), image });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

export const getUserProfile = async (req, res) => {
  try {
    const userId = req.params.id;
    const user = await User.findById(userId).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    let image = user.image;
    if (image && !/^https?:\/\//.test(image)) {
      image = `http://localhost:5000/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }
    res.json({ ...user.toObject(), image });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Add or update vehicle info for livreur
export const updateVehicle = async (req, res) => {
  try {
    const { id } = req.params;
    const { vehicle } = req.body;
    const user = await User.findByIdAndUpdate(id, { vehicle }, { new: true });
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Add maintenance record
export const addMaintenance = async (req, res) => {
  try {
    const { id } = req.params; // user id
    const { maintenance } = req.body;
    const user = await User.findById(id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (!user.vehicle) user.vehicle = {};
    if (!user.vehicle.maintenanceHistory) user.vehicle.maintenanceHistory = [];
    user.vehicle.maintenanceHistory.push(maintenance);
    await user.save();
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

/**
 * Calculate stats for a livreur (deliveries completed, average rating, etc.)
 * @param {ObjectId} livreurId
 * @returns {Promise<Object>} stats
 */
async function calculateLivreurStats(livreurId) {
  const Delivery = (await import('../models/Delivery.js')).default;
  const deliveries = await Delivery.find({ driver: livreurId, status: 'delivered' });
  const completed = deliveries.length;
  const ratings = deliveries.map(d => d.rating).filter(r => typeof r === 'number');
  const avgRating = ratings.length ? (ratings.reduce((a, b) => a + b, 0) / ratings.length) : 0;
  // Add more stats as needed
  return {
    deliveriesCompleted: completed,
    rating: avgRating,
    // ...other stats
  };
}

// Add a new user (admin function)
export const addUser = async (req, res) => {
  const { username, firstName, name, email, password, phone, location, role, image, verified, vehiculetype, status, vehiculedocuments } = req.body;

  if (!name || !email || !password || !location || location.latitude === undefined || location.longitude === undefined) {
    return res.status(400).json({ 
      message: "Name, email, password, and valid location (latitude, longitude) are required" 
    });
  }

  try {
    // Check if the email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email already exists" });
    }

    const newUser = new User({
      username,
      firstName,
      name,
      email,
      password,
      phone,
      location,
      role,
      image,
      verified,
      vehiculetype: role === 'livreur' ? vehiculetype : undefined,
      status: role === 'livreur' ? status : undefined,
      vehiculedocuments: role === 'livreur' ? vehiculedocuments : undefined
    });

    await newUser.save();

    if (newUser.role === 'livreur') {
      const newDelivery = new Delivery({
        order: null,
        driver: newUser._id,
        status: 'pending',
        deliveredAt: null
      });
      await newDelivery.save();
    }

    // Convert to object and remove password
    const userObj = newUser.toObject();
    delete userObj.password;

    res.status(201).json({ 
      message: `User ${name} has been added`, 
      user: userObj 
    });
  } catch (error) {
    console.error('Error adding user:', error.message);
    res.status(500).json({ message: 'Error adding user' });
  }
};

// Get user by ID
export const getUserById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    let image = user.image;
    if (image && !/^https?:\/\//.test(image)) {
      image = `http://localhost:5000/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }
    let address = null;
    if (user.location && user.location.latitude && user.location.longitude) {
      address = await reverseGeocode(user.location.latitude, user.location.longitude);
    }
    const userObj = user.toObject();
    // Ensure password is removed even if select didn't work
    delete userObj.password;
    res.json({ ...userObj, image, address });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ message: 'Error fetching user' });
  }
};

// Rate a livreur
export const rateLivreur = async (req, res) => {
  try {
    const { id } = req.params; // Livreur ID
    const { clientId, rating } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const livreur = await User.findById(id);
    if (!livreur || livreur.role !== 'livreur') {
      return res.status(404).json({ message: 'Livreur not found' });
    }

    livreur.ratings.push({ clientId, rating });
    await livreur.save();

    // Convert to object and remove password
    const livreurObj = livreur.toObject();
    delete livreurObj.password;

    res.status(200).json({ message: 'Livreur rated successfully', livreur: livreurObj });
  } catch (error) {
    console.error('Error rating livreur:', error);
    res.status(500).json({ message: 'Error rating livreur' });
  }
};

// Get current user
export const getCurrentUser = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    let image = user.image;
    if (image && !/^https?:\/\//.test(image)) {
      image = `http://localhost:5000/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }
    const userObj = user.toObject();
    // Ensure password is removed even if select didn't work
    delete userObj.password;
    res.json({ ...userObj, image });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Helper function for reverse geocoding
const reverseGeocode = async (lat, lon) => {
  try {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`;
    const response = await fetch(url, {
      headers: { 'User-Agent': 'pfe-update-backend/1.0' }
    });
    if (!response.ok) return null;
    const data = await response.json();
    return data.display_name || null;
  } catch (err) {
    return null;
  }
};

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};
