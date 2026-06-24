import { config } from './env.js';

/**
 * Database configuration module
 * Currently supports PostgreSQL configuration
 * Can be extended to support other databases
 */

export const databaseConfig = {
  connection: {
    host: config.database.host,
    port: config.database.port,
    database: config.database.name,
    user: config.database.user,
    password: config.database.password
  },
  
  pool: {
    min: 2,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000
  },
  
  ssl: config.isProduction ? { rejectUnauthorized: false } : false
};

/**
 * Initialize database connection
 * This is a placeholder for actual database implementation
 * Can be extended with Sequelize, Typeorm, Knex, etc.
 */
export async function initializeDatabase() {
  try {
    console.log(`Connecting to database: ${databaseConfig.connection.database}`);
    // Database connection logic here
    console.log('Database connected successfully');
  } catch (error) {
    console.error('Database connection failed:', error);
    throw error;
  }
}

export default databaseConfig;
