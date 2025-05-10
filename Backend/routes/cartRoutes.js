import express from "express";
import Cart from "../models/Cart.js";
import { protect } from "../middleware/auth.js"; // Import middleware

const router = express.Router();

// Only return cart items for the logged-in user
router.get("/", protect, async (req, res) => {
  try {
    const userId = req.user.id;
    const cartItems = await Cart.find({ user: userId }).populate("food");
    res.json(cartItems);
  } catch (error) {
    res.status(500).json({ error: "Error fetching cart items" });
  }
});

router.get("/count", async (req, res) => {
  const count = await Cart.countDocuments();
  res.json({ count });
});

router.post("/", async (req, res) => {
  const { userId, foodId, quantity } = req.body;
  const cartItem = new Cart({ user: userId, food: foodId, quantity });
  await cartItem.save();
  res.status(201).json(cartItem);
});

router.post("/add", protect, async (req, res) => {
  const { foodId, quantity } = req.body;

  try {
    const userId = req.user.id; // Extract user ID from token
    const existingCartItem = await Cart.findOne({ user: userId, food: foodId });
    if (existingCartItem) {
      existingCartItem.quantity += quantity;
      await existingCartItem.save();
      return res.status(200).json(existingCartItem);
    }

    const cartItem = new Cart({ user: userId, food: foodId, quantity });
    await cartItem.save();
    res.status(201).json(cartItem);
  } catch (error) {
    console.error("Error adding to cart:", error);
    res.status(500).json({ error: "Error adding to cart" });
  }
});

router.delete("/:id", async (req, res) => {
  await Cart.findByIdAndDelete(req.params.id);
  res.status(204).send();
});

export default router;
