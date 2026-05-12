const mongoose = require('mongoose');
const fs = require('fs');

// Read .env.local
const envContent = fs.readFileSync('.env.local', 'utf8');
const MONGODB_URI = envContent.match(/MONGODB_URI=(.+)/)[1].trim();

const NewsSchema = new mongoose.Schema({
  title: String,
  content: String,
  summary: String,
  explanation: String,
  image: String,
  category: mongoose.Schema.Types.ObjectId,
  tags: [mongoose.Schema.Types.ObjectId],
  status: String,
  views: Number,
  language: String,
  languages: [String],
  translations: mongoose.Schema.Types.Mixed,
  source: String,
  publishedAt: Date,
  createdAt: Date,
  updatedAt: Date
});

const News = mongoose.models.News || mongoose.model('News', NewsSchema);

async function fixLanguages() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const allNews = await News.find({});
    console.log(`Found ${allNews.length} news items`);

    for (const news of allNews) {
      if (!news.languages || news.languages.length === 0) {
        news.languages = ['EN'];
        news.translations = {
          EN: {
            title: news.title,
            content: news.content,
            summary: news.summary,
            explanation: news.explanation
          }
        };
        news.markModified('translations');
        await news.save();
        console.log(`Fixed news: ${news._id}`);
      }
    }

    console.log('Done!');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

fixLanguages();
