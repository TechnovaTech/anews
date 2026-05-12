const mongoose = require('mongoose');

async function addWalletToUsers() {
  await mongoose.connect('mongodb://localhost:27017/asiazenews');
  
  const result = await mongoose.connection.db.collection('users').updateMany(
    { wallet: { $exists: false } },
    { 
      $set: { 
        wallet: {
          balance: 0,
          savePoints: 0,
          sharePoints: 0,
          referralPoints: 0,
          transactions: 0,
          referrals: 0
        }
      }
    }
  );
  
  console.log(`✅ Added wallet field to ${result.modifiedCount} users`);
  await mongoose.disconnect();
}

addWalletToUsers().catch(console.error);
