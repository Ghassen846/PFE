import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import generateToken from '../utils/generateToken.js';
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
      
      // Convert Mongoose document to plain object and add address
      const userObj = user.toObject();
      userObj.address = address;
        // Ensure image path is in the correct format
      if (userObj.image && !userObj.image.startsWith('/')) {
        userObj.image = `/uploads/${userObj.image.replace(/^uploads[\\/]/, '')}`;
      }
      
      return userObj;
    }));

    res.status(200).json(usersWithAddress);
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ message: 'Failed to get users' });
  }
};

// Get user by ID
export const getUserById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }

    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Enhance with address information if location exists
    let address = null;
    if (user.location && user.location.latitude && user.location.longitude) {
      address = await reverseGeocode(user.location.latitude, user.location.longitude);
    }    // Fix image URL
    let image = user.image;
    if (image && !image.startsWith('/')) {
      image = `/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }

    const userObj = user.toObject();
    userObj.address = address;
    userObj.image = image;

    res.status(200).json(userObj);
  } catch (error) {
    console.error('Error getting user by ID:', error);
    res.status(500).json({ message: 'Failed to get user details' });
  }
};

// Create a new user (registration)
export const registerUser = async (req, res) => {  try {
    const {
      username,
      firstName,
      name,
      email,
      password,
      phone,
      role,
      vehiculetype,
      status,
    } = req.body;

    // Handle location data - ensure we convert to numbers
    let latitude = 0;
    let longitude = 0;
    
    // Check for nested location object first
    if (req.body.location) {
      latitude = parseFloat(req.body.location.latitude) || 0;
      longitude = parseFloat(req.body.location.longitude) || 0;
    } else {
      // Handle various formats that might come from the app
      latitude = parseFloat(req.body['location[latitude]'] || req.body.latitude || 0);
      longitude = parseFloat(req.body['location[longitude]'] || req.body.longitude || 0);
    }

    // Check for existing email
    const existingEmail = await User.findOne({ email });
    if (existingEmail) {
      return res.status(400).json({ message: 'Email already in use.' });
    }

    // Check for existing username
    const existingUsername = await User.findOne({ username });
    if (existingUsername) {
      return res.status(400).json({ message: 'Username already taken.' });
    }

    // Create the user
    const user = await User.create({
      username,
      firstName,
      name, // Map LastName to name field
      email,
      password, // Will be hashed by the pre-save hook
      phone,
      role: role || 'livreur', // Default to livreur if not specified
      location: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
      },
      vehiculetype: vehiculetype || undefined,
      status: status || 'available', // Default status
      isOnline: true // Set as online when registering
    });    // Generate JWT token
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || 'your_jwt_secret', {
      expiresIn: '30d',
    });
    
    console.log(`User registered with ID: ${user._id}`);    // Return user data (excluding password)
    const userWithoutPassword = {
      _id: user._id,
      username: user.username,
      firstName: user.firstName,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      location: user.location,
      vehiculetype: user.vehiculetype,
      status: user.status,
      token,
      isOnline: user.isOnline
    };

    console.log(`User registration successful: ${user.email} (ID: ${user._id})`);
    console.log(`Response data: ${JSON.stringify(userWithoutPassword)}`);
    res.status(201).json(userWithoutPassword);
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ message: 'Failed to register user', error: error.message });
  }
};

// Update a user
export const updateUser = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }

    // Check for user's existence
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // If trying to update email, check if the new email is already in use
    if (req.body.email && req.body.email !== user.email) {
      const existingEmail = await User.findOne({ email: req.body.email });
      if (existingEmail) {
        return res.status(400).json({ message: 'Email already in use.' });
      }
    }

    // If trying to update username, check if the new username is already in use
    if (req.body.username && req.body.username !== user.username) {
      const existingUsername = await User.findOne({ username: req.body.username });
      if (existingUsername) {
        return res.status(400).json({ message: 'Username already taken.' });
      }
    }

    // Handle location update if provided
    let locationUpdate = {};
    if (req.body.latitude !== undefined && req.body.longitude !== undefined) {
      locationUpdate = {
        location: {
          latitude: parseFloat(req.body.latitude),
          longitude: parseFloat(req.body.longitude)
        }
      };
    }

    // Combine updates
    const updates = {
      ...req.body,
      ...locationUpdate
    };

    // Don't let the password be updated through this endpoint
    delete updates.password;

    // Update the user
    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { $set: updates },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found after update attempt' });
    }    // Fix image URL
    let image = updatedUser.image;
    if (image && !image.startsWith('/')) {
      image = `/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }

    const userObj = updatedUser.toObject();
    userObj.image = image;

    res.status(200).json(userObj);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ message: 'Failed to update user', error: error.message });
  }
};

// Delete a user
export const deleteUser = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid user ID format' });
    }

    const deletedUser = await User.findByIdAndDelete(req.params.id);
    if (!deletedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Failed to delete user' });
  }
};

// Login a user
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
      // Fix image URL
    let imageUrl = null;
    if (user.image) {
      if (user.image.startsWith('/')) {
        imageUrl = user.image;
      } else {
        // Make sure to use relative path
        imageUrl = `/uploads/${user.image.replace(/^uploads[\\/]/, '')}`;
      }
    }
    
    const token = generateToken(user._id);
    
    // Update user to be online
    user.isOnline = true;
    user.lastActive = new Date();
    await user.save();
    
    res.status(200).json({
      _id: user._id,
      username: user.username,
      firstName: user.firstName,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      image: imageUrl,
      token,
      isOnline: true
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: error.message });
  }
};

// Change password
export const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user._id;

    // Find the user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if current password is correct
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    // Update the password
    user.password = newPassword; // Will be hashed by pre-save hook
    await user.save();

    res.status(200).json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ message: 'Failed to change password' });
  }
};    // Get all livreurs
export const getAllLivreurs = async (req, res) => {
  try {
    const livreurs = await User.find({ role: 'livreur' }).select('-password');

    // Add address field using reverse geocoding if available
    const livreursWithAddress = await Promise.all(livreurs.map(async livreur => {
      let address = null;
      if (livreur.location && livreur.location.latitude && livreur.location.longitude) {
        address = await reverseGeocode(livreur.location.latitude, livreur.location.longitude);
      }
      
      // Fix image URL
      let image = livreur.image;
      if (image && !image.startsWith('/')) {
        image = `/uploads/${image.replace(/^uploads[\\/]/, '')}`;
      }
      
      const livreurObj = livreur.toObject();
      livreurObj.address = address;
      livreurObj.image = image;
      
      return livreurObj;
    }));

    res.status(200).json(livreursWithAddress);
  } catch (error) {
    console.error('Error getting livreurs:', error);
    res.status(500).json({ message: 'Failed to get livreurs' });
  }
};    // Get all available livreurs
export const getAvailableLivreurs = async (req, res) => {
  try {
    const availableLivreurs = await User.find({
      role: 'livreur',
      status: 'available'
    }).select('-password');

    // Add address field using reverse geocoding if available
    const livreursWithAddress = await Promise.all(availableLivreurs.map(async livreur => {
      let address = null;
      if (livreur.location && livreur.location.latitude && livreur.location.longitude) {
        address = await reverseGeocode(livreur.location.latitude, livreur.location.longitude);
      }
      
      // Fix image URL
      let image = livreur.image;
      if (image && !image.startsWith('/')) {
        image = `/uploads/${image.replace(/^uploads[\\/]/, '')}`;
      }
      
      const livreurObj = livreur.toObject();
      livreurObj.address = address;
      livreurObj.image = image;
      
      return livreurObj;
    }));

    res.status(200).json(livreursWithAddress);
  } catch (error) {
    console.error('Error getting available livreurs:', error);
    res.status(500).json({ message: 'Failed to get available livreurs' });
  }
};

// Rate a livreur
export const rateLivreur = async (req, res) => {
  try {
    const { rating } = req.body;
    const livreurId = req.params.id;
    const clientId = req.user._id; // Assuming authentication middleware sets req.user

    // Validate the rating value
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    // Find the livreur
    const livreur = await User.findById(livreurId);
    if (!livreur) {
      return res.status(404).json({ message: 'Livreur not found' });
    }

    // Check if this client has already rated this livreur
    const existingRatingIndex = livreur.ratings.findIndex(
      r => r.clientId.toString() === clientId.toString()
    );

    if (existingRatingIndex >= 0) {
      // Update existing rating
      livreur.ratings[existingRatingIndex].rating = rating;
    } else {
      // Add new rating
      livreur.ratings.push({ clientId, rating });
    }

    // Calculate average rating
    const totalRating = livreur.ratings.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / livreur.ratings.length;

    // Update livreur stats with new average rating
    if (!livreur.livreurStats) {
      livreur.livreurStats = {};
    }
    livreur.livreurStats.rating = averageRating;

    await livreur.save();    // Fix image URL
    let image = livreur.image;
    if (image && !image.startsWith('/')) {
      image = `/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }

    const livreurObj = livreur.toObject();
    livreurObj.image = image;
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
    }    let image = user.image;
    if (image && !image.startsWith('/')) {
      image = `/uploads/${image.replace(/^uploads[\\/]/, '')}`;
    }
    const userObj = user.toObject();
    // Ensure password is removed even if select didn't work
    delete userObj.password;
    res.json({ ...userObj, image });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update user's online status
export const updateOnlineStatus = async (req, res) => {
  try {
    const { userId, isOnline } = req.body;
    
    console.log('[Backend] Update online status request:', req.body);
    
    if (!userId) {
      console.log('[Backend] Missing userId in request body');
      return res.status(400).json({ message: 'User ID is required' });
    }
    
    if (typeof isOnline !== 'boolean') {
      console.log('[Backend] Invalid isOnline value:', isOnline);
      return res.status(400).json({ message: 'isOnline must be a boolean value' });
    }
    
    const user = await User.findById(userId);
    if (!user) {
      console.log('[Backend] User not found with ID:', userId);
      return res.status(404).json({ message: 'User not found' });
    }
    
    user.isOnline = isOnline;
    user.lastActive = new Date(); // Update last active timestamp
    await user.save();
    
    console.log(`[Backend] User ${userId} online status updated to ${isOnline}`);
    
    res.status(200).json({ 
      message: `Online status updated to ${isOnline ? 'online' : 'offline'}`,
      isOnline: user.isOnline,
      lastActive: user.lastActive
    });
  } catch (error) {
    console.error('[Backend] Error updating online status:', error);
    res.status(500).json({ message: 'Failed to update online status', error: error.message });
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
