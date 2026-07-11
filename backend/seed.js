// One-time script: creates the fixed admin account.
// Run with: npm run seed
require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('./db');

async function seed() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;

  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length > 0) {
    console.log('Admin already exists, skipping.');
    process.exit(0);
  }

  const hash = await bcrypt.hash(password, 10);
  await pool.query(
    'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
    ['Admin', email, hash, 'admin']
  );
  console.log(`Admin created: ${email} / ${password}`);
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
