import mongoose from 'mongoose';

const pointSettingsSchema = new mongoose.Schema({
  savePoints: { type: Number, default: 5 },
  sharePoints: { type: Number, default: 10 },
  referralGiverPoints: { type: Number, default: 50 },
  referralReceiverPoints: { type: Number, default: 30 },
}, { timestamps: true });

export default mongoose.models.PointSettings || mongoose.model('PointSettings', pointSettingsSchema);
