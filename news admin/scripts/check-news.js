const mongoose = require('mongoose');
const fs = require('fs');

const envContent = fs.readFileSync('.env.local', 'utf8');
const MONGODB_URI = envContent.match(/MONGODB_URI=(.+)/)[1].trim();

async function checkNews() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB\n');

    const db = mongoose.connection.db;
    const news = await db.collection('news').findOne({ _id: new mongoose.Types.ObjectId('69157a577438c4237141a36e') });
    
    console.log('Languages:', news.languages);
    console.log('Translations:', JSON.stringify(news.translations, null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkNews();
