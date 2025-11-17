# Gate Pass System - Backend Setup Guide

## 📋 Prerequisites

1. **Node.js** - Download from https://nodejs.org/ (v14 or higher)
2. **MySQL** - Download from https://www.mysql.com/downloads/
3. **Git** - Optional (for version control)

---

## 🗄️ Database Setup

### Step 1: Create Database

Open MySQL Command Line or MySQL Workbench and run:

```sql
CREATE DATABASE gate_pass_system;
USE gate_pass_system;
```

### Step 2: Create Tables

Run the following SQL to create all tables:

```sql
-- Visitors Table
CREATE TABLE visitors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(20) UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  contact_number VARCHAR(20) NOT NULL,
  purpose VARCHAR(255) NOT NULL,
  host_name VARCHAR(100) NOT NULL,
  status ENUM('active', 'expired', 'denied') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Admins Table
CREATE TABLE admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id VARCHAR(20) UNIQUE NOT NULL,
  admin_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  contact_number VARCHAR(20) NOT NULL,
  department VARCHAR(100) NOT NULL,
  employee_id VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Security Staff Table
CREATE TABLE security_staff (
  id INT AUTO_INCREMENT PRIMARY KEY,
  security_id VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  contact_number VARCHAR(20) NOT NULL,
  password VARCHAR(255) NOT NULL,
  status ENUM('active', 'inactive') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- QR Codes Table
CREATE TABLE qr_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(20) NOT NULL,
  qr_data JSON NOT NULL,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  verified BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id)
);

-- Visitor Logs Table
CREATE TABLE visitor_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(20) NOT NULL,
  action ENUM('CHECK_IN', 'CHECK_OUT') NOT NULL,
  gate VARCHAR(50) NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (visitor_id) REFERENCES visitors(visitor_id)
);

-- Create Indexes
CREATE INDEX idx_visitor_email ON visitors(email);
CREATE INDEX idx_admin_email ON admins(email);
CREATE INDEX idx_security_email ON security_staff(email);
CREATE INDEX idx_visitor_id ON qr_codes(visitor_id);
CREATE INDEX idx_visitor_log ON visitor_logs(visitor_id);
```

---

## 🚀 Backend Setup

### Step 1: Navigate to Backend Directory

```bash
cd Ayush\backend
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Configure Environment Variables

Edit the `.env` file and update your database credentials:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=gate_pass_system
PORT=5000
JWT_SECRET=your-secret-key-change-in-production
```

### Step 4: Start the Server

```bash
npm start
```

You should see:
```
✅ Database connected successfully
🚀 Server running on http://localhost:5000
```

---

## 🔌 Frontend Integration

### Step 1: Include API Script

Add this line to the `<head>` section of your HTML files:

```html
<script src="api.js"></script>
```

### Step 2: Update Login Function in index.html

Replace the login handler with API calls:

```javascript
document.getElementById('loginForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;
  
  const response = await gatePassAPI.login(username, password);
  
  if (response.success) {
    if (response.user.role === 'admin') {
      window.location.href = '2.html';
    } else if (response.user.role === 'visitor') {
      window.location.href = '3.html';
    } else if (response.user.role === 'security') {
      window.location.href = '4.html';
    }
  } else {
    alert('Login failed: ' + response.error);
  }
});
```

### Step 3: Update Visitor Registration

```javascript
document.getElementById('visitorRegForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const fullName = this.querySelector('input[placeholder="Enter your full name"]').value;
  const contact = this.querySelector('input[placeholder="Enter your phone number"]').value;
  const email = this.querySelector('input[placeholder="Enter your email"]').value;
  const purpose = this.querySelector('input[placeholder="Brief purpose of your visit"]').value;
  const host = this.querySelector('input[placeholder="Person you\'re visiting"]').value;
  
  const response = await gatePassAPI.registerVisitor(fullName, email, contact, purpose, host);
  
  if (response.success) {
    alert('Registration successful! ID: ' + response.visitor.id);
    window.location.href = '3.html';
  } else {
    alert('Registration failed: ' + response.error);
  }
});
```

---

## 📊 Default Test Credentials (After Backend Setup)

After you insert test data into the database, you can use:

- **Admin**: username: `admin@example.com`, password: `hashedPassword`
- **Visitor**: email: `visitor@example.com`
- **Security**: username: `security@example.com`, password: `hashedPassword`

---

## 🔒 Security Features

✅ JWT Token Authentication  
✅ Bcrypt Password Hashing  
✅ CORS Enabled  
✅ Token Expiration (8 hours)  
✅ Input Validation  
✅ SQL Injection Prevention  

---

## 🛠️ Troubleshooting

### Connection Refused on Port 5000
- Check if server is running: `npm start`
- Verify MySQL is running
- Check if port 5000 is already in use

### Database Connection Error
- Verify DB credentials in `.env`
- Make sure MySQL is running
- Check if `gate_pass_system` database exists

### CORS Error
- Verify CORS is enabled in server.js
- Frontend and backend must be on different ports

---

## 📝 API Endpoints

### Authentication
- `POST /api/login` - Login
- `POST /api/register-visitor` - Register visitor
- `POST /api/register-admin` - Register admin

### Visitor Management
- `GET /api/visitors/:visitorId` - Get visitor details
- `GET /api/visitors` - Get all visitors
- `POST /api/generate-qr` - Generate QR code
- `POST /api/verify-qr` - Verify QR code
- `POST /api/checkin-checkout` - Check in/out

### Admin
- `GET /api/admin/stats` - Get dashboard stats
- `GET /api/admin/activity` - Get activity logs

---

## 🚀 Production Deployment

1. Change `JWT_SECRET` to a strong random string
2. Update database credentials for production database
3. Set `NODE_ENV=production`
4. Use a process manager like PM2
5. Deploy to platforms like Heroku, AWS, DigitalOcean, etc.

---

**Need help?** Check the API responses in browser console for error details.
