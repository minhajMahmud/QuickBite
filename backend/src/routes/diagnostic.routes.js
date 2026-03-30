const express = require('express');
const { pool } = require('../config/db');
const env = require('../config/env');

const router = express.Router();

/**
 * GET /api/v1/diagnostic/db-info
 * Shows current database connection info
 */
router.get('/db-info', async (req, res, next) => {
  try {
    console.log('🔍 [DIAGNOSTIC] Database info requested...');
    
    const client = await pool.connect();
    try {
      const result = await client.query(`
        SELECT 
          current_database() as database,
          current_user as user,
          version() as version,
          current_schema as schema,
          now() as server_time
      `);

      const info = result.rows[0];
      
      res.json({
        success: true,
        message: 'Database connection verified',
        connection: {
          host: env.db.host,
          port: env.db.port,
          user: env.db.user,
          database: env.db.database,
        },
        current: {
          database: info.database,
          user: info.user,
          schema: info.schema,
          version: info.version.split(',')[0],
          serverTime: info.server_time,
        },
      });
    } finally {
      client.release();
    }
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/diagnostic/tables
 * List all tables in the database
 */
router.get('/tables', async (req, res, next) => {
  try {
    console.log('🔍 [DIAGNOSTIC] Tables list requested...');
    
    const result = await pool.query(`
      SELECT 
        table_name,
        table_type,
        to_char(pg_size_pretty(pg_total_relation_size(table_schema||'.'||table_name)), '99999') as size
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);

    res.json({
      success: true,
      message: `Found ${result.rows.length} tables in public schema`,
      tables: result.rows,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/diagnostic/users-table
 * Show users table structure and record count
 */
router.get('/users-table', async (req, res, next) => {
  try {
    console.log('🔍 [DIAGNOSTIC] Users table info requested...');
    
    const columnResult = await pool.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);

    const countResult = await pool.query('SELECT COUNT(*) as total_rows FROM public.users');
    const recentResult = await pool.query(`
      SELECT 
        id,
        email,
        name,
        created_at,
        deleted_at
      FROM public.users
      ORDER BY created_at DESC
      LIMIT 5
    `);

    res.json({
      success: true,
      message: 'Users table info retrieved',
      table: {
        name: 'public.users',
        totalRows: parseInt(countResult.rows[0].total_rows),
        columns: columnResult.rows,
      },
      recentUsers: recentResult.rows,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/diagnostic/test-insert
 * Create a test user and verify it's saved
 * Body: { email, name, password }
 */
router.post('/test-insert', async (req, res, next) => {
  const { email, name, password } = req.body;
  
  if (!email || !name || !password) {
    return res.status(400).json({
      success: false,
      message: 'Missing required fields: email, name, password',
    });
  }

  try {
    console.log(`🧪 [DIAGNOSTIC] Test insert requested for: ${email}`);
    
    // Step 1: Check if user exists
    console.log('   Step 1: Checking if user exists...');
    const existsResult = await pool.query('SELECT id FROM public.users WHERE email = $1', [email]);
    if (existsResult.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists',
      });
    }

    // Step 2: Hash password
    console.log('   Step 2: Hashing password...');
    const bcrypt = require('bcryptjs');
    const passwordHash = await bcrypt.hash(password, 10);
    const userId = require('crypto').randomUUID();
    const now = new Date();

    // Step 3: Insert user
    console.log('   Step 3: Inserting user into database...');
    const insertResult = await pool.query(
      `INSERT INTO public.users (
        id, name, email, password_hash, status, 
        email_verified, first_login, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [userId, name, email, passwordHash, 'active', false, true, now, now]
    );

    const inserted = insertResult.rows[0];
    console.log(`   ✅ User inserted: ${inserted.id}`);

    // Step 4: Verify insert
    console.log('   Step 4: Verifying insert with SELECT...');
    const verifyResult = await pool.query('SELECT * FROM public.users WHERE id = $1', [userId]);
    
    if (verifyResult.rows.length === 0) {
      throw new Error('INSERT succeeded but SELECT returned no rows - CRITICAL ISSUE!');
    }

    const verified = verifyResult.rows[0];
    console.log(`   ✅ Verification successful! Found user in database`);

    // Step 5: Get total count
    console.log('   Step 5: Getting total user count...');
    const countResult = await pool.query('SELECT COUNT(*) as total FROM public.users');
    const totalUsers = parseInt(countResult.rows[0].total);

    res.status(201).json({
      success: true,
      message: 'Test insert successful - data verified in database',
      steps: [
        { step: 1, action: 'Check existing user', result: 'OK - No duplicate' },
        { step: 2, action: 'Hash password', result: 'OK - bcryptjs applied' },
        { step: 3, action: 'INSERT user', result: `OK - User ID: ${inserted.id}` },
        { step: 4, action: 'Verify SELECT', result: 'OK - User found in database' },
        { step: 5, action: 'Count total users', result: `OK - Total: ${totalUsers}` },
      ],
      inserted: {
        id: inserted.id,
        email: inserted.email,
        name: inserted.name,
        createdAt: inserted.created_at,
      },
      verified: {
        id: verified.id,
        email: verified.email,
        name: verified.name,
        createdAt: verified.created_at,
      },
      totalUsersInDatabase: totalUsers,
    });

  } catch (error) {
    console.error(`❌ [DIAGNOSTIC] Test insert failed:`, error.message);
    res.status(500).json({
      success: false,
      message: 'Test insert failed',
      error: error.message,
      errorCode: error.code,
    });
  }
});

/**
 * GET /api/v1/diagnostic/all-users
 * List all users in the database
 */
router.get('/all-users', async (req, res, next) => {
  try {
    console.log('🔍 [DIAGNOSTIC] All users requested...');
    
    const result = await pool.query(`
      SELECT 
        id,
        email,
        name,
        status,
        email_verified,
        created_at,
        deleted_at
      FROM public.users
      ORDER BY created_at DESC
    `);

    res.json({
      success: true,
      totalUsers: result.rows.length,
      users: result.rows,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/v1/diagnostic/test-users
 * Delete all test users (for cleanup)
 */
router.delete('/test-users', async (req, res, next) => {
  try {
    console.log('🧹 [DIAGNOSTIC] Deleting test users...');
    
    const result = await pool.query(`
      DELETE FROM public.users 
      WHERE email LIKE '%test%' OR email LIKE '%diagnostic%'
      RETURNING email
    `);

    res.json({
      success: true,
      message: `Deleted ${result.rows.length} test users`,
      deleted: result.rows.map(row => row.email),
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
