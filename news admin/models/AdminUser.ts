import mongoose from 'mongoose'

const AdminUserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true
  },
  mobile: {
    type: String,
    required: true,
    trim: true
  },
  roleName: {
    type: String,
    required: true,
    trim: true
  },
  modules: {
    news: { type: Boolean, default: false },
    stories: { type: Boolean, default: false },
    reels: { type: Boolean, default: false },
    categories: { type: Boolean, default: false },
    users: { type: Boolean, default: false },
    notifications: { type: Boolean, default: false },
    rewards: { type: Boolean, default: false },
    analytics: { type: Boolean, default: false },
    ads: { type: Boolean, default: false }
  },
  status: {
    type: String,
    enum: ['Active', 'Inactive'],
    default: 'Active'
  }
}, {
  timestamps: true
})

export default mongoose.models.AdminUser || mongoose.model('AdminUser', AdminUserSchema)