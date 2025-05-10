import mongoose from 'mongoose';

const settingsSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    notifications: {
      emailNotifications: {
        type: Boolean,
        default: true
      },
      pushNotifications: {
        type: Boolean,
        default: false
      },
      orderUpdates: {
        type: Boolean,
        default: true
      },
      marketingEmails: {
        type: Boolean,
        default: false
      },
      systemAlerts: {
        type: Boolean,
        default: true
      }
    },
    security: {
      twoFactorAuth: {
        type: Boolean,
        default: false
      },
      loginAlerts: {
        type: Boolean,
        default: true
      },
      dataEncryption: {
        type: Boolean,
        default: true
      }
    },
    appearance: {
      darkMode: {
        type: Boolean,
        default: false
      },
      compactView: {
        type: Boolean,
        default: false
      },
      highContrast: {
        type: Boolean,
        default: false
      }
    },
    system: {
      autoBackup: {
        type: Boolean,
        default: true
      },
      dataRetention: {
        type: String,
        default: '90'
      },
      errorReporting: {
        type: Boolean,
        default: true
      }
    }
  },
  {
    timestamps: true
  }
);

// Ensure each user has only one settings document
settingsSchema.index({ user: 1 }, { unique: true });

const Settings = mongoose.model('Settings', settingsSchema);

export default Settings;