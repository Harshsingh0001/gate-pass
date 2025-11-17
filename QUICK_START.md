# 🚀 Complete Backend Setup Guide - Digital Gate Pass System

## Step-by-Step Installation

### 1️⃣ Install Prerequisites

#### Download and Install Node.js
- Go to https://nodejs.org/
- Download LTS version
- Install with default settings
- Verify installation:
  ```bash
  node --version
  npm --version
  ```

#### Download and Install MySQL
- Go to https://www.mysql.com/downloads/
- Download MySQL Community Server
- Install with default settings
- Remember your password
- Verify installation:
  ```bash
  mysql --version
  ```

---

### 2️⃣ Create Database

#### Option A: Using MySQL Command Line
```bash
mysql -u root -p
```
Enter your MySQL password, then:

```sql
CREATE DATABASE gate_pass_system;
USE gate_pass_system;

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

-- Create Indexes for better performance
CREATE INDEX idx_visitor_email ON visitors(email);
CREATE INDEX idx_admin_email ON admins(email);
CREATE INDEX idx_security_email ON security_staff(email);
```

#### Option B: Using MySQL Workbench
1. Open MySQL Workbench
2. Create new connection or use existing
3. Copy the SQL queries above
4. Paste and execute

---

### 3️⃣ Setup Backend

#### Step 1: Navigate to Backend Folder
```bash
cd "Ayush\backend"
```

#### Step 2: Install Dependencies
```bash
npm install
```

This will install:
- express (web framework)
- mysql2 (database driver)
- jsonwebtoken (authentication)
- bcryptjs (password hashing)
- cors (cross-origin requests)
- dotenv (environment variables)

#### Step 3: Configure Environment

Edit `backend\.env` file:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=gate_pass_system

# Server Configuration
PORT=5000

# JWT Secret (change this!)
JWT_SECRET=your-secret-key-change-in-production-12345
```

**Important:** Replace `your_mysql_password` with your actual MySQL password!

#### Step 4: Start the Server
```bash
npm start
```

You should see:
```
✅ Database connected successfully
🚀 Server running on http://localhost:5000
```

---

### 4️⃣ Frontend Setup (Already Done!)

The frontend files are already updated to use the backend API. Just make sure `api.js` is in the same directory as your HTML files.

---

## ✅ Testing the Backend

### 1. Test API Health
Visit this in your browser:
```
http://localhost:5000/api/health
```

You should see:
```json
{
  "status": "Server is running"
}
```

### 2. Test Login via Frontend
1. Open `index.html` in browser
2. Try to login (it will now use the backend API)

---

## 📝 Demo Credentials (After Setup)

After you run the backend, you can use these to test:

### Admin Login
```
Username: admin
Password: admin123
(Database will have this after first registration)
```

### Visitor Registration
- Use the "Register as Visitor" button
- Fill in any details
- It will save to database and redirect to visitor dashboard

### Security Staff
- Need to be added to database first via SQL:

```sql
INSERT INTO security_staff (security_id, name, email, contact_number, password) 
VALUES ('SG001', 'John Guard', 'guard@example.com', '1234567890', '$2a$10$...');
```

---

## 🔧 Troubleshooting

### Problem: "Cannot find module 'express'"
**Solution:** Run `npm install` in the backend folder

### Problem: "Connection refused on port 5000"
**Solution:** 
- Make sure backend is running with `npm start`
- Check if port is already in use

### Problem: "Database connection error"
**Solution:**
- Verify MySQL is running
- Check DB credentials in `.env`
- Make sure `gate_pass_system` database exists

### Problem: "CORS Error in console"
**Solution:**
- This means backend is not running
- Start backend with `npm start`

### Problem: "404 endpoint not found"
**Solution:**
- Make sure server is actually running
- Check console for any error messages

---

## 🎯 How It All Works Together

```
User fills form in Browser
    ↓
HTML sends request to api.js
    ↓
api.js sends request to backend (Node.js)
    ↓
Backend connects to MySQL database
    ↓
Backend sends response back to frontend
    ↓
Frontend shows result to user
```

---

## 📚 API Endpoints Available

### Authentication
```
POST http://localhost:5000/api/login
POST http://localhost:5000/api/register-visitor
POST http://localhost:5000/api/register-admin
```

### Visitor Management
```
GET http://localhost:5000/api/visitors
GET http://localhost:5000/api/visitors/:visitorId
POST http://localhost:5000/api/generate-qr
POST http://localhost:5000/api/verify-qr
POST http://localhost:5000/api/checkin-checkout
```

### Admin Dashboard
```
GET http://localhost:5000/api/admin/stats
GET http://localhost:5000/api/admin/activity
```

---

## 🛡️ Security Features Implemented

✅ **JWT Authentication** - Secure token-based login  
✅ **Password Hashing** - Bcrypt for secure passwords  
✅ **CORS Protection** - Prevent unauthorized requests  
✅ **Token Expiration** - Tokens expire after 8 hours  
✅ **SQL Injection Prevention** - Prepared statements  
✅ **Input Validation** - All inputs validated  

---

## 🚀 Quick Start Checklist

- [ ] Node.js installed
- [ ] MySQL installed
- [ ] Database created with tables
- [ ] Backend dependencies installed (`npm install`)
- [ ] `.env` file configured with your DB password
- [ ] Backend running (`npm start`)
- [ ] `api.js` in frontend folder
- [ ] `index.html` includes `<script src="api.js"></script>`
- [ ] Testing login in browser

---

## 💡 Next Steps

1. **Add test data to database** - Insert sample visitors/admins
2. **Test all features** - Login, register, generate QR codes
3. **Monitor logs** - Check console output for errors
4. **Customize** - Add your own features/endpoints
5. **Deploy** - Put on server for production use

---

**Need help?** Check the console (Press F12 in browser) for error messages!
