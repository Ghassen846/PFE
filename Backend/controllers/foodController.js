import Food from '../models/Food.js';
import mongoose from 'mongoose';

// Get all food items
export const getFoodItems = async (req, res) => {
  try {
    // Populate restaurant with its name
    const foods = await Food.find().populate('restaurant', 'name');
    res.json(foods);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get food item by ID
export const getFoodItemById = async (req, res) => {
  try {
    const food = await Food.findById(req.params.id);
    if (!food) {
      return res.status(404).json({ message: 'Food not found' });
    }
    res.json(food);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a new food item
export const createFoodItem = async (req, res) => {
  try {
    const foodData = req.body;

    // If an image was uploaded, add the path to the food data
    if (req.file) {
      foodData.imageUrl = `/uploads/foods/${req.file.filename}`;
    }

    // Ensure restaurant is provided
    if (!foodData.restaurant) {
      return res.status(400).json({ message: 'Restaurant ID is required' });
    }

    // Fetch restaurant details to populate restaurantDetails
    const Restaurant = mongoose.model('Restaurant');
    const restaurant = await Restaurant.findById(foodData.restaurant);

    if (!restaurant) {
      return res.status(400).json({ message: 'Restaurant not found' });
    }

    // Add restaurant details to food data
    foodData.restaurantDetails = {
      name: restaurant.name,
      address: restaurant.address,
      contact: restaurant.contact
    };

    const food = new Food(foodData);
    await food.save();

    res.status(201).json(food);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Update a food item
export const updateFoodItem = async (req, res) => {
  try {
    const foodData = req.body;

    // If an image was uploaded, add the path to the food data
    if (req.file) {
      foodData.imageUrl = `/uploads/foods/${req.file.filename}`;
    }

    // If restaurant is being updated, update restaurantDetails as well
    if (foodData.restaurant) {
      // Fetch restaurant details to populate restaurantDetails
      const Restaurant = mongoose.model('Restaurant');
      const restaurant = await Restaurant.findById(foodData.restaurant);

      if (!restaurant) {
        return res.status(400).json({ message: 'Restaurant not found' });
      }

      // Add restaurant details to food data
      foodData.restaurantDetails = {
        name: restaurant.name,
        address: restaurant.address,
        contact: restaurant.contact
      };
    }

    const food = await Food.findByIdAndUpdate(
      req.params.id,
      foodData,
      { new: true, runValidators: true }
    );

    if (!food) {
      return res.status(404).json({ message: 'Food item not found' });
    }

    res.json(food);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Delete a food item
export const deleteFoodItem = async (req, res) => {
  try {
    const food = await Food.findByIdAndDelete(req.params.id);
    if (!food) {
      return res.status(404).json({ message: 'Food not found' });
    }
    res.json({ message: 'Food deleted successfully', food });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Rate a food item
export const rateFood = async (req, res) => {
  try {
    const { id } = req.params; // Food ID
    const { clientId, rating } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const food = await Food.findById(id);
    if (!food) {
      return res.status(404).json({ message: 'Food not found' });
    }

    food.ratings.push({ clientId, rating });
    await food.save();

    res.status(200).json({ message: 'Food rated successfully', food });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
