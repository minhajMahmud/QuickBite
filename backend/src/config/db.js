const { Pool } = require('pg');
const env = require('./env');

const pool = new Pool({
  host: env.db.host,
  port: env.db.port,
  user: env.db.user,
  password: env.db.password,
  database: env.db.database,
});

// Log connection details on startup (without exposing password)
console.log('🗄️  PostgreSQL Connection Configuration:');
console.log(`   Host: ${env.db.host}`);
console.log(`   Port: ${env.db.port}`);
console.log(`   User: ${env.db.user}`);
console.log(`   Database: ${env.db.database}`);
console.log(`   Pool Size: min=2, max=20`);

async function checkDbConnection() {
  const client = await pool.connect();
  try {
    // Get detailed connection info
    const result = await client.query(`
      SELECT 
        current_database() as database,
        current_user as user,
        version() as version,
        current_schema as schema
    `);
    
    const connInfo = result.rows[0];
    console.log('\n✅ PostgreSQL Connected Successfully!');
    console.log(`   Database: ${connInfo.database}`);
    console.log(`   User: ${connInfo.user}`);
    console.log(`   Schema: ${connInfo.schema}`);
    console.log(`   Version: ${connInfo.version.split(',')[0]}`);
    console.log(''); // Blank line for readable logs
    
    return true;
  } catch (error) {
    console.error('❌ PostgreSQL Connection Failed:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Execute a query with logging
 */
async function executeQuery(query, values = [], operation = 'Query') {
  const client = await pool.connect();
  try {
    console.log(`📝 ${operation}:`);
    console.log(`   SQL: ${query.substring(0, 100)}${query.length > 100 ? '...' : ''}`);
    console.log(`   Values: ${values.length ? JSON.stringify(values) : '(none)'}`);
    
    const result = await client.query(query, values);
    
    console.log(`✅ ${operation} Success - ${result.rows.length} rows affected`);
    return result;
  } catch (error) {
    console.error(`❌ ${operation} Failed:`, error.message);
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  pool,
  checkDbConnection,
  executeQuery,
};
