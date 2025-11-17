const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// MySQL Connection Pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'gate_pass_system',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Test database connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Database connected successfully');
    connection.release();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
  }
}

testConnection();

// ========== AUTHENTICATION ENDPOINTS ==========

// Register Visitor
app.post('/api/register-visitor', async (req, res) => {
  try {
    const { fullName, email, contact, purpose, host } = req.body;

    if (!fullName || !email || !contact || !purpose || !host) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const connection = await pool.getConnection();

    // Check if email already exists
    const [existing] = await connection.execute(
      'SELECT * FROM visitors WHERE email = ?',
      [email]
    );

    if (existing.length > 0) {
      connection.release();
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Generate visitor ID
    const visitorId = 'V' + Math.floor(Math.random() * 100000);

    // Insert new visitor
    await connection.execute(
      `INSERT INTO visitors (visitor_id, full_name, email, contact_number, purpose, host_name, status, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, 'active', NOW())`,
      [visitorId, fullName, email, contact, purpose, host]
    );

    connection.release();

    // Create token
    const token = jwt.sign(
      { id: visitorId, email, role: 'visitor', name: fullName },
      JWT_SECRET,
      { expiresIn: '8h' }
    );

    res.status(201).json({
      success: true,
      message: 'Visitor registered successfully',
      visitor: {
        id: visitorId,
        name: fullName,
        email,
        role: 'visitor'
      },
      token
    });
  } catch (error) {
    console.error('Register visitor error:', error);
    res.status(500).json({ error: 'Server error during registration' });
  }
});

// Register Admin
app.post('/api/register-admin', async (req, res) => {
  try {
    const { adminName, email, contact, department, employeeId, password } = req.body;

    if (!adminName || !email || !contact || !department || !employeeId || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const connection = await pool.getConnection();

    // Check if email already exists
    const [existing] = await connection.execute(
      'SELECT * FROM admins WHERE email = ?',
      [email]
    );

    if (existing.length > 0) {
      connection.release();
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate admin ID
    const adminId = 'ADM' + Math.floor(Math.random() * 100000);

    // Insert new admin
    await connection.execute(
      `INSERT INTO admins (admin_id, admin_name, email, contact_number, department, employee_id, password, status, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, 'active', NOW())`,
      [adminId, adminName, email, contact, department, employeeId, hashedPassword]
    );

    connection.release();

    // Create token
    const token = jwt.sign(
      { id: adminId, email, role: 'admin', name: adminName },
      JWT_SECRET,
      { expiresIn: '8h' }
    );

    res.status(201).json({
      success: true,
      message: 'Admin registered successfully',
      admin: {
        id: adminId,
        name: adminName,
        email,
        role: 'admin'
      },
      token
    });
  } catch (error) {
    console.error('Register admin error:', error);
    res.status(500).json({ error: 'Server error during registration' });
  }
});

// Login
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const connection = await pool.getConnection();

    // Try admin login first
    const [admins] = await connection.execute(
      'SELECT * FROM admins WHERE email = ? OR admin_name = ?',
      [username, username]
    );

    if (admins.length > 0) {
      const admin = admins[0];
      const passwordMatch = await bcrypt.compare(password, admin.password);

      if (passwordMatch) {
        const token = jwt.sign(
          { id: admin.admin_id, email: admin.email, role: 'admin', name: admin.admin_name },
          JWT_SECRET,
          { expiresIn: '8h' }
        );

        connection.release();
        return res.json({
          success: true,
          message: 'Admin login successful',
          user: {
            id: admin.admin_id,
            name: admin.admin_name,
            email: admin.email,
            role: 'admin'
          },
          token
        });
      }
    }

    // Try visitor login
    const [visitors] = await connection.execute(
      'SELECT * FROM visitors WHERE email = ?',
      [username]
    );

    if (visitors.length > 0) {
      const visitor = visitors[0];
      // Visitors use a simple demo password check
      if (password === 'visitor123') {
        const token = jwt.sign(
          { id: visitor.visitor_id, email: visitor.email, role: 'visitor', name: visitor.full_name },
          JWT_SECRET,
          { expiresIn: '8h' }
        );

        connection.release();
        return res.json({
          success: true,
          message: 'Visitor login successful',
          user: {
            id: visitor.visitor_id,
            name: visitor.full_name,
            email: visitor.email,
            role: 'visitor',
            purpose: visitor.purpose,
            host: visitor.host_name
          },
          token
        });
      }
    }

    // Try security login
    const [securityUsers] = await connection.execute(
      'SELECT * FROM security_staff WHERE email = ? OR name = ?',
      [username, username]
    );

    if (securityUsers.length > 0) {
      const securityUser = securityUsers[0];
      const passwordMatch = await bcrypt.compare(password, securityUser.password);

      if (passwordMatch) {
        const token = jwt.sign(
          { id: securityUser.security_id, email: securityUser.email, role: 'security', name: securityUser.name },
          JWT_SECRET,
          { expiresIn: '8h' }
        );

        connection.release();
        return res.json({
          success: true,
          message: 'Security staff login successful',
          user: {
            id: securityUser.security_id,
            name: securityUser.name,
            email: securityUser.email,
            role: 'security'
          },
          token
        });
      }
    }

    connection.release();
    res.status(401).json({ error: 'Invalid credentials' });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
});

// ========== VISITOR ENDPOINTS ==========

// Get visitor details
app.get('/api/visitors/:visitorId', verifyToken, async (req, res) => {
  try {
    const { visitorId } = req.params;
    const connection = await pool.getConnection();

    const [visitors] = await connection.execute(
      'SELECT * FROM visitors WHERE visitor_id = ?',
      [visitorId]
    );

    connection.release();

    if (visitors.length === 0) {
      return res.status(404).json({ error: 'Visitor not found' });
    }

    res.json({ success: true, visitor: visitors[0] });
  } catch (error) {
    console.error('Get visitor error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all visitors (for admin dashboard)
app.get('/api/visitors', verifyToken, async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [visitors] = await connection.execute(
      'SELECT visitor_id, full_name, email, purpose, host_name, status, created_at FROM visitors ORDER BY created_at DESC LIMIT 100'
    );
    connection.release();

    res.json({ success: true, visitors });
  } catch (error) {
    console.error('Get visitors error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Generate QR Code
app.post('/api/generate-qr', verifyToken, async (req, res) => {
  try {
    const { visitorId, purpose, host, location } = req.body;
    const connection = await pool.getConnection();

    // Get visitor details
    const [visitors] = await connection.execute(
      'SELECT * FROM visitors WHERE visitor_id = ?',
      [visitorId]
    );

    if (visitors.length === 0) {
      connection.release();
      return res.status(404).json({ error: 'Visitor not found' });
    }

    const visitor = visitors[0];

    // Generate QR data
    const qrData = {
      id: visitorId,
      name: visitor.full_name,
      timestamp: new Date().toISOString(),
      type: 'gate_pass',
      purpose: purpose || visitor.purpose,
      host: host || visitor.host_name,
      location: location || 'Building A, Floor 3',
      validUntil: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString()
    };

    // Store QR code generation in database
    await connection.execute(
      `INSERT INTO qr_codes (visitor_id, qr_data, generated_at, expires_at) 
       VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 8 HOUR))`,
      [visitorId, JSON.stringify(qrData)]
    );

    connection.release();

    res.json({
      success: true,
      qrData,
      message: 'QR code generated successfully'
    });
  } catch (error) {
    console.error('Generate QR error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Verify QR Code
app.post('/api/verify-qr', verifyToken, async (req, res) => {
  try {
    const { qrData } = req.body;
    const connection = await pool.getConnection();

    const data = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;

    // Check if QR code is valid and not expired
    const [qrCodes] = await connection.execute(
      'SELECT * FROM qr_codes WHERE visitor_id = ? AND expires_at > NOW() ORDER BY generated_at DESC LIMIT 1',
      [data.id]
    );

    connection.release();

    if (qrCodes.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired QR code' });
    }

    res.json({
      success: true,
      message: 'QR code verified successfully',
      visitor: data.name,
      purpose: data.purpose
    });
  } catch (error) {
    console.error('Verify QR error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Check in/out visitor
app.post('/api/checkin-checkout', verifyToken, async (req, res) => {
  try {
    const { visitorId, action, gate } = req.body;
    const connection = await pool.getConnection();

    if (action === 'checkin') {
      await connection.execute(
        `INSERT INTO visitor_logs (visitor_id, action, gate, timestamp) 
         VALUES (?, 'CHECK_IN', ?, NOW())`,
        [visitorId, gate || 'Gate A']
      );
    } else if (action === 'checkout') {
      await connection.execute(
        `INSERT INTO visitor_logs (visitor_id, action, gate, timestamp) 
         VALUES (?, 'CHECK_OUT', ?, NOW())`,
        [visitorId, gate || 'Gate A']
      );
    }

    connection.release();

    res.json({
      success: true,
      message: `Visitor ${action}ed successfully`
    });
  } catch (error) {
    console.error('Checkin/Checkout error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== ADMIN ENDPOINTS ==========

// Get dashboard stats
app.get('/api/admin/stats', verifyToken, async (req, res) => {
  try {
    const connection = await pool.getConnection();

    const [totalVisitors] = await connection.execute('SELECT COUNT(*) as count FROM visitors');
    const [activeVisitors] = await connection.execute(
      `SELECT COUNT(*) as count FROM visitor_logs 
       WHERE DATE(timestamp) = CURDATE() AND action = 'CHECK_IN' 
       AND visitor_id NOT IN (SELECT visitor_id FROM visitor_logs WHERE DATE(timestamp) = CURDATE() AND action = 'CHECK_OUT')`
    );
    const [todayScans] = await connection.execute(
      `SELECT COUNT(*) as count FROM visitor_logs WHERE DATE(timestamp) = CURDATE()`
    );

    connection.release();

    res.json({
      success: true,
      stats: {
        totalVisitors: totalVisitors[0].count,
        activeVisitors: activeVisitors[0].count,
        todayScans: todayScans[0].count,
        systemUptime: '99.9%'
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get recent activity
app.get('/api/admin/activity', verifyToken, async (req, res) => {
  try {
    const connection = await pool.getConnection();

    const [activity] = await connection.execute(
      `SELECT vl.*, v.full_name, v.purpose FROM visitor_logs vl
       JOIN visitors v ON vl.visitor_id = v.visitor_id
       ORDER BY vl.timestamp DESC LIMIT 20`
    );

    connection.release();

    res.json({
      success: true,
      activity
    });
  } catch (error) {
    console.error('Get activity error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Revoke (soft-delete) a visitor - admin only
app.delete('/api/visitors/:visitorId', verifyToken, async (req, res) => {
  try {
    const { visitorId } = req.params;

    // Only admins can revoke visitors
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Admin privileges required' });
    }

    const connection = await pool.getConnection();

    // Check if visitor exists
    const [visitors] = await connection.execute(
      'SELECT * FROM visitors WHERE visitor_id = ?',
      [visitorId]
    );

    if (visitors.length === 0) {
      connection.release();
      return res.status(404).json({ error: 'Visitor not found' });
    }

    // Soft-delete by setting status to 'revoked'
    await connection.execute(
      'UPDATE visitors SET status = ? WHERE visitor_id = ?',
      ['revoked', visitorId]
    );

    // Log the revoke action
    await connection.execute(
      `INSERT INTO visitor_logs (visitor_id, action, gate, timestamp) VALUES (?, 'REVOKE', 'Admin', NOW())`,
      [visitorId]
    );

    connection.release();

    res.json({ success: true, message: 'Visitor revoked successfully' });
  } catch (error) {
    console.error('Revoke visitor error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// ========== MIDDLEWARE ==========

// Verify JWT Token
function verifyToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'Server is running' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
