#!/usr/bin/env node
'use strict';

/**
 * Clean orphaned admin permissions from production database
 * Run this before deploying if you get "Cannot read properties of undefined (reading 'attributes')" error
 *
 * Usage: node scripts/clean-admin-permissions.js
 */

const mysql = require('mysql2/promise');

const DB_CONFIG = {
  host: process.env.DATABASE_HOST,
  port: parseInt(process.env.DATABASE_PORT || '3306'),
  user: process.env.DATABASE_USERNAME,
  password: process.env.DATABASE_PASSWORD,
  database: process.env.DATABASE_NAME,
  ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : false,
};

async function cleanAdminPermissions() {
  console.log('🔧 Connecting to database...');
  console.log(`   Host: ${DB_CONFIG.host}`);
  console.log(`   Database: ${DB_CONFIG.database}`);

  const connection = await mysql.createConnection(DB_CONFIG);

  try {
    console.log('✅ Connected to database');

    // Check if tables exist
    const [tables] = await connection.query(
      "SHOW TABLES LIKE 'strapi_administrator%'"
    );

    if (tables.length === 0) {
      console.log('ℹ️  No admin tables found - this might be a fresh database');
      return;
    }

    console.log('\n🗑️  Cleaning admin permission tables...');

    // Option 1: Delete all admin permissions (they'll be recreated on next boot)
    const queries = [
      'DELETE FROM strapi_administrator_roles_strapi_administrator',
      'DELETE FROM strapi_administrator_permissions_roles_links',
      'DELETE FROM strapi_administrator_permissions',
      'DELETE FROM strapi_administrator_roles WHERE code != "strapi-super-admin"',
    ];

    for (const query of queries) {
      try {
        const [result] = await connection.query(query);
        console.log(`   ✅ ${query.split(' ')[2]}: ${result.affectedRows} rows deleted`);
      } catch (err) {
        // Table might not exist in some Strapi versions
        if (err.code === 'ER_NO_SUCH_TABLE') {
          console.log(`   ⚠️  Table not found, skipping: ${err.message}`);
        } else {
          throw err;
        }
      }
    }

    // Reset the setup flag to trigger reinitialization
    await connection.query(
      `DELETE FROM core_store WHERE key = 'setup_settings_admin'`
    );
    console.log('   ✅ Reset admin setup flag');

    console.log('\n✅ Database cleanup complete!');
    console.log('   Admin permissions will be regenerated on next Strapi boot');

  } catch (err) {
    console.error('\n❌ Error:', err.message);
    throw err;
  } finally {
    await connection.end();
    console.log('\n🔌 Disconnected from database');
  }
}

// Environment variables are loaded from Digital Ocean App Platform
// No need for dotenv in production

cleanAdminPermissions()
  .then(() => {
    console.log('\n🎉 Done! You can now deploy.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\n💥 Failed:', err);
    process.exit(1);
  });
