const knex = require('knex');
const logger = require('../utils/logger');

console.log('🔍 Database config - Environment:', process.env.NODE_ENV);
console.log('🔍 Database config - Host:', process.env.DB_HOST);
console.log('🔍 Database config - Port:', process.env.DB_PORT);
console.log('🔍 Database config - Database:', process.env.DB_NAME);
console.log('🔍 Database config - User:', process.env.DB_USER);

const config = {
  development: {
    client: 'mysql2',
    connection: {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      database: process.env.DB_NAME || 'teekoob',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
    },
    pool: {
      min: 2,
      max: 10,
      acquireTimeoutMillis: 30000,
      createTimeoutMillis: 30000,
      destroyTimeoutMillis: 5000,
      idleTimeoutMillis: 30000,
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 100,
    },
    migrations: {
      directory: '../migrations',
      tableName: 'knex_migrations'
    },
    seeds: {
      directory: '../seeds'
    },
    debug: process.env.NODE_ENV === 'development'
  },
  
  production: {
    client: 'mysql2',
    connection: {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    },
    pool: {
      min: 2,
      max: 20,
      acquireTimeoutMillis: 30000,
      createTimeoutMillis: 30000,
      destroyTimeoutMillis: 5000,
      idleTimeoutMillis: 30000,
      reapIntervalMillis: 1000,
      createRetryIntervalMillis: 100,
    },
    migrations: {
      directory: '../migrations',
      tableName: 'knex_migrations'
    },
    seeds: {
      directory: '../seeds'
    }
  }
};

const environment = process.env.NODE_ENV || 'development';
const dbConfig = config[environment];

console.log('🔍 Database config object:', JSON.stringify(dbConfig, null, 2));

const db = knex(dbConfig);

// Test database connection with better error handling
db.raw('SELECT 1')
  .then(() => {
    console.log('✅ Database connected successfully');
    logger.info('✅ Database connected successfully');
  })
  .catch((error) => {
    console.error('❌ Database connection failed:', error);
    console.error('❌ Error details:', {
      message: error.message,
      code: error.code,
      errno: error.errno,
      sqlState: error.sqlState,
      sqlMessage: error.sqlMessage
    });
    logger.error('❌ Database connection failed:', error);
    
    // Don't exit immediately, let the app handle it
    console.log('⚠️ Continuing without database connection...');
  });

module.exports = db;
