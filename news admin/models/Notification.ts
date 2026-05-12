import mongoose from 'mongoose';

const NotificationSchema = new mongoose.Schema({
  contentId: { type: mongoose.Schema.Types.ObjectId },
  contentType: { type: String, enum: ['News', 'Story', 'Reel'], required: true },
  translations: {
    english: {
      title: { type: String },
      message: { type: String }
    },
    hindi: {
      title: { type: String },
      message: { type: String }
    },
    bengali: {
      title: { type: String },
      message: { type: String }
    }
  },
  link: { type: String },
  audience: {
    allUsers: { type: Boolean, default: false },
    languages: [{ type: String, enum: ['EN', 'HIN', 'BEN'] }]
  },
  status: { type: String, enum: ['sent', 'scheduled', 'failed'], default: 'sent' },
  scheduledFor: { type: Date },
  sentAt: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.models.Notification || mongoose.model('Notification', NotificationSchema);
