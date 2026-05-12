import mongoose from 'mongoose';

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  password: { type: String, required: true },
  googleId: { type: String },
  facebookId: { type: String },
  state: { type: String },
  role: { type: String, enum: ['admin', 'editor', 'user'], default: 'user' },
  preferences: {
    language: { type: String, default: 'EN' },
    categories: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Category' }]
  },
  walletBalance: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.models.User || mongoose.model('User', UserSchema);
