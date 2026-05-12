import mongoose from 'mongoose';

const rewardSchema = new mongoose.Schema({
  name: { type: String, required: true },
  points: { type: Number, required: true },
  available: { type: Boolean, default: true },
  redeemed: { type: Number, default: 0 },
  imageUrl: { type: String },
  description: { type: String },
  terms: { type: String },
  redeemCode: { type: String },
}, { timestamps: true });

// Clear cached model to ensure schema updates are applied
if (mongoose.models.Reward) {
  delete mongoose.models.Reward;
}

export default mongoose.model('Reward', rewardSchema);
