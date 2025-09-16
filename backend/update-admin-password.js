const bcrypt = require('bcryptjs');
const db = require('./src/config/database');

async function updateAdminPassword() {
  try {
    // Hash the password 'admin123'
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash('admin123', saltRounds);
    
    // Update the admin user's password
    await db('users')
      .where('email', 'admin@teekoob.com')
      .update({
        password_hash: passwordHash,
        is_admin: true, // Make sure is_admin is set to true
        updated_at: new Date()
      });
    
    console.log('✅ Admin password updated successfully!');
    console.log('📧 Email: admin@teekoob.com');
    console.log('🔑 Password: admin123');
    console.log('🔐 New hash:', passwordHash);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating admin password:', error);
    process.exit(1);
  }
}

updateAdminPassword();
