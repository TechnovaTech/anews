import mongoose from 'mongoose';

const CategorySchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  slug: { type: String, required: true, unique: true },
  description: { type: String },
  labels: {
    english: { type: String, default: '' },
    hindi: { type: String, default: '' },
    bengali: { type: String, default: '' }
  },
  icon: { type: String },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, { minimize: false });

export default mongoose.models.Category || mongoose.model('Category', CategorySchema);
