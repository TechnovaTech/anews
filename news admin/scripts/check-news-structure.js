const mongoose = require('mongoose');

async function checkNews() {
  try {
    await mongoose.connect('mongodb://localhost:27017/asiaze-news');
    console.log('Connected to database');
    
    const news = await mongoose.connection.db.collection('news').findOne({});
    
    if (news) {
      console.log('\n=== Sample News Document ===');
      console.log('Title:', news.title);
      console.log('Languages:', news.languages);
      console.log('Language (single):', news.language);
      console.log('\nTranslations structure:');
      console.log(JSON.stringify(news.translations, null, 2));
    } else {
      console.log('No news found in database');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkNews();
