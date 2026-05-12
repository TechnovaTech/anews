import mongoose from 'mongoose';

const AdvertisementSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
  },
  imageUrl: {
    type: String,
    default: '',
  },
  videoUrl: {
    type: String,
    default: '',
  },
  adType: {
    type: String,
    enum: ['image', 'video'],
    default: 'image',
  },
  clickUrl: {
    type: String,
    required: true,
  },
  position: {
    type: String,
    enum: ['banner', 'sidebar', 'inline', 'popup'],
    default: 'banner',
  },
  showInArticles: {
    type: Boolean,
    default: false,
  },
  showInReels: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'scheduled'],
    default: 'active',
  },
  startDate: {
    type: Date,
  },
  endDate: {
    type: Date,
  },
  clicks: {
    type: Number,
    default: 0,
  },
  impressions: {
    type: Number,
    default: 0,
  },
}, {
  timestamps: true,
});

export default mongoose.models.Advertisement || mongoose.model('Advertisement', AdvertisementSchema);
