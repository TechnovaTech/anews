const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');

async function seedAdmin() {
  const client = new MongoClient('mongodb://localhost:27017/asiazenews');
  
  try {
    await client.connect();
    const db = client.db();
    
    // Check if admin already exists
    const existingAdmin = await db.collection('adminusers').findOne({ email: 'admin@gmail.com' });
    
    if (existingAdmin) {
      console.log('Admin user already exists');
      return;
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash('admin123', 12);
    
    // Create super admin
    const superAdmin = {
      name: 'Super Admin',
      email: 'admin@gmail.com',
      password: hashedPassword,
      mobile: '',
      roleName: 'Super Admin',
      modules: {
        news: true,
        stories: true,
        reels: true,
        categories: true,
        users: true,
        notifications: true,
        rewards: true,
        analytics: true,
        ads: true
      },
      status: 'Active',
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    await db.collection('adminusers').insertOne(superAdmin);
    console.log('Super admin created successfully');
    console.log('Email: admin@gmail.com');
    console.log('Password: admin123');
    
  } catch (error) {
    console.error('Seed failed:', error);
  } finally {
    await client.close();
  }
}

seedAdmin();