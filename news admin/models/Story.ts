import mongoose from 'mongoose';

// Delete existing model to force schema update
if (mongoose.models.Story) {
  delete mongoose.models.Story;
}

const StorySchema = new mongoose.Schema({
  storyName: String,
  heading: String,
  description: String,
  image: String,
  videoUrl: String,
  thumbnail: String,
  mediaItems: [],
  autoDeleteType: String,
  deleteAfterHours: Number,
  deleteAfterDate: String,
  active: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
}, { strict: false });

export default mongoose.model('Story', StorySchema);
