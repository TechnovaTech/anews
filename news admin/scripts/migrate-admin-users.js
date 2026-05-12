const { MongoClient } = require('mongodb');

async function migrateAdminUsers() {
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017/asiaze-news');
  
  try {
    await client.connect();
    const db = client.db();
    
    // Find admin users from users collection
    const adminUsers = await db.collection('users').find({ 
      role: { $in: ['admin', 'super_admin', 'editor'] } 
    }).toArray();
    
    console.log(`Found ${adminUsers.length} admin users to migrate`);
    
    // Migrate each admin user
    for (const user of adminUsers) {
      const adminUser = {
        name: user.name,
        email: user.email,
        password: user.password,
        mobile: user.mobile || '',
        roleName: user.role === 'super_admin' ? 'Super Admin' : 
                 user.role === 'admin' ? 'Admin' : 'Editor',
        modules: {
          news: true,
          stories: true,
          reels: true,
          categories: true,
          users: user.role === 'super_admin' || user.role === 'admin',
          notifications: true,
          rewards: user.role === 'super_admin' || user.role === 'admin',
          analytics: user.role === 'super_admin' || user.role === 'admin',
          ads: user.role === 'super_admin' || user.role === 'admin'
        },
        status: user.isActive ? 'Active' : 'Inactive',
        createdAt: user.createdAt || new Date(),
        updatedAt: new Date()
      };
      
      // Insert into adminusers collection
      await db.collection('adminusers').insertOne(adminUser);
      console.log(`Migrated: ${user.email}`);
    }
    
    console.log('Migration completed successfully');
    
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await client.close();
  }
}

migrateAdminUsers();