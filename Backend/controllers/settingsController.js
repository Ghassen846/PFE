import Settings from '../models/Settings.js';

// Get settings for the current user
export const getSettings = async (req, res) => {
  try {
    const userId = req.user._id;
    
    // Find existing settings for the user
    let settings = await Settings.findOne({ user: userId });
    
    // If no settings exist yet, create default settings
    if (!settings) {
      settings = new Settings({ user: userId });
      await settings.save();
    }
    
    // Return settings without the user ID and mongoose metadata
    const settingsObj = settings.toObject();
    delete settingsObj._id;
    delete settingsObj.user;
    delete settingsObj.__v;
    delete settingsObj.createdAt;
    delete settingsObj.updatedAt;
    
    res.json(settingsObj);
  } catch (error) {
    console.error('Error fetching settings:', error);
    res.status(500).json({ message: 'Failed to fetch settings' });
  }
};

// Update settings for the current user
export const updateSettings = async (req, res) => {
  try {
    const userId = req.user._id;
    const updatedSettings = req.body;
    
    // Find and update settings, create if doesn't exist
    let settings = await Settings.findOneAndUpdate(
      { user: userId },
      {
        $set: {
          notifications: updatedSettings.notifications,
          security: updatedSettings.security,
          appearance: updatedSettings.appearance,
          system: updatedSettings.system
        }
      },
      { new: true, upsert: true } // Return updated doc and create if doesn't exist
    );
    
    // Return settings without the user ID and mongoose metadata
    const settingsObj = settings.toObject();
    delete settingsObj._id;
    delete settingsObj.user;
    delete settingsObj.__v;
    delete settingsObj.createdAt;
    delete settingsObj.updatedAt;
    
    res.json(settingsObj);
  } catch (error) {
    console.error('Error updating settings:', error);
    res.status(500).json({ message: 'Failed to update settings' });
  }
};