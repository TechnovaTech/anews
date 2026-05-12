import mongoose from 'mongoose';

const ReelSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  fullArticleLink: { type: String },
  videoUrl: { type: String, required: true },
  thumbnail: { type: String },
  category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
  language: { type: String, enum: ['EN', 'HIN', 'BEN'], default: 'EN' },
  tags: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' }],
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  status: { type: String, enum: ['draft', 'published', 'archived'], default: 'draft' },
  featured: { type: Boolean, default: false },
  enableComments: { type: Boolean, default: true },
  views: { type: Number, default: 0 },
  likes: { type: Number, default: 0 },
  saves: { type: Number, default: 0 },
  publishedAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.models.Reel || mongoose.model('Reel', ReelSchema);
